describe("candela.init on_write", function()
    local ui, patterns, highlighter

    before_each(function()
        package.loaded["candela"] = nil
        package.loaded["candela.ui"] = nil
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.highlighter"] = nil
        package.loaded["candela.config"] = nil

        package.loaded["candela.config"] = {
            defaults = { palette = { colors = { dark = {}, light = {} }, cycle = "constant" } },
            options = {
                engine = { command = "rg", args = {} },
                matching = { auto_refresh = false, hl_eol = false },
                icons = {
                    candela = "C",
                    color = "C",
                    regex = "R",
                    highlight = { header = "H", toggle_on = "Y", toggle_off = "N" },
                    lightbox = { header = "L", toggle_on = "Y", toggle_off = "N" },
                },
                window = { width = 0.5, min_height = 5, max_height = 30, margin = 16 },
                palette = {
                    use = "replace",
                    cycle = "constant",
                    colors = { dark = { "#AA0000" }, light = { "#FF0000" } },
                    swatches = { dark = {}, light = {} },
                },
                syntax_highlighting = { enabled = false },
            },
        }

        local existing = vim.fn.bufnr("candela://patterns")
        if existing ~= -1 then
            vim.api.nvim_buf_delete(existing, { force = true })
        end

        -- Need real candela module for augroup
        package.loaded["candela"] = nil
        local candela = require("candela")

        patterns = require("candela.patterns")
        patterns.palette = { dark = { "#AA0000" }, light = { "#FF0000" } }
        patterns.next_color = function()
            return "#AA0000"
        end

        highlighter = require("candela.highlighter")
        highlighter.base_buf = vim.api.nvim_create_buf(false, true)
        -- Stub highlight to avoid needing real engine
        highlighter.highlight = function()
            return 0
        end

        -- Trigger ensure_init to wire on_write
        ui = require("candela.ui")
        ui.get_lines() -- ensure ui.buf is created
        candela.ensure_init()
    end)

    it("adds patterns from buffer that aren't in memory", function()
        -- Simulate user typing a new pattern in the buffer
        vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
        vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, { "NEWPATTERN" })

        -- Fire on_write
        ui.on_write()

        assert.is_not_nil(patterns.get("NEWPATTERN"))
    end)

    it("deletes patterns from memory that aren't in buffer", function()
        patterns.add("TOBEDELETED")
        -- Buffer is empty — pattern should be deleted
        vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
        vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, { "" })

        ui.on_write()

        assert.is_nil(patterns.get("TOBEDELETED"))
    end)

    it("keeps patterns that exist in both", function()
        patterns.add("KEEP")
        vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
        vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, { "KEEP" })

        ui.on_write()

        assert.is_not_nil(patterns.get("KEEP"))
        assert.equals(1, patterns.count())
    end)

    it("handles add and delete in same write", function()
        patterns.add("OLD")
        vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
        vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, { "NEW" })

        ui.on_write()

        assert.is_nil(patterns.get("OLD"))
        assert.is_not_nil(patterns.get("NEW"))
    end)

    it("silently merges duplicates", function()
        vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
        vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, { "DUP", "DUP" })

        ui.on_write()

        assert.is_not_nil(patterns.get("DUP"))
        assert.equals(1, patterns.count())
    end)
end)
