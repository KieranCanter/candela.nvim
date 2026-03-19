describe("candela.io", function()
    local io_mod, patterns
    local test_dir = vim.fn.tempname()
    local test_file = test_dir .. "/test_patterns.lua"

    before_each(function()
        package.loaded["candela.io"] = nil
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.highlighter"] = nil
        package.loaded["candela.config"] = nil
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
        package.loaded["candela.highlighter"] = {
            match_cache = {},
            base_buf = nil,
            highlight = function()
                return 0
            end,
            remove = function() end,
            remove_all = function() end,
            refresh_ui = function() end,
        }

        patterns = require("candela.patterns")
        patterns.palette = { dark = { "#AA0000" }, light = { "#FF0000" } }
        patterns.next_color = function()
            return "#AA0000"
        end

        io_mod = require("candela.io")
        vim.fn.mkdir(test_dir, "p")
    end)

    after_each(function()
        vim.fn.delete(test_dir, "rf")
    end)

    describe("export", function()
        it("writes patterns to a lua file", function()
            patterns.add("ERROR", "#FF0000")
            patterns.add("WARN", "#FFFF00")
            io_mod.export(test_file)
            assert.is_true(vim.fn.filereadable(test_file) == 1)
        end)

        it("exported file is valid lua", function()
            patterns.add("ERROR", "#FF0000")
            io_mod.export(test_file)
            local ok, data = pcall(dofile, test_file)
            assert.is_true(ok)
            assert.is_true(#data > 0)
            assert.equals("ERROR", data[1].regex)
        end)
    end)

    describe("import", function()
        it("loads patterns from a lua file", function()
            -- Write a test file manually
            local f = io.open(test_file, "w")
            f:write('return { { regex = "IMPORTED", color = "#123456", highlight = true, lightbox = true } }')
            f:close()

            io_mod.import(test_file)
            assert.is_not_nil(patterns.get("IMPORTED"))
            assert.equals("#123456", patterns.get("IMPORTED").color)
        end)

        it("rejects non-lua files", function()
            local bad_file = test_dir .. "/test.txt"
            local f = io.open(bad_file, "w")
            f:write("not lua")
            f:close()
            io_mod.import(bad_file)
            assert.equals(0, patterns.count())
        end)
    end)

    describe("roundtrip", function()
        it("export then import preserves patterns", function()
            patterns.add("ERROR", "#FF0000", true, false)
            patterns.add("WARN", "#FFFF00", false, true)
            io_mod.export(test_file)

            patterns.clear()
            assert.equals(0, patterns.count())

            io_mod.import(test_file)
            assert.equals(2, patterns.count())

            local err = patterns.get("ERROR")
            assert.is_not_nil(err)
            assert.equals("#FF0000", err.color)
            assert.is_true(err.highlight)
            assert.is_false(err.lightbox)
        end)
    end)
end)
