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
local BUFNAME = "lightbox"

local function set_buf_options()
    M.window.buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value("swapfile", false, { buf = M.window.buf })
    vim.api.nvim_set_option_value("filetype", "candela", { buf = M.window.buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = M.window.buf })
end

function M.setup()
    local view_mode = CandelaConfig.options.lightbox.view:match("split%-(%a+)")
    local window = nil

    if view_mode == nil then
        window = CandelaWindow.new({})
    else
        window = CandelaWindow.new({
            win = 0,
            split = view_mode,
        })
    end
    M.window = window

    set_buf_options()
    vim.api.nvim_buf_set_name(M.window.buf, BUFNAME)

    return M
end

local function write_lightbox_with_fold(base_buf)
    vim.notify("write_lightbox_with_fold() not implemented yet", vim.log.levels.WARN)
end

local function write_lightbox_with_remove(base_buf)
    local old_lines = vim.api.nvim_buf_get_lines(base_buf, 0, -1, false)

    -- match_cache: table of form { lineno, pattern, ns, hl_group }
    local match_cache = CandelaHighlighter.get_flattened_match_cache()

    for i, match in ipairs(match_cache) do
        local curr = ""
        if CandelaConfig.options.lightbox.trim_space then
            curr = string.match(old_lines[match.lineno], "%s*(%a.*%a)%s*")
        else
            curr = old_lines[match.lineno]
        end
        vim.api.nvim_buf_set_lines(M.window.buf, i - 1, i, false, { curr })
        if CandelaConfig.options.lightbox.hl_eol then
            vim.api.nvim_buf_set_extmark(M.window.buf, match.ns, i - 1, 0, {
                line_hl_group = match.hl_group,
                priority = 100,
            })
        else
            vim.api.nvim_buf_set_extmark(M.window.buf, match.ns, i - 1, 0, {
                end_col = string.len(curr),
                hl_group = match.hl_group,
                priority = 100,
            })
        end
    end
end

function M.write_lightbox()
    local base_buf = require("candela.ui").base_buf
    if base_buf == nil then
        return
    end

    if CandelaConfig.options.lightbox.hide_method == "fold" then
        write_lightbox_with_fold()
    else
        write_lightbox_with_remove(base_buf)
    end
end

function M.display()
    M.write_lightbox()

    -- open in tab view
    if CandelaConfig.options.lightbox.view == "tab" then
        if M.tab ~= nil and vim.api.nvim_tabpage_is_valid(M.tab) then
            vim.api.nvim_tabpage_set_win(M.tab, M.window.win)
        else
            vim.api.nvim_cmd({ cmd = "tabnew" }, {})
            local temp_buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_cmd({ cmd = "buffer", args = { string.format("%s", M.window.buf) } }, {})
            M.window.win = vim.api.nvim_get_current_win()
            vim.api.nvim_buf_delete(temp_buf, { force = true })
        end
        M.window.win = vim.api.nvim_get_current_win()
        set_buf_options()
    -- open in split view
    else
        M.window:open_window(true)
    end
end

function M.toggle()
    if M.window == nil then
        M.setup()
    end

    if M.window:is_open() and M.window.win == vim.api.nvim_get_current_win() then
        M.window:close_window()
    elseif M.window:is_open() then
        vim.api.nvim_set_current_win(M.window.win)
    else
        M.display()
    end
end

return M
