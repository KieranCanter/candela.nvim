-- module to control the highlighting of matches

local CandelaEngine = require("candela.engine")

local M = {}

-- TODO: create default color palette

---@param color string
---@param ns integer
---@param hl_group string
local function register_highlight(color, ns, hl_group)
    vim.api.nvim_set_hl_ns(ns)
    -- TODO: figure out foreground color situation
    local fg = "#101010"
    if fg == nil then
        return
    end

    vim.api.nvim_set_hl(0, hl_group, {
        --fg = fg,
        bg = color,
        force = true,
    })
end

---@param regex string
---@return string
local function hash_regex(regex)
    return vim.fn.sha256(regex):sub(1, 8)
end

---@param bufnr number
---@param pattern CandelaPattern
---@return number
function M.highlight_matches(bufnr, pattern)
    local ns = vim.api.nvim_create_namespace("CandelaNs_" .. hash_regex(pattern.regex))
    local hl_group = "CandelaHl_" .. hash_regex(pattern.regex)
    M.register_highlight(pattern.color, ns, hl_group)

    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("Candela: cannot search file with no file name", vim.log.levels.ERROR)
        return -1
    end

    -- TODO: get command from config based on best default between rg, ag, and grep or user config
    local rg_cmd = { "rg", "--line-number", "--color=never", pattern.regex, filepath }
    local matches = CandelaEngine.get_matches(rg_cmd)
    local count = 0
    for _, entry in ipairs(matches) do
        local row, line = entry.lineno, entry.line
        vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, 0, {
            end_col = string.len(line),
            hl_group = hl_group,
            hl_eol = true,
            priority = 100,
        })
        count = count + 1
    end

    return count
end

---@return boolean
function M.remove_highlight(bufnr, regex)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(regex)]
    if ns == nil then
        vim.notify(string.format("Candela: namespace does not exist: CandelaNs_%s", hash_regex(regex)), vim.log.levels.ERROR)
        return false
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    return true
end

---@return boolean
function M.change_highlight_color(regex, new_color)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(regex)]
    if ns == nil then
        vim.notify(string.format("Candela: namespace does not exist: CandelaNs_%s", hash_regex(regex)), vim.log.levels.ERROR)
        return false
    end

    local hl_group = "CandelaHl_" .. hash_regex(regex)
    register_highlight(new_color, ns, hl_group)
    return true
end

return M
