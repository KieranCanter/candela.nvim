-- Module for defining commands
local CandelaUi = require("candela.ui")
local CandelaPatternList = require("candela.pattern_list")

local CandelaCommands = {}
CandelaCommands.commands = {}

CandelaCommands.commands.add = function()
    CandelaUi.show_patterns()
    CandelaUi.show_prompt("add")
end

CandelaCommands.commands.edit = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to edit regex", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("edit")
end

CandelaCommands.commands.copy = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to copy regex", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("copy")
end

CandelaCommands.commands.delete = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to delete regex", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("delete")
end

CandelaCommands.commands.clear = function()
    CandelaUi.show_prompt("clear")
end

CandelaCommands.commands.change_color = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to change regex color", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("change_color")
end

CandelaCommands.commands.toggle_highlight = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex highlight", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("toggle_highlight")
end

CandelaCommands.commands.toggle_lightbox = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex lightbox", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("toggle_lightbox")
end

CandelaCommands.commands.match = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to match regex", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("match")
end

CandelaCommands.commands.find = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to find instances of regex", vim.log.levels.ERROR)
        return
    end
    CandelaUi.show_prompt("find")
    vim.api.nvim_cmd({ cmd = "lnext" }, {})
    vim.api.nvim_cmd({ cmd = "lopen" }, {})
end

CandelaCommands.commands.find_all = function()
    CandelaUi.show_prompt("find_all")
    vim.api.nvim_cmd({ cmd = "lnext" }, {})
    vim.api.nvim_cmd({ cmd = "lopen" }, {})
end

CandelaCommands.commands.help = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to see menu commands", vim.log.levels.ERROR)
        return
    end
    vim.notify("Candela: help subcommand not implemented yet", vim.log.levels.WARN)
end

---@param args table<string, any>
function CandelaCommands.dispatch(args)
    local subcommand = args[1]

    if not subcommand or subcommand == "" then
        CandelaUi.toggle()
    elseif CandelaCommands.commands[subcommand] ~= nil then
        CandelaCommands.commands[subcommand]()
    else
        vim.notify('Candela: unsupported command "' .. subcommand .. '"', vim.log.levels.ERROR)
    end
end

return CandelaCommands
