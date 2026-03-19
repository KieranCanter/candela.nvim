describe("candela.highlighter", function()
    local highlighter, patterns

    before_each(function()
        package.loaded["candela.highlighter"] = nil
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.config"] = nil
        package.loaded["candela.ui"] = nil
        package.loaded["candela"] = nil

        package.loaded["candela"] = { augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }) }
        package.loaded["candela.config"] = {
            options = {
                engine = { command = "rg", args = { "--line-number", "--color=never" } },
                matching = { hl_eol = false },
                icons = { highlight = {}, lightbox = {} },
                window = { toggle_width = 4 },
            },
        }

        -- Stub UI
        package.loaded["candela.ui"] = {
            buf = vim.api.nvim_create_buf(false, true),
            get_lines = function()
                return {}
            end,
            render = function() end,
        }

        patterns = require("candela.patterns")
        patterns.palette = { dark = { "#AA0000", "#00AA00" }, light = { "#FF0000" } }
        patterns.next_color = function()
            return "#AA0000"
        end

        highlighter = require("candela.highlighter")
    end)

    it("starts with empty match_cache", function()
        assert.same({}, highlighter.match_cache)
    end)

    it("base_buf is nil initially", function()
        assert.is_nil(highlighter.base_buf)
    end)

    describe("highlight", function()
        it("returns -1 when pattern not found", function()
            assert.equals(-1, highlighter.highlight("NOPE"))
        end)

        it("warns when no base_buf", function()
            patterns.add("ERROR")
            highlighter.base_buf = nil
            -- Should warn, not crash
            assert.equals(-1, highlighter.highlight("ERROR"))
        end)
    end)

    describe("remove", function()
        it("clears match_cache entry", function()
            highlighter.match_cache["ERROR"] = { { extmark_id = 1, row = 1, end_col = 5 } }
            highlighter.base_buf = vim.api.nvim_create_buf(false, true)
            highlighter.remove("ERROR")
            assert.is_nil(highlighter.match_cache["ERROR"])
        end)

        it("is safe for nonexistent regex", function()
            highlighter.base_buf = vim.api.nvim_create_buf(false, true)
            highlighter.remove("NOPE") -- should not error
        end)
    end)

    describe("remove_all", function()
        it("clears all entries", function()
            highlighter.match_cache["A"] = {}
            highlighter.match_cache["B"] = {}
            highlighter.base_buf = vim.api.nvim_create_buf(false, true)
            highlighter.remove_all()
            assert.same({}, highlighter.match_cache)
        end)
    end)

    describe("refresh_ui", function()
        it("calls ui.render with pattern regexes", function()
            local rendered_lines
            package.loaded["candela.ui"].render = function(lines)
                rendered_lines = lines
            end
            package.loaded["candela.ui"].get_lines = function()
                return {}
            end

            patterns.add("WARN")
            patterns.add("ERROR")
            highlighter.refresh_ui()

            assert.is_not_nil(rendered_lines)
            assert.equals(2, #rendered_lines)
            -- Both patterns present (order doesn't matter)
            local set = {}
            for _, l in ipairs(rendered_lines) do
                set[l] = true
            end
            assert.is_true(set["ERROR"])
            assert.is_true(set["WARN"])
        end)

        it("preserves buffer order and appends new", function()
            local rendered_lines
            package.loaded["candela.ui"].render = function(lines)
                rendered_lines = lines
            end
            package.loaded["candela.ui"].get_lines = function()
                return { "WARN", "ERROR" }
            end

            patterns.add("ERROR")
            patterns.add("WARN")
            patterns.add("FATAL")
            highlighter.refresh_ui()

            assert.equals("WARN", rendered_lines[1])
            assert.equals("ERROR", rendered_lines[2])
            assert.equals("FATAL", rendered_lines[3])
        end)

        it("removes deleted patterns from buffer", function()
            local rendered_lines
            package.loaded["candela.ui"].render = function(lines)
                rendered_lines = lines
            end
            package.loaded["candela.ui"].get_lines = function()
                return { "ERROR", "WARN" }
            end

            patterns.add("ERROR")
            -- WARN not in patterns, should be dropped
            highlighter.refresh_ui()

            assert.equals(1, #rendered_lines)
            assert.equals("ERROR", rendered_lines[1])
        end)

        it("deduplicates buffer lines", function()
            local rendered_lines
            package.loaded["candela.ui"].render = function(lines)
                rendered_lines = lines
            end
            package.loaded["candela.ui"].get_lines = function()
                return { "ERROR", "ERROR" }
            end

            patterns.add("ERROR")
            highlighter.refresh_ui()

            assert.equals(1, #rendered_lines)
        end)
    end)
end)
