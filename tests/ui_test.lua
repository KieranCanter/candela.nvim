describe("candela.ui", function()
    local ui

    before_each(function()
        package.loaded["candela.ui"] = nil
        package.loaded["candela.config"] = nil
        package.loaded["candela"] = nil

        -- Stub config so ui.ensure_init works
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

    describe("render + compute_diff", function()
        it("returns nil diff when nothing changed", function()
            ui.render({ "ERROR", "WARN" })
            local diff = ui.compute_diff()
            assert.is_not_nil(diff)
            assert.equals(0, #diff.edits)
            assert.equals(0, #diff.adds)
            assert.equals(0, #diff.deletes)
        end)

        it("detects edits", function()
            ui.render({ "ERROR", "WARN" })
            vim.api.nvim_buf_set_lines(ui.buf, 0, 1, false, { "FATAL" })
            local diff = ui.compute_diff()
            assert.equals(1, #diff.edits)
            assert.equals("ERROR", diff.edits[1].old)
            assert.equals("FATAL", diff.edits[1].new)
        end)

        it("detects adds", function()
            ui.render({ "ERROR" })
            vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
            vim.api.nvim_buf_set_lines(ui.buf, 1, 1, false, { "WARN" })
            local diff = ui.compute_diff()
            assert.equals(1, #diff.adds)
            assert.equals("WARN", diff.adds[1])
        end)

        it("detects deletes", function()
            ui.render({ "ERROR", "WARN" })
            vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
            vim.api.nvim_buf_set_lines(ui.buf, 1, 2, false, {})
            local diff = ui.compute_diff()
            assert.equals(1, #diff.deletes)
            assert.equals(2, diff.deletes[1])
        end)

        it("rejects duplicates", function()
            ui.render({ "ERROR" })
            vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
            vim.api.nvim_buf_set_lines(ui.buf, 1, 1, false, { "ERROR" })
            local diff = ui.compute_diff()
            assert.is_nil(diff)
        end)

        it("rejects empty lines", function()
            ui.render({ "ERROR" })
            vim.api.nvim_set_option_value("modifiable", true, { buf = ui.buf })
            vim.api.nvim_buf_set_lines(ui.buf, 1, 1, false, { "" })
            local diff = ui.compute_diff()
            assert.is_nil(diff)
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
    end)
end)
