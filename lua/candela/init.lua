---@class Candela
---@field ui CandelaUi
---@field patterns CandelaPattern[]

local Candela = {}

function Candela.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(args)
        require("candela.commands").dispatch(args.fargs)
    end, {
        nargs = "*",
        desc = "Regex highlighter",
        complete = function(arglead, cmdline, _)
            local args = vim.split(cmdline, "%s+")
            local idx = #args - 1 -- skip :Candela argument

            if idx == 1 then
                return vim.tbl_keys(require("candela.commands").commands)
            elseif idx == 2 then
                local sub = args[2]
                -- TODO: allow other appropriate commands to receive args
                -- :Candela add <regex> or :Candela add { regex = <regex>, [color = <hex_code>], [highlight = <boolean>], [lightbox = <boolean>] }
                -- :Candela delete <regex> or :Candela delete <index>
                if sub == "import" or sub == "export" then
                    return vim.fn.getcompletion(arglead, "file")
                end
            end
        end,
    })

    Candela.config = require("candela.config").setup(opts)
    if Candela.config == nil then
        package.loaded.candela = nil
        return
    end
    Candela.commands = require("candela.commands").setup(Candela.config)
    Candela.ui = require("candela.ui").setup(Candela.config)
    require("candela.finder").setup(Candela.config)
    Candela.patterns = require("candela.pattern_list").setup(Candela.config)
    Candela.highlighter = require("candela.highlighter").setup()
    Candela.lightbox = require("candela.lightbox").setup(Candela.config)
end

return Candela
