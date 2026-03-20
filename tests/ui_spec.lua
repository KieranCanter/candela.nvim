describe("candela.ui", function()
    local ui

    before_each(function()
        -- Wipe the named buffer if it exists from a previous test
        local existing = vim.fn.bufnr("candela://patterns")
        if existing ~= -1 then
            vim.api.nvim_buf_delete(existing, { force = true })
        end

        package.loaded["candela.ui"] = nil
        package.loaded["candela.config"] = nil
        package.loaded["candela.highlighter"] = nil
        package.loaded["candela"] = nil

        package.loaded["candela.config"] = {
            options = {
                icons = {
                    candela = "C",
                    color = "C",
                    regex = "R",
                    highlight = { header = "H", toggle_on = "Y", toggle_off = "N" },
                    lightbox = { header = "L", toggle_on = "Y", toggle_off = "N" },
                },
                window = { width = 0.5, min_height = 5, max_height = 30, margin = 16 },
            },
        }
        package.loaded["candela"] = { augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }) }
        package.loaded["candela.highlighter"] = { refresh_ui = function() end }

        ui = require("candela.ui")
    end)

    after_each(function()
        if ui.win and vim.api.nvim_win_is_valid(ui.win) then
            ui.close()
        end
    end)

    local function make_entry(regex)
        return { regex = regex, color = "#AA0000", count = 0, highlight = true, lightbox = true, hl_group = "Normal" }
    end

    describe("render + get_lines", function()
        it("sets buffer content", function()
            ui.render({ make_entry("ERROR"), make_entry("WARN") })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
            assert.equals("ERROR", lines[1])
            assert.equals("WARN", lines[2])
        end)

        it("overwrites previous content", function()
            ui.render({ make_entry("ERROR") })
            ui.render({ make_entry("WARN"), make_entry("FATAL") })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
            assert.equals("WARN", lines[1])
        end)

        it("get_lines skips empty lines", function()
            ui.render({ make_entry("ERROR"), make_entry(""), make_entry("WARN") })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
        end)

        it("get_lines preserves whitespace-only lines", function()
            ui.render({ make_entry(" "), make_entry("ERROR") })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
            assert.equals(" ", lines[1])
        end)
    end)

    describe("open/close", function()
        it("opens and closes", function()
            ui.open()
            assert.is_true(ui.win ~= nil and vim.api.nvim_win_is_valid(ui.win))
            ui.close()
            assert.is_false(ui.win ~= nil and vim.api.nvim_win_is_valid(ui.win))
        end)

        it("toggle works", function()
            ui.toggle()
            assert.is_true(ui.win ~= nil and vim.api.nvim_win_is_valid(ui.win))
            ui.toggle()
            assert.is_false(ui.win ~= nil and vim.api.nvim_win_is_valid(ui.win))
        end)

        it("open is idempotent", function()
            ui.open()
            local win = ui.win
            ui.open()
            assert.equals(win, ui.win)
        end)

        it("close when not open is safe", function()
            ui.close()
            assert.is_false(ui.win ~= nil and vim.api.nvim_win_is_valid(ui.win))
        end)
    end)

    describe("on_write", function()
        it("fires callback on BufWriteCmd", function()
            local called = false
            ui.on_write = function()
                called = true
            end
            ui.render({ make_entry("ERROR") })
            vim.api.nvim_exec_autocmds("BufWriteCmd", { buffer = ui.buf })
            assert.is_true(called)
        end)

        it("clears modified flag after write", function()
            ui.on_write = function() end
            ui.render({ make_entry("ERROR") })
            vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
            vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, { "CHANGED" })
            assert.is_true(vim.api.nvim_get_option_value("modified", { buf = ui.buf }))
            vim.api.nvim_exec_autocmds("BufWriteCmd", { buffer = ui.buf })
            assert.is_false(vim.api.nvim_get_option_value("modified", { buf = ui.buf }))
        end)
    end)
end)
