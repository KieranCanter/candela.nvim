local CandelaWindow = require("candela.window")
local CandelaHighlighter = require("candela.highlighter")
local CandelaConfig = require("candela.config")

-- Lightbox design:
-- * fold-only: remove is too expensive; use neovim's read-only clone buffer feature and fold unmatched + unlightboxed lines
-- * set fml (foldminlines) to 0 so every line can be folded
-- * set foldtext to something better than default
--   * se foldtext=foldtext#minimal()?
--   * vim.opt.foldtext = "v:lua.MinimalFoldText()" with function _G.MinimalFoldText() that returns empty string
--   * se `fillchars=fold:-` or `fillchars=fold\ ` to set fillchars on folded lines
-- * with above, different fold_style options: invisible, minimal, detailed
-- * option fold_style: invisible, minimal, compact, detailed (no fillchars, single fillchars char, full fillchars chars, first folded line shown)
-- * option show_count: show number of folded lines or not
-- * option fillchar: char to use for fillchars=fold:
-- * maintain a table of [row -> {set of active pattern IDs}] in which active pattern IDs are lightbox toggled on
--   * lines with no active patterns are folded
-- * when a pattern is toggled on: unfold all lines covered by matches
-- * when a pattern is toggled off: for each affected line, check if any other pattern covers it (if its active pattern IDs set is empty) and fold if no
-- * :se foldtext=v:foldstart (starting line)
-- * :se foldtext=v:foldend (ending line)
-- * :se foldtext=v:folddashes (single fillchar?)
-- * :se foldtext=v:folddashesv:folddashes (+-- # line(s) folded)
--[[
function _G.Invisible()
  return ""
end
function _G.Count()
    return tostring(vim.v.foldend - vim.v.foldstart + 1)
end
--]]

local M = {}

function M.setup()
    local opts = CandelaConfig.options.lightbox
    local split_dir = opts.view:match("split%-(%a+)") -- match direction if opt set, nil otherwise ("right", "below", etc.)
    local system_split = opts.view:match("system%-(%a+)") -- match split command if opt set, nil otherwise ("split", "vsplit")
    local tab_split = opts.view:match("tab") and "tab split" -- match tab comand if opt set, nil otherwise

    if split_dir == nil then
        M.window = CandelaWindow.new({})
        M.open_command = system_split or tab_split
    else
        M.window = CandelaWindow.new({
            win = 0,
            split = split_dir,
        })
        M.open_command = nil -- no command needed, using win config to specify split direction
    end

    return M
end

function M.display()
    -- open with command
    if M.open_command ~= nil then
        vim.api.nvim_exec2(M.open_command, {})
        M.window.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M.window.win, M.window.buf)
    -- open in split view
    else
        M.window:open_window(true)
    end
    -- set win options
end

function M.refresh()
    M.window.buf = require("candela.ui").base_buf
end

function M.toggle()
    if M.window == nil then
        M.setup()
    end

    -- lightbox is open and currently focused
    if M.window:is_open() and M.window.win == vim.api.nvim_get_current_win() then
        M.window:close_window()
    -- lightbox is open but not focused
    elseif M.window:is_open() then
        vim.api.nvim_set_current_win(M.window.win)
    --lightbox is closed
    else
        M.window.buf = require("candela.ui").base_buf
        M.display()
    end
end

return M
