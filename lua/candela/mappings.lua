M = {}

function M.set_float_keymaps()
    local CandelaUi = require("candela.ui")
    local CandelaCommands = require("candela.commands")
    local regex_buf = CandelaUi.windows.regex.buf --[[@as integer]]
    local prompt_buf = CandelaUi.windows.prompt.buf --[[@as integer]]

    local keymap_info = {
        [regex_buf] = {
            {
                lhs = "q",
                desc = "[Candela] close UI",
                callback = function()
                    CandelaUi.hide_patterns()
                end,
            },
            {
                lhs = "<ESC>",
                desc = "[Candela] close UI",
                callback = function()
                    CandelaUi.hide_patterns()
                end,
            },
            {
                lhs = "a",
                desc = "[Candela] add pattern",
                callback = function()
                    CandelaCommands.commands.add.impl()
                end,
            },
            {
                lhs = "e",
                desc = "[Candela] edit pattern",
                callback = function()
                    CandelaCommands.commands.edit.impl()
                end,
            },
            {
                lhs = "c",
                desc = "[Candela] copy pattern",
                callback = function()
                    CandelaCommands.commands.copy.impl()
                end,
            },
            {
                lhs = "d",
                desc = "[Candela] delete pattern",
                callback = function()
                    CandelaCommands.commands.delete.impl()
                end,
            },
            {
                lhs = "D",
                desc = "[Candela] clear all patterns",
                callback = function()
                    CandelaCommands.commands.clear.impl()
                end,
            },
            {
                lhs = "C",
                desc = "[Candela] change pattern color",
                callback = function()
                    CandelaCommands.commands.change_color.impl()
                end,
            },
            {
                lhs = "h",
                desc = "[Candela] toggle pattern highlight",
                callback = function()
                    CandelaCommands.commands.toggle_highlight.impl()
                end,
            },
            {
                lhs = "l",
                desc = "[Candela] toggle pattern lightbox",
                callback = function()
                    CandelaCommands.commands.toggle_lightbox.impl()
                end,
            },
            {
                lhs = "R",
                desc = "[Candela] refresh patterns for current buffer",
                callback = function()
                    CandelaCommands.commands.refresh.impl()
                end,
            },
            {
                lhs = "m",
                desc = "[Candela] vim match selected patterns",
                callback = function()
                    CandelaUi.locate(false, require("candela.finder").match)
                end,
            },
            {
                lhs = "M",
                desc = "[Candela] vim match all patterns",
                callback = function()
                    CandelaUi.locate(true, require("candela.finder").match)
                end,
            },
            {
                lhs = "f",
                desc = "[Candela] find selected patterns and send to location list",
                callback = function()
                    CandelaUi.locate(false, require("candela.finder").find)
                end,
            },
            {
                lhs = "F",
                desc = "[Candela] find all patterns and send to location list",
                callback = function()
                    CandelaUi.locate(true, require("candela.finder").find)
                end,
            },
            {
                lhs = "L",
                desc = "[Candela] toggle lightbox",
                callback = function()
                    CandelaCommands.commands.lightbox.impl()
                end,
            },
            {
                lhs = "I",
                desc = "[Candela] import patterns from file",
                callback = function()
                    CandelaUi.import()
                end,
            },
            {
                lhs = "E",
                desc = "[Candela] export patterns to file",
                callback = function()
                    CandelaUi.export()
                end,
            },
            {
                lhs = "<TAB>",
                desc = "[Candela] toggle selection of current pattern",
                callback = function()
                    CandelaUi.toggle_select_pattern()
                end,
            },
            {
                lhs = "?",
                desc = "[Candela] display keymaps",
                callback = function()
                    CandelaCommands.commands.help.impl()
                end,
            },
        },
        [prompt_buf] = {
            {
                lhs = "q",
                desc = "[Candela] close prompt",
                callback = function()
                    CandelaUi.hide_prompt()
                end,
            },
            {
                lhs = "<ESC>",
                desc = "[Candela] close prompt",
                callback = function()
                    CandelaUi.hide_prompt()
                end,
            },
        },
    }

    for bufnr, keymaps in pairs(keymap_info) do
        for _, keymap in ipairs(keymaps) do
            vim.api.nvim_buf_set_keymap(bufnr, "n", keymap.lhs, "", {
                noremap = true,
                silent = true,
                desc = keymap.desc,
                callback = keymap.callback,
            })
        end
    end

end

return M
