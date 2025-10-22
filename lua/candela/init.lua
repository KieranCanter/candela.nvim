---@class Candela

local M = {}
M.CANDELA_AUGROUP = vim.api.nvim_create_augroup("Candela", { clear = false })

local function init()
    local CandelaCommands = require("candela.commands")
    vim.api.nvim_create_user_command("Candela", function(args)
        CandelaCommands.dispatch(args)
    end, {
        nargs = "*",
        desc = "Regex highlighter",
        complete = function(arglead, cmdline, _)
            -- Get the subcommand.
            local commands = CandelaCommands.commands
            local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Candela[!]*%s(%S+)%s(.*)$")
            if subcmd_key and subcmd_arg_lead and commands[subcmd_key] and commands[subcmd_key].complete then
                -- The subcommand has completions. Return them.
                return commands[subcmd_key].complete(subcmd_arg_lead)
            end
            -- Check if cmdline is a subcommand
            if cmdline:match("^['<,'>]*Candela[!]*%s+%w*$") then
                -- Filter subcommands that match
                local subcommand_keys = vim.tbl_keys(commands)
                return vim.iter(subcommand_keys)
                    :filter(function(key)
                        return key:find(arglead) ~= nil
                    end)
                    :totable()
            end
        end,
        bang = true,
    })

    require("candela.commands").setup()
    require("candela.ui").setup(M.config)
    require("candela.finder").setup(M.config)
    require("candela.pattern_list").setup(M.config)
    require("candela.highlighter").setup()
    require("candela.lightbox").setup(M.config)
    if M.config.syntax_highlighting.enabled then
        require("candela.syntax").enable(M.config.syntax_highlighting)
    end
end

function M.setup(opts)
    M.config = require("candela.config").setup(opts)
    if M.config == nil then
        package.loaded.candela = nil
        return nil
    end

    init()
end

return M
