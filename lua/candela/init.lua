local CandelaConfig = require("candela.config")
local CandelaCommands = require("candela.commands")
local CandelaUi = require("candela.ui")
local CandelaPatternList = require("candela.pattern_list")
local CandelaHighlighter = require("candela.highlighter")
local CandelaLightbox = require("candela.lightbox")

---@class Candela
---@field ui CandelaUi
---@field patterns CandelaPattern[]

local Candela = {}

function Candela.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(args)
        CandelaCommands.dispatch(args.fargs)
    end, {
        nargs = "*",
        desc = "Regex highlighter",
        complete = function(arglead, cmdline, _)
            local args = vim.split(cmdline, "%s+")
            local idx = #args - 1 -- skip :Candela argument

            if idx == 1 then
                return vim.tbl_keys(CandelaCommands.commands)
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

    Candela.config = CandelaConfig.setup(opts)
    if Candela.config == nil then
        package.loaded.candela = nil
        return
    end
    Candela.commands = CandelaCommands.setup(Candela.config)
    Candela.ui = CandelaUi.setup(Candela.config)
    Candela.patterns = CandelaPatternList.setup(Candela.config)
    Candela.highlighter = CandelaHighlighter.setup()
    Candela.lightbox = CandelaLightbox.setup(Candela.config)
end

return Candela
