---@alias CandelaFoldStyle "nvim"|"fillchar"|"count"|"preview"|"detailed"

local M = {}
M.lightbox_cache = {} ---@type table<integer, table<string, boolean>>
M.folds_cache = {} ---@type integer[][]
M.win = nil
M.buf = nil
M.win_config = nil

---@return boolean
local function is_open()
    return M.win ~= nil and vim.api.nvim_win_is_valid(M.win)
end

---@param start_line integer
---@return string
local function get_foldtext_preview(start_line)
    return (vim.fn.getline(start_line) or ""):gsub("\t", "    "):gsub("^%s+", "")
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

--- Initialize window config from user options. Idempotent.
function M.init()
    if M.win_config then
        return
    end
    local opts = require("candela.config").options.lightbox

    local split_dir = opts.view:match("split%-(%a+)")
    local system_split = opts.view:match("system%-(%a+)")
    local tab_split = opts.view:match("tab") and "tab split"

    if split_dir then
        M.win_config = { win = 0, split = split_dir }
        M.open_command = nil
    else
        M.win_config = {}
        M.open_command = system_split or tab_split
    end
end

---@param row integer 1-indexed line number
---@param regex string pattern key
function M.add_to_cache(row, regex)
    M.lightbox_cache[row] = M.lightbox_cache[row] or {}
    M.lightbox_cache[row][regex] = true
end

---@param matches MatchEntry[]|nil
---@param regex string
function M.add_many_to_cache(matches, regex)
    if not matches then
        return
    end
    for _, match in pairs(matches) do
        M.add_to_cache(match.row, regex)
    end
end

---@param matches MatchEntry[]|nil
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

--- Recompute and apply folds in the lightbox window.
function M.update_folds()
    if not is_open() then
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(M.win)
    vim.api.nvim_win_call(M.win, function()
        for _, range in ipairs(M.folds_cache) do
            if vim.fn.foldclosed(range[1]) ~= -1 then
                vim.api.nvim_win_set_cursor(M.win, { range[1], 0 })
                vim.cmd("normal! zd")
            end
        end
    end)

    compute_fold_ranges()

    vim.api.nvim_win_call(M.win, function()
        for _, range in ipairs(M.folds_cache) do
            vim.cmd(string.format("%d,%dfold", range[1], range[2]))
        end
    end)
    vim.api.nvim_win_set_cursor(M.win, cursor)
end

---@param currently_open boolean
function M.display(currently_open)
    M.init()
    if currently_open then
        vim.api.nvim_set_current_win(M.win)
        return
    end

    if M.open_command then
        vim.cmd(M.open_command)
        M.win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M.win, M.buf)
    else
        M.win = vim.api.nvim_open_win(M.buf, true, M.win_config)
    end

    local win = M.win
    vim.api.nvim_set_option_value("foldmethod", "manual", { win = win })
    vim.api.nvim_set_option_value("foldenable", true, { win = win })
    vim.api.nvim_set_option_value("foldlevel", 0, { win = win })

    local config = require("candela.config").options.lightbox
    vim.api.nvim_set_option_value("fillchars", "fold:" .. config.fillchar, { win = win })
    local foldtext = config.custom_foldtext and "v:lua.require'candela.lightbox'.custom_foldtext()"
        or "v:lua.require'candela.lightbox'.generate_foldtext()"
    vim.api.nvim_set_option_value("foldtext", foldtext, { win = win })

    M.update_folds()
end

--- Refresh lightbox buffer to match current base buffer.
function M.refresh()
    local base = require("candela.highlighter").base_buf
    if not base then
        return
    end
    M.buf = base
    if is_open() then
        vim.api.nvim_win_close(M.win, true)
        M.display(false)
    end
end

--- Toggle lightbox window open/closed.
function M.toggle()
    M.init()
    local base = require("candela.highlighter").base_buf
    if not base then
        base = vim.api.nvim_get_current_buf()
        require("candela.highlighter").base_buf = base
    end

    if is_open() and M.win == vim.api.nvim_get_current_win() then
        vim.api.nvim_win_close(M.win, true)
        M.win = nil
    elseif is_open() then
        M.buf = base
        M.display(true)
    else
        M.buf = base
        M.display(false)
    end
end

return M
