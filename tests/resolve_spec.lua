describe("candela.patterns.resolve", function()
    local patterns, ui

    before_each(function()
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.config"] = nil
        package.loaded["candela.ui"] = nil
        package.loaded["candela"] = nil

        package.loaded["candela"] = { augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }) }
        package.loaded["candela.config"] = {
            defaults = { palette = { colors = { dark = {}, light = {} }, cycle = "constant" } },
            options = {
                palette = {
                    use = "replace",
                    cycle = "constant",
                    colors = { dark = { "#AA0000" }, light = { "#FF0000" } },
                    swatches = { dark = {}, light = {} },
                },
            },
        }

        local existing = vim.fn.bufnr("candela://patterns")
        if existing ~= -1 then
            vim.api.nvim_buf_delete(existing, { force = true })
        end

        ui = require("candela.ui")
        patterns = require("candela.patterns")
        patterns.palette = { dark = { "#AA0000" }, light = { "#FF0000" } }
        patterns.next_color = function()
            return "#AA0000"
        end
    end)

    it("resolves regex string directly", function()
        patterns.add("ERROR")
        assert.equals("ERROR", patterns.resolve("ERROR"))
    end)

    it("returns nil for unknown regex", function()
        assert.is_nil(patterns.resolve("NOPE"))
    end)

    it("resolves index from buffer lines", function()
        patterns.add("ERROR")
        patterns.add("WARN")
        ui.render({ "ERROR", "WARN" })
        assert.equals("ERROR", patterns.resolve(1))
        assert.equals("WARN", patterns.resolve(2))
    end)

    it("resolves string index", function()
        patterns.add("ERROR")
        ui.render({ "ERROR" })
        assert.equals("ERROR", patterns.resolve("1"))
    end)

    it("returns nil for out of range index", function()
        patterns.add("ERROR")
        ui.render({ "ERROR" })
        assert.is_nil(patterns.resolve(99))
    end)

    it("preserves whitespace in regex", function()
        patterns.add(" ")
        ui.render({ " " })
        assert.equals(" ", patterns.resolve(1))
    end)
end)
