-- Module for defining commands
local CandelaUi = require("candela.ui")
local CandelaPatternList = require("candela.pattern_list")

local CandelaCommands = {}
CandelaCommands.commands = { "add", "edit", "copy", "remove", "clear", "change_color", "toggle_highlight", "toggle_lightbox" }
-- TODO: add above commands as variables to CandelaCommands holding functions to each command

---@param args table<string, any>
function CandelaCommands.dispatch(args)
    local subcommand = args[1]
    local tail = { unpack(args, 2) }

    if not subcommand or subcommand == "" then
        CandelaUi.toggle()
    elseif subcommand == "add" then
        CandelaUi.show_patterns()
        CandelaUi.show_prompt("add")
    elseif subcommand == "edit" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to edit regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("edit")
    elseif subcommand == "copy" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to copy regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("copy")
    elseif subcommand == "remove" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to remove regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("remove")
    elseif subcommand == "clear" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to clear all", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("clear")
        --CandelaPatternList.clear()
        --CandelaUi.update_lines()
    elseif subcommand == "change_color" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to remove regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("change_color")
    elseif subcommand == "toggle_highlight" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to remove regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("toggle_highlight")
    elseif subcommand == "toggle_lightbox" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to remove regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("toggle_lightbox")
    elseif subcommand == "match" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to match regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("match")
    else
        vim.notify("Candela: unsupported command \"" .. subcommand .. "\"", vim.log.levels.ERROR)
    end
end

return CandelaCommands
