local M = {}
M.lightbox_cache = {} ---@type table<integer, table<string, boolean>>
M.folds_cache = {} ---@type integer[][]
M.win = nil
M.buf = nil

---@return boolean
local function is_open()
    return M.win ~= nil and vim.api.nvim_win_is_valid(M.win)
end

---@param start_line integer
---@return string
local function get_foldtext_preview(start_line)
    return ((vim.fn.getline(start_line) or ""):gsub("\t", "    "):gsub("^%s+", ""))
end

---@return string
function M.generate_foldtext()
    local start_line = vim.v.foldstart
    local count = vim.v.foldend - start_line + 1
    local preview = get_foldtext_preview(start_line)
    local config = require("candela.config").options.lightbox

    if config.fold_style == "fillchar" then
        return string.rep(config.fillchar, vim.api.nvim_win_get_width(0))
    elseif config.fold_style == "count" then
        return count == 1 and "1 line" or (count .. " lines")
    elseif config.fold_style == "preview" then
        return "next line: " .. preview
    elseif config.fold_style == "detailed" then
        return (count == 1 and "1 line" or (count .. " lines")) .. ": " .. preview
    else
        return vim.fn.foldtext()
    end
end

---@param row integer 1-indexed line number
---@param regex string pattern key
function M.add_to_cache(row, regex)
    M.lightbox_cache[row] = M.lightbox_cache[row] or {}
    M.lightbox_cache[row][regex] = true
end

---@param matches Candela.Highlight[]|nil
---@param regex string
function M.add_many_to_cache(matches, regex)
    if not matches then
        return
    end
    for _, match in pairs(matches) do
        M.add_to_cache(match.row, regex)
    end
end

---@param matches Candela.Highlight[]|nil
---@param regex string
function M.remove_from_cache(matches, regex)
    if not matches then
        return
    end
    for _, match in pairs(matches) do
        if M.lightbox_cache[match.row] then
            M.lightbox_cache[match.row][regex] = nil
            if next(M.lightbox_cache[match.row]) == nil then
                M.lightbox_cache[match.row] = nil
            end
        end
    end
end

local function compute_fold_ranges()
    local total = vim.api.nvim_buf_line_count(M.buf)
    local rows = {}
    for row in pairs(M.lightbox_cache) do
        table.insert(rows, row)
    end

    if #rows == 0 then
        M.folds_cache = { { 1, total } }
        return
    end
    table.sort(rows)

    local ranges = {}
    if rows[1] > 1 then
        table.insert(ranges, { 1, rows[1] - 1 })
    end
    for i = 1, #rows - 1 do
        if rows[i] + 1 <= rows[i + 1] - 1 then
            table.insert(ranges, { rows[i] + 1, rows[i + 1] - 1 })
        end
    end
    if rows[#rows] < total then
        table.insert(ranges, { rows[#rows] + 1, total })
    end

    M.folds_cache = ranges
end

--- Toggle a pattern's lightbox state and update cache/folds.
---@param regex string
function M.toggle_pattern(regex)
    local is_on = require("candela.patterns").toggle_lightbox(regex)
    local matches = require("candela.highlighter").match_cache[regex]
    if is_on then
        M.add_many_to_cache(matches, regex)
    else
        M.remove_from_cache(matches, regex)
    end
    M.update_folds()
end

--- Recompute and apply folds in the lightbox window.
function M.update_folds()
    if not is_open() then
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(M.win)

    -- Delete all existing folds
    vim.api.nvim_win_call(M.win, function()
        vim.cmd("normal! zE")
    end)

    -- Recompute and apply
    compute_fold_ranges()
    vim.api.nvim_win_call(M.win, function()
        for _, range in ipairs(M.folds_cache) do
            vim.cmd(string.format("%d,%dfold", range[1], range[2]))
        end
    end)

    -- Restore cursor (clamp to valid range)
    local line_count = vim.api.nvim_buf_line_count(M.buf)
    local row = math.min(cursor[1], line_count)
    vim.api.nvim_win_set_cursor(M.win, { row, cursor[2] })
end

--- Parse a view string into a win_config or vim command.
---@param view Candela.LightboxConfig.View
---@return vim.api.keyset.win_config|string
local function parse_view(view)
    local split_dir = view:match("split%-(%a+)")
    if split_dir then
        return { win = 0, split = split_dir }
    end
    local system_split = view:match("system%-(%a+)")
    if system_split then
        return system_split
    end
    if view:match("tab") then
        return "tab split"
    end
    return "vsplit"
end

local function apply_window_options(win)
    vim.api.nvim_set_option_value("foldmethod", "manual", { win = win })
    vim.api.nvim_set_option_value("foldenable", true, { win = win })
    vim.api.nvim_set_option_value("foldlevel", 0, { win = win })
    vim.api.nvim_set_option_value("foldminlines", 0, { win = win })

    local config = require("candela.config").options.lightbox
    vim.api.nvim_set_option_value("fillchars", "fold:" .. config.fillchar, { win = win })
    local foldtext = config.custom_foldtext and "v:lua.require'candela.lightbox'.custom_foldtext()"
        or "v:lua.require'candela.lightbox'.generate_foldtext()"
    vim.api.nvim_set_option_value("foldtext", foldtext, { win = win })
end

--- Open the lightbox in the given view.
---@param view Candela.LightboxConfig.View
function M.open(view)
    local base = require("candela.highlighter").base_buf
    if not base then
        base = vim.api.nvim_get_current_buf()
        require("candela.highlighter").base_buf = base
    end
    M.buf = base

    local result = parse_view(view)
    if type(result) == "string" then
        vim.cmd(result)
        M.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M.win, M.buf)
    else
        M.win = vim.api.nvim_open_win(M.buf, true, result)
    end

    apply_window_options(M.win)
    M.update_folds()
end

function M.close()
    if is_open() then
        vim.api.nvim_win_close(M.win, true)
        M.win = nil
    end
end

--- Toggle lightbox window. Opens with given view, closes if already open and focused.
---@param view? Candela.LightboxConfig.View defaults to "system-vsplit"
function M.toggle(view)
    view = view or "system-vsplit"

    if is_open() and M.win == vim.api.nvim_get_current_win() then
        M.close()
    elseif is_open() then
        vim.api.nvim_set_current_win(M.win)
    else
        M.open(view)
    end
end

--- Refresh lightbox buffer to match current base buffer.
function M.refresh()
    local base = require("candela.highlighter").base_buf
    if not base then
        return
    end
    M.buf = base
    if is_open() then
        local view = "system-vsplit" -- re-open with default
        M.close()
        M.open(view)
    end
end

return M
