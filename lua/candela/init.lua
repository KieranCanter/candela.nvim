--[[
--  Candela regex highlighter
--
--
--  * Neovim API equivalents
--    * vim.api.nvim_<get|set>_option_value() = vim.bo, vim.b, vim.wo, vim.w, vim.t, vim.o, vim.go
--    * vim.api.nvim_cmd() or vim.api.nvim_exec2() = vim.cmd() or vim.cmd [[]]
--    * vim.api.nvim_win_get_cursor(0)[1] = vim.fn.line('.')
--    * vim.api.nvim_win_get_cursor(0)[2] + 1 = vim.fn.line('.')
--    * vim.api.nvim_buf_get_name(0) = vim.fn.expand('%:p') (path name)
--
--  * future improvements
--    * lightbox duh
--    * add verify_opts function to each that takes opts
--    * lazy load more
--    * import/export pattern list
--    * handle automatic foreground color changing if the colors are too similar in luminosity
--]]
--
-- TODO: remove all functions that aren't needed across files from appropriate table e.g.
--       CandelaPatternList.get_next_color() => local get_next_color()

local CandelaConfig = require("candela.config")
local CandelaCommands = require("candela.commands")
local CandelaUi = require("candela.ui")
local CandelaPatternList = require("candela.pattern_list")
local CandelaHighlighter = require("candela.highlighter")
local CandelaLightbox = require("candela.lightbox")

---@class Candela
---@field ui CandelaUi
---@field patterns CandelaPattern[]|nil

local Candela = {}

function Candela.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(args)
        CandelaCommands.dispatch(args.fargs)
    end, {
        nargs = "?",
        desc = "Regex highlighter",
        complete = function()
            local commands = {}
            for comm, _ in pairs(CandelaCommands.commands) do
                table.insert(commands, comm)
            end
            return commands
        end,
    })

    Candela.config = CandelaConfig.setup(opts)
    Candela.commands = CandelaCommands.setup(Candela.config)
    Candela.ui = CandelaUi.setup(Candela.config)
    Candela.patterns = CandelaPatternList.setup(Candela.config)
    Candela.highlighter = CandelaHighlighter.setup()
    Candela.lightbox = CandelaLightbox.setup(Candela.config)
end

return Candela
