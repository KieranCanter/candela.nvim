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
        package.loaded["candela"] = nil

        package.loaded["candela.config"] = {
            options = {
                icons = { candela = "C" },
                window = { width = 0.5, min_height = 5, max_height = 30, margin = 16 },
            },
        }
        package.loaded["candela"] = { augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }) }

        ui = require("candela.ui")
    end)

    after_each(function()
        if ui.is_open() then
            ui.close()
        end
    end)

    describe("render + get_lines", function()
        it("sets buffer content", function()
            ui.render({ "ERROR", "WARN" })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
            assert.equals("ERROR", lines[1])
            assert.equals("WARN", lines[2])
        end)

        it("overwrites previous content", function()
            ui.render({ "ERROR" })
            ui.render({ "WARN", "FATAL" })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
            assert.equals("WARN", lines[1])
        end)

        it("get_lines skips empty lines", function()
            ui.render({ "ERROR", "", "WARN" })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
        end)

        it("get_lines preserves whitespace-only lines", function()
            ui.render({ " ", "ERROR" })
            local lines = ui.get_lines()
            assert.equals(2, #lines)
            assert.equals(" ", lines[1])
        end)
    end)

    describe("open/close", function()
        it("opens and closes", function()
            ui.open()
            assert.is_true(ui.is_open())
            ui.close()
            assert.is_false(ui.is_open())
        end)

        it("toggle works", function()
            ui.toggle()
            assert.is_true(ui.is_open())
            ui.toggle()
            assert.is_false(ui.is_open())
        end)

        it("open is idempotent", function()
            ui.open()
            local win = ui.win
            ui.open()
            assert.equals(win, ui.win)
        end)

        it("close when not open is safe", function()
            ui.close()
            assert.is_false(ui.is_open())
        end)
    end)

    describe("on_write", function()
        it("fires callback on BufWriteCmd", function()
            local called = false
            ui.on_write = function()
                called = true
            end
            ui.render({ "ERROR" })
            -- Simulate :w by executing the BufWriteCmd autocmd
            vim.api.nvim_exec_autocmds("BufWriteCmd", { buffer = ui.buf })
            assert.is_true(called)
        end)

        it("clears modified flag after write", function()
            ui.on_write = function() end
            ui.render({ "ERROR" })
            vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
            vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, { "CHANGED" })
            assert.is_true(vim.api.nvim_get_option_value("modified", { buf = ui.buf }))
            vim.api.nvim_exec_autocmds("BufWriteCmd", { buffer = ui.buf })
            assert.is_false(vim.api.nvim_get_option_value("modified", { buf = ui.buf }))
        end)
    end)
end)
