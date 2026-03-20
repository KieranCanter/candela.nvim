describe("candela.locator", function()
    local locator

    before_each(function()
        package.loaded["candela.locator"] = nil
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.highlighter"] = nil
        package.loaded["candela.config"] = nil
        package.loaded["candela"] = nil

        package.loaded["candela"] = {
            augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }),
            set_ui_keymaps = function() end,
        }
        package.loaded["candela.config"] = {
            defaults = { palette = { colors = { dark = {}, light = {} }, cycle = "constant" } },
            options = {
                engine = { command = "rg", args = { "--line-number", "--color=never" } },
                matching = { case = "sensitive" },
                palette = {
                    use = "replace",
                    cycle = "constant",
                    colors = { dark = { "#AA0000" }, light = { "#FF0000" } },
                    swatches = { dark = {}, light = {} },
                },
            },
        }

        -- Create a temp file with known content
        local tmpfile = vim.fn.tempname() .. ".log"
        local f = io.open(tmpfile, "w")
        f:write("ERROR something\nWARN something\nERROR again\n")
        f:close()

        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, tmpfile)
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "ERROR something", "WARN something", "ERROR again" })

        package.loaded["candela.highlighter"] = {
            base_buf = buf,
            match_cache = {},
        }

        local patterns = require("candela.patterns")
        patterns.palette = { dark = { "#AA0000" }, light = { "#FF0000" } }
        patterns.next_color = function()
            return "#AA0000"
        end
        patterns.add("ERROR")

        locator = require("candela.locator")
    end)

    describe("vimmatch", function()
        it("returns true when matches found", function()
            assert.is_true(locator.vimmatch({ "ERROR" }))
        end)

        it("returns false when no matches", function()
            assert.is_false(locator.vimmatch({ "ZZZZNOTFOUND" }))
        end)

        it("accepts multiple regexes", function()
            assert.is_true(locator.vimmatch({ "ERROR", "WARN" }))
        end)
    end)

    describe("loclist", function()
        it("populates location list", function()
            local ok = locator.loclist({ "ERROR" })
            assert.is_true(ok)
            local loclist = vim.fn.getloclist(0)
            assert.is_true(#loclist > 0)
        end)

        it("returns false when no matches", function()
            assert.is_false(locator.loclist({ "ZZZZNOTFOUND" }))
        end)

        it("accepts multiple regexes", function()
            assert.is_true(locator.loclist({ "ERROR", "WARN" }))
        end)
    end)

    describe("init", function()
        it("sets case from config", function()
            locator.init()
        end)

        it("set_candela_case reads vim options", function()
            locator.set_candela_case()
        end)
    end)
end)
