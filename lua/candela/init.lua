--[[
--  Candela regex highlighter
--
--  * List of patterns
--    * Add pattern
--    * Remove pattern
--    * Show patterns
--    * Clear patterns
--  * Pattern
--    * Change color
--    * Toggle highlighting
--    * Toggle pattern showing up in lightbox
--  * Syntax highlighting option true or false
--  * Lightbox
--    * separate buffer/window for only "lightbox" true patterns
--
--  * Neovim API equivalents
--    * vim.api.nvim_<get|set>_option_value() = vim.bo, vim.b, vim.wo, vim.w, vim.t, vim.o, vim.go
--    * vim.api.nvim_cmd() or vim.api.nvim_exec2() = vim.cmd() or vim.cmd [[]]
--    * vim.api.nvim_win_get_cursor(0)[1] = vim.fn.line('.')
--    * vim.api.nvim_win_get_cursor(0)[2] + 1 = vim.fn.line('.')
--    * vim.api.nvim_buf_get_name(0) = vim.fn.expand('%:p') (path name)
--
--  * future improvements
--    * TODO: implement "find" command: pressing 'f' on a pattern in the UI sends the regex to vim and lets the user
--            cycle through matches with a keymap (<C-n>?)
--            - use vim.api.nvim.cmd("cgetexpr system(<ripgrep command>)") with :cn/:cp
--            - test with `:cgetexpr system("rg --line-number --color=never --vimgrep 'line' " . expand('%:p'))`
--            - use 'f' for current pattern and 'F' for all patterns
--    * automatically rerun highlighting on buffer change
--    * highlight the color's bg in ui the hex code's appropriate color
--    * implement a good method of color picking?
--]]
--
-- TODO: remove all functions that aren't needed across files from appropriate table e.g.
--       CandelaPatternList.get_next_color() => local get_next_color()

local CandelaUi = require("candela.ui")
local CandelaPatternList = require("candela.pattern_list")
local CandelaCommands = require("candela.commands")
local CandelaConfig = require("candela.config")

---@class Candela
---@field ui CandelaUi
---@field patterns CandelaPattern[]|nil

local Candela = {}
Candela.ui = { windows = {}, base_buf = 0 }
Candela.patterns = {}

function Candela.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(args)
        CandelaCommands.dispatch(args.fargs)
    end, {
        nargs = "?",
        desc = "Regex highlighter",
        complete = function()
           return { "add", "edit", "copy", "remove", "clear", "change_color", "toggle_highlight", "toggle_lightbox" }
        end,
    })

    opts = CandelaConfig.setup(opts)
    Candela.ui = CandelaUi.new(opts)
    Candela.patterns = CandelaPatternList.patterns
end

return Candela
