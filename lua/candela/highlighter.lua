-- module to control the highlighting of matches

local CandelaEngine = require("candela.engine")

local M = {}

-- TODO: create default color palette

---@param colors table
---@param ns integer
---@param hl_group string
local function register_highlight(colors, ns, hl_group)
    vim.api.nvim_set_hl_ns(ns)
    -- TODO: figure out foreground color situation

    colors.force = true

    vim.api.nvim_set_hl(0, hl_group, colors)
end

---@param regex string
---@return string
local function hash_regex(regex)
    return vim.fn.sha256(regex):sub(1, 8)
end

function M.highlight_ui(windows, patterns)
    local ns = vim.api.nvim_create_namespace("CandelaUi")
    if #patterns == 0 then
        vim.api.nvim_buf_clear_namespace(windows.color.buf, ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(windows.highlight.buf, ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(windows.lightbox.buf, ns, 0, -1)
        return
    end

    local color_start = 0 -- start at beginning of color
    local color_end = 7 -- end index of hex code #123456
    local toggle_start = 1 -- start at middle of length 5 window
    local toggle_end = 5 -- end at middle of length 5 window

    for i, pattern in ipairs(patterns) do
        vim.api.nvim_buf_set_extmark(windows.color.buf, ns, i-1, 0, {
            end_col = color_end,
            line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex),
            priority = 100,
        })
        if pattern.highlight == true then
            vim.api.nvim_buf_set_extmark(windows.highlight.buf, ns, i-1, 0, {
                line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex),
                priority = 100,
            })
        end
        if pattern.lightbox == true then
            vim.api.nvim_buf_set_extmark(windows.lightbox.buf, ns, i-1, 0, {
                line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex),
                priority = 100,
            })
        end
    end
end

---@param bufnr number
---@param pattern CandelaPattern
---@return number
function M.highlight_matches(bufnr, pattern, cmd, args)
    local ns = vim.api.nvim_create_namespace("CandelaNs_" .. hash_regex(pattern.regex))
    local hl_group = "CandelaHl_" .. hash_regex(pattern.regex)
    register_highlight({ bg = pattern.color }, ns, hl_group)

    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("Candela: cannot search file with no file name", vim.log.levels.ERROR)
        return -1
    end

    -- construct shell command from regex search engine
    local command = { cmd }
    for _, arg in ipairs(args) do
        table.insert(command, arg)
    end
    table.insert(command, pattern.regex)
    table.insert(command, filepath)

    local matches = CandelaEngine.get_matches(command)
    local col = 0
    local count = 0
    for _, entry in ipairs(matches) do
        local row, line = entry.lineno, entry.line
        if row ~= nil and type(row) == "number" and line ~= nil and type(line) == "string" then
            vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, col, {
                end_col = string.len(line),
                hl_group = hl_group,
                hl_eol = true,
                priority = 100,
            })
            count = count + 1
        end
    end

    return count
end

---@return boolean
function M.remove_match_highlights(bufnr, regex)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(regex)]
    if ns == nil then
        vim.notify(
            string.format("Candela: namespace does not exist: CandelaNs_%s", hash_regex(regex)),
            vim.log.levels.ERROR
        )
        return false
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    return true
end

---@return boolean
function M.change_highlight_color(regex, new_color)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(regex)]
    if ns == nil then
        vim.notify(
            string.format("Candela: namespace does not exist: CandelaNs_%s", hash_regex(regex)),
            vim.log.levels.ERROR
        )
        return false
    end

    local hl_group = "CandelaHl_" .. hash_regex(regex)
    register_highlight({ bg = new_color }, ns, hl_group)
    return true
end

return M
