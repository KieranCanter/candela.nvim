-- Module for defining commands
local CandelaUi = require("candela.ui")
local CandelaPatternList = require("candela.pattern_list")

local CandelaCommands = {}
CandelaCommands.commands = {
    "add",
    "edit",
    "copy",
    "delete",
    "clear",
    "change_color",
    "toggle_highlight",
    "toggle_lightbox",
    "refresh",
    "match",
    "find",
    "find_all",
    "help",
}
-- TODO: add above commands as variables to CandelaCommands holding functions to each command

---@param args table<string, any>
function CandelaCommands.dispatch(args)
    local subcommand = args[1]

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
    elseif subcommand == "delete" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to delete regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("delete")
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
            vim.notify("Candela: must be in patterns window to change regex color", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("change_color")
    elseif subcommand == "toggle_highlight" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to toggle regex highlight", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("toggle_highlight")
    elseif subcommand == "toggle_lightbox" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to toggle regex lightbox", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("toggle_lightbox")
    elseif subcommand == "refresh" then
        CandelaUi.refresh_all()
    elseif subcommand == "match" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to match regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("match")
    elseif subcommand == "find" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to find instances of regex", vim.log.levels.ERROR)
            return
        end
        CandelaUi.show_prompt("find")
        vim.api.nvim_cmd({ cmd = "lnext" }, {})
        vim.api.nvim_cmd({ cmd = "lopen" }, {})
    elseif subcommand == "find_all" then
        CandelaUi.show_prompt("find_all")
        vim.api.nvim_cmd({ cmd = "lnext" }, {})
        vim.api.nvim_cmd({ cmd = "lopen" }, {})
    elseif subcommand == "help" then
        if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
            vim.notify("Candela: must be in patterns window to see menu commands", vim.log.levels.ERROR)
            return
        end
        vim.notify("Candela: help subcommand not implemented yet", vim.log.levels.WARN)
    else
        vim.notify('Candela: unsupported command "' .. subcommand .. '"', vim.log.levels.ERROR)
    end
end

return CandelaCommands
