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

    M.lightbox_cache = {}
    M.ranges_cache = {}

    return M
end

---@param row integer: line number/row
---@param id string: pattern ID
function M.add_to_cache(row, id)
    M.lightbox_cache[row] = M.lightbox_cache[row] or {}
    M.lightbox_cache[row][id] = true
end

---@param id string: pattern ID
---@return integer[]
function M.remove_from_cache(id)
    local rows = CandelaHighlighter.match_cache[id]
    if not rows then
        return {}
    end

    local removed = {}

    for row, _ in pairs(rows) do
        if M.lightbox_cache[row] then
            M.lightbox_cache[row][id] = nil
            if next(M.lightbox_cache[row]) == nil then
                M.lightbox_cache[row] = nil
                table.insert(removed, row)
            end
        end
    end

    return removed
end

---@return table[]
local function get_ranges()
    local total_rows = vim.api.nvim_buf_line_count(M.window.buf)
    local rows = {}

    -- Collect visible matched lines
    for row, _ in pairs(M.lightbox_cache) do
        table.insert(rows, row)
    end

    -- If no matches, fold entire file
    if #rows == 0 then
        return { { 0, total_rows - 1 } }
    end

    table.sort(rows)

    local ranges = {}
    local prev = -1

    -- Fold before first match if needed
    if rows[1] > 0 then
        table.insert(ranges, { 0, rows[1] - 1 })
    end

    -- Fold gaps inbetween
    for i = 1, #rows - 1 do
        local start = rows[i] + 1
        local ending = rows[i+1] - 1
        if start <= ending then
            table.insert(ranges, { start, ending })
        end
    end

    -- Fold after last match if needed
    if rows[#rows] < total_rows - 1 then
        table.insert(ranges, { rows[#rows] + 1, total_rows })
    end

    return ranges
end

---@param win integer
---@param ranges table[]
local function fold_ranges(win, ranges)
    vim.api.nvim_win_call(win, function()
        for _, range in ipairs(ranges) do
            vim.api.nvim_exec2(string.format("%d,%dfold", range[1], range[2]), {})
        end
    end)
end

---@param win integer
---@param ranges table[]
local function unfold_ranges(win, ranges)
    vim.api.nvim_win_call(win, function()
        for _, range in ipairs(ranges) do
            vim.api.nvim_exec2(string.format("%d,%dfoldopen", range[1], range[2]), {})
        end
    end)
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

    -- set window option values
    vim.api.nvim_set_option_value("foldmethod", "manual", { win = M.window.win })
    vim.api.nvim_set_option_value("foldenable", true, { win = M.window.win })
    vim.api.nvim_set_option_value("foldlevel", 0, { win = M.window.win })

    local ranges = get_ranges()
    print(vim.inspect(ranges))
    fold_ranges(M.window.win, ranges)
end

function M.refresh()
    M.window.buf = require("candela.ui").base_buf
end

function M.toggle()
    --if M.window == nil then
    --    M.setup()
    --end

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
