local CandelaWindow = require("candela.window")
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

    M.lightbox_cache = {}
    M.folds_cache = {}

    return M
end

---@param row integer: line number/row
---@param id string: pattern ID
function M.add_to_cache(row, id)
    M.lightbox_cache[row] = M.lightbox_cache[row] or {}
    M.lightbox_cache[row][id] = true
end

---@param matches table[]: table of matches from Highlighter.match_cache
---@param id string: pattern ID
function M.add_many_to_cache(matches, id)
    for _, match in pairs(matches) do
        M.add_to_cache(match.row, id)
    end
end

---@param matches table[]: table of matches from Highlighter.match_cache
---@param id string: pattern ID
function M.remove_from_cache(matches, id)
    if not matches then
        return {}
    end

    for _, match in pairs(matches) do
        local row = match.row
        if M.lightbox_cache[row] then
            M.lightbox_cache[row][id] = nil
            if next(M.lightbox_cache[row]) == nil then
                M.lightbox_cache[row] = nil
            end
        end
    end
end

local function update_folds_cache()
    local total_rows = vim.api.nvim_buf_line_count(M.window.buf)
    local rows = {}

    -- Collect visible matched lines
    for row, _ in pairs(M.lightbox_cache) do
        table.insert(rows, row)
    end

    -- If no matches, fold entire file
    if #rows == 0 then
        M.folds_cache = { { 1, total_rows } }
        return
    end

    table.sort(rows)

    local ranges = {}

    -- Fold before first match if needed
    if rows[1] > 1 then
        table.insert(ranges, { 1, rows[1] - 1 })
    end

    -- Fold gaps inbetween
    for i = 1, #rows - 1 do
        local start = rows[i] + 1
        local ending = rows[i + 1] - 1
        if start <= ending then
            table.insert(ranges, { start, ending })
        end
    end

    -- Fold after last match if needed
    if rows[#rows] < total_rows - 1 then
        table.insert(ranges, { rows[#rows] + 1, total_rows })
    end

    M.folds_cache = ranges
end

---@param row integer
local function delete_fold_at(row)
    if vim.fn.foldclosed(row) == -1 then return end

    vim.api.nvim_win_set_cursor(M.window.win, { row, 0 })
    vim.api.nvim_exec2("normal! zd", {})
end

local function delete_folds()
    local cursor_loc = vim.api.nvim_win_get_cursor(M.window.win)
    vim.api.nvim_win_call(M.window.win, function()
        for _, range in ipairs(M.folds_cache) do
            delete_fold_at(range[1])
        end
    end)
    vim.api.nvim_win_set_cursor(M.window.win, cursor_loc)
    vim.api.nvim_win_call(M.window.win, function()
    vim.api.nvim_exec2("normal! zz", {})
    end)
end

local function fold_ranges()
    vim.api.nvim_win_call(M.window.win, function()
        for _, range in ipairs(M.folds_cache) do
            vim.api.nvim_exec2(string.format("%d,%dfold", range[1], range[2]), {})
        end
    end)
end

function M.update_folds()
    if not M.window:is_open() then
        return
    end

    delete_folds()
    update_folds_cache()
    fold_ranges()
end

function M.display(is_open)
    if is_open then
        vim.api.nvim_set_current_win(M.window.win)
    else
        -- open with command
        if M.open_command ~= nil then
            vim.api.nvim_exec2(M.open_command, {})
            M.window.win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(M.window.win, M.window.buf)
        -- open in split view
        else
            M.window:open_window(true)
        end

        -- set window option values
        vim.api.nvim_set_option_value("foldmethod", "manual", { win = M.window.win })
        vim.api.nvim_set_option_value("foldenable", true, { win = M.window.win })
        vim.api.nvim_set_option_value("foldlevel", 0, { win = M.window.win })
        vim.api.nvim_set_option_value("fml", 0, { win = M.window.win })

        M.update_folds()
    end
end

function M.refresh()
    M.window.buf = require("candela.ui").base_buf
end

function M.toggle()
    local base_buf = require("candela.ui").base_buf
    if not base_buf then
        vim.notify("[Candela] no buffer initialized as match buffer, proceeding with current", vim.log.levels.WARN)
        base_buf = vim.api.nvim_get_current_buf()
    end

    -- lightbox is open and currently focused
    if M.window:is_open() and M.window.win == vim.api.nvim_get_current_win() and vim.api.nvim_win_get_buf(M.window.win) == M.window.buf then
        M.window:close_window()
    -- lightbox is open but not focused
    elseif M.window:is_open() and vim.api.nvim_win_get_buf(M.window.win) == M.window.buf then
        M.window.buf = base_buf
        M.display(true)
        --vim.api.nvim_set_current_win(M.window.win)
        --delete_folds()
    --lightbox is closed
    else
        M.window.buf = base_buf
        M.display(false)
    end
end

return M
