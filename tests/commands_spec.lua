describe("candela.commands", function()
    local commands, patterns

    before_each(function()
        package.loaded["candela.commands"] = nil
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.highlighter"] = nil
        package.loaded["candela.config"] = nil
        package.loaded["candela.ui"] = nil
        package.loaded["candela"] = nil

        package.loaded["candela"] = { augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }) }
        package.loaded["candela.config"] = {
            defaults = { palette = { colors = { dark = {}, light = {} }, cycle = "constant" } },
            options = {
                engine = { command = "rg", args = { "--line-number", "--color=never" } },
                matching = { hl_eol = false },
                icons = { highlight = {}, lightbox = {} },
                window = { width = 0.5, min_height = 5, max_height = 30, margin = 16 },
                lightbox = {
                    default_view = "system-vsplit",
                    fold_style = "nvim",
                    fillchar = "-",
                    custom_foldtext = nil,
                },
                palette = {
                    use = "replace",
                    cycle = "constant",
                    colors = { dark = { "#AA0000" }, light = { "#FF0000" } },
                    swatches = { dark = {}, light = {} },
                },
            },
        }

        -- Stub UI
        local existing = vim.fn.bufnr("candela://patterns")
        if existing ~= -1 then
            vim.api.nvim_buf_delete(existing, { force = true })
        end
        package.loaded["candela.ui"] = {
            buf = vim.api.nvim_create_buf(false, true),
            get_lines = function()
                return {}
            end,
            render = function() end,
            help = function() end,
            close = function() end,
        }

        -- Stub highlighter
        package.loaded["candela.highlighter"] = {
            match_cache = {},
            base_buf = vim.api.nvim_create_buf(false, true),
            highlight = function()
                return 0
            end,
            remove = function() end,
            remove_all = function() end,
            refresh = function() end,
            refresh_ui = function() end,
            update_color = function() end,
            toggle_highlights = function() end,
        }

        patterns = require("candela.patterns")
        patterns.palette = { dark = { "#AA0000" }, light = { "#FF0000" } }
        patterns.next_color = function()
            return "#AA0000"
        end

        commands = require("candela.commands")
    end)

    local function dispatch(cmd_str)
        local parts = vim.split(cmd_str, " ")
        commands.dispatch({ fargs = parts })
    end

    describe("add", function()
        it("adds a pattern", function()
            dispatch("add ERROR")
            assert.is_not_nil(patterns.get("ERROR"))
        end)

        it("rejects no args", function()
            dispatch("add")
            assert.equals(0, patterns.count())
        end)
    end)

    describe("edit", function()
        it("edits a pattern by regex", function()
            patterns.add("ERROR")
            dispatch("edit ERROR FATAL")
            assert.is_nil(patterns.get("ERROR"))
            assert.is_not_nil(patterns.get("FATAL"))
        end)
    end)

    describe("copy", function()
        it("copies a pattern with new regex", function()
            patterns.add("ERROR", "#123456")
            dispatch("copy ERROR FATAL")
            assert.is_not_nil(patterns.get("ERROR"))
            assert.is_not_nil(patterns.get("FATAL"))
            assert.equals("#123456", patterns.get("FATAL").color)
        end)
    end)

    describe("delete", function()
        it("deletes by regex", function()
            patterns.add("ERROR")
            dispatch("delete ERROR")
            assert.is_nil(patterns.get("ERROR"))
        end)

        it("deletes multiple", function()
            patterns.add("ERROR")
            patterns.add("WARN")
            dispatch("delete ERROR WARN")
            assert.equals(0, patterns.count())
        end)
    end)

    describe("clear", function()
        it("clears all patterns", function()
            patterns.add("ERROR")
            patterns.add("WARN")
            dispatch("clear")
            assert.equals(0, patterns.count())
        end)
    end)

    describe("change_color", function()
        it("changes color by regex", function()
            patterns.add("ERROR", "#000000")
            dispatch("change_color ERROR #FFFFFF")
            assert.equals("#FFFFFF", patterns.get("ERROR").color)
        end)
    end)

    describe("toggle_highlight", function()
        it("toggles highlight state", function()
            patterns.add("ERROR")
            assert.is_true(patterns.get("ERROR").highlight)
            dispatch("toggle_highlight ERROR")
            assert.is_false(patterns.get("ERROR").highlight)
        end)
    end)

    describe("toggle_lightbox", function()
        it("toggles lightbox state", function()
            patterns.add("ERROR")
            assert.is_true(patterns.get("ERROR").lightbox)
            dispatch("toggle_lightbox ERROR")
            assert.is_false(patterns.get("ERROR").lightbox)
        end)
    end)

    describe("complete", function()
        it("completes subcommands", function()
            local results = commands.complete("a", "Candela a", 9)
            assert.is_true(vim.tbl_contains(results, "add"))
        end)

        it("completes pattern regexes for edit", function()
            patterns.add("ERROR")
            local results = commands.complete("E", "Candela edit E", 14)
            assert.is_true(#results > 0)
        end)
    end)

    describe("dispatch", function()
        it("handles unknown command", function()
            dispatch("nonexistent")
        end)
    end)

    describe("vimmatch", function()
        it("dispatches vimmatch command", function()
            patterns.add("ERROR")
            -- Should not error
            dispatch("vimmatch ERROR")
        end)
    end)

    describe("loclist", function()
        it("dispatches loclist command", function()
            patterns.add("ERROR")
            -- Should not error
            dispatch("loclist ERROR")
        end)
    end)

    describe("lightbox", function()
        it("dispatches lightbox with view", function()
            -- Should not error
            dispatch("lightbox system-vsplit")
        end)

        it("dispatches lightbox without view", function()
            dispatch("lightbox")
        end)
    end)
end)
