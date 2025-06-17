-- Module for defining commands

local CandelaCommands = {}

function CandelaCommands.setup()
    vim.api.nvim_create_user_command("Candela", function()
        require("candela.ui"):toggle()
    end, {})
end

return CandelaCommands
