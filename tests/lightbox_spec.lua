describe("candela.lightbox", function()
    local lightbox

    before_each(function()
        package.loaded["candela.lightbox"] = nil
        package.loaded["candela.highlighter"] = nil
        package.loaded["candela.config"] = nil
        package.loaded["candela"] = nil

        package.loaded["candela"] = { augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }) }
        package.loaded["candela.config"] = {
            options = {
                lightbox = {
                    view = "system-vsplit",
                    fold_style = "nvim",
                    fillchar = "-",
                    custom_foldtext = nil,
                },
            },
        }

        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
            "line 4",
            "line 5",
        })
        package.loaded["candela.highlighter"] = { base_buf = buf, match_cache = {} }

        lightbox = require("candela.lightbox")
    end)

    after_each(function()
        if lightbox.win and vim.api.nvim_win_is_valid(lightbox.win) then
            vim.api.nvim_win_close(lightbox.win, true)
            lightbox.win = nil
        end
    end)

    describe("cache", function()
        it("add_to_cache creates entry", function()
            lightbox.add_to_cache(1, "ERROR")
            assert.is_not_nil(lightbox.lightbox_cache[1])
            assert.is_true(lightbox.lightbox_cache[1]["ERROR"])
        end)

        it("add_to_cache supports multiple regexes per row", function()
            lightbox.add_to_cache(1, "ERROR")
            lightbox.add_to_cache(1, "WARN")
            assert.is_true(lightbox.lightbox_cache[1]["ERROR"])
            assert.is_true(lightbox.lightbox_cache[1]["WARN"])
        end)

        it("add_many_to_cache adds all matches", function()
            local matches = {
                { extmark_id = 1, row = 1, end_col = 5 },
                { extmark_id = 2, row = 3, end_col = 5 },
            }
            lightbox.add_many_to_cache(matches, "ERROR")
            assert.is_not_nil(lightbox.lightbox_cache[1])
            assert.is_not_nil(lightbox.lightbox_cache[3])
        end)

        it("add_many_to_cache handles nil", function()
            lightbox.add_many_to_cache(nil, "ERROR")
            assert.same({}, lightbox.lightbox_cache)
        end)

        it("remove_from_cache removes regex from rows", function()
            lightbox.add_to_cache(1, "ERROR")
            lightbox.add_to_cache(1, "WARN")
            local matches = { { extmark_id = 1, row = 1, end_col = 5 } }
            lightbox.remove_from_cache(matches, "ERROR")
            assert.is_nil(lightbox.lightbox_cache[1]["ERROR"])
            assert.is_true(lightbox.lightbox_cache[1]["WARN"])
        end)

        it("remove_from_cache cleans up empty rows", function()
            lightbox.add_to_cache(1, "ERROR")
            local matches = { { extmark_id = 1, row = 1, end_col = 5 } }
            lightbox.remove_from_cache(matches, "ERROR")
            assert.is_nil(lightbox.lightbox_cache[1])
        end)

        it("remove_from_cache handles nil", function()
            lightbox.remove_from_cache(nil, "ERROR")
        end)
    end)

    describe("open", function()
        it("opens with system-vsplit", function()
            lightbox.open("system-vsplit")
            assert.is_not_nil(lightbox.win)
            assert.is_true(vim.api.nvim_win_is_valid(lightbox.win))
        end)
    end)

    describe("toggle", function()
        it("opens and closes", function()
            lightbox.toggle("system-vsplit")
            assert.is_not_nil(lightbox.win)
            assert.is_true(vim.api.nvim_win_is_valid(lightbox.win))

            vim.api.nvim_set_current_win(lightbox.win)
            lightbox.toggle("system-vsplit")
            assert.is_nil(lightbox.win)
        end)

        it("defaults to system-vsplit", function()
            lightbox.toggle()
            assert.is_not_nil(lightbox.win)
            assert.is_true(vim.api.nvim_win_is_valid(lightbox.win))
        end)
    end)
end)
