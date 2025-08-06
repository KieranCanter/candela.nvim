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
--    * for config options set to system value, resetup affected modules with new option value using autocmd on event OptionSet
--    * lazy load more
--    * design solution for patterns that are too long for line (set nowrap or create a SSOT for line numbers to print?)
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
---@field patterns CandelaPattern[]

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
    if Candela.config == nil then
        package.loaded.candela = nil
        return
    end
    Candela.commands = CandelaCommands.setup(Candela.config)
    Candela.ui = CandelaUi.setup(Candela.config)
    Candela.patterns = CandelaPatternList.setup(Candela.config)
    Candela.highlighter = CandelaHighlighter.setup()
    Candela.lightbox = CandelaLightbox.setup()
end

return Candela
