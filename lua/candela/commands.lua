-- Module for defining user commands
local CandelaUi = require("candela.ui")

local CandelaCommands = {}
CandelaCommands.commands = {}

CandelaCommands.commands.add = function()
    CandelaUi.show_patterns()
    CandelaUi.add()
end

CandelaCommands.commands.edit = function()
    CandelaUi.edit()
end

CandelaCommands.commands.copy = function()
    CandelaUi.copy()
end

CandelaCommands.commands.delete = function()
    CandelaUi.delete()
end

CandelaCommands.commands.clear = function()
    CandelaUi.clear()
end

CandelaCommands.commands.change_color = function()
    CandelaUi.change_color()
end

CandelaCommands.commands.toggle_highlight = function()
    CandelaUi.toggle_highlight()
end

CandelaCommands.commands.toggle_lightbox = function()
    CandelaUi.toggle_lightbox()
end

CandelaCommands.commands.match = function()
    CandelaUi.match()
end

CandelaCommands.commands.find = function()
    CandelaUi.find()
    vim.api.nvim_cmd({ cmd = "lnext" }, {})
    vim.api.nvim_cmd({ cmd = "lopen" }, {})
end

CandelaCommands.commands.find_all = function()
    CandelaUi.find_all()
    vim.api.nvim_cmd({ cmd = "lnext" }, {})
    vim.api.nvim_cmd({ cmd = "lopen" }, {})
end

CandelaCommands.commands.help = function()
    if vim.api.nvim_get_current_win() ~= CandelaUi.windows.regex.win then
        vim.notify("Candela: must be in patterns window to see menu commands", vim.log.levels.ERROR)
        return
    end
    vim.notify("Candela: help subcommand not implemented yet", vim.log.levels.WARN)
    CandelaUi.help()
end

CandelaCommands.commands.health = function()
    vim.cmd.checkhealth("candela")
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
