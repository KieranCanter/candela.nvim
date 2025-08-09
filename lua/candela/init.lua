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
--  * TODO:
--    * lightbox config options
--    * for config options set to system value, resetup affected modules with new option value using autocmd on event OptionSet
--    * lazy load more
--    * import/export pattern list
--    * palettes/colors
--      * better default colors
--      * handle automatic foreground color changing if the colors are too similar in luminosity
--      * give config option to cycle colors constantly or randomly (same colors show first everytime or random selection from palette)
--    * grow and shrink height of patterns window based on how many patterns there are
--    * user config option for min_height/max_height of patterns
--      * autocmd for scrolling regex buffer that scrolls other buffers accordingly
--    * feature for finding/matching selected patterns; refactor find_all/match_all to be find_many/match_many instead
--      * keep short-living "selected list" on patterns window opening
--      * if selected list is zero, run find/match on current pattern
--      * otherwise, run find_many/match_many on selected list
--    * implement help function
--    * write docs
--    * make vim.notify strings consistent with format "[Candela] <message>"
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
    Candela.lightbox = CandelaLightbox.setup(Candela.config)
end

return Candela
