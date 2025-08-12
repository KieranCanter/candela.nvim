-- module to control th highlighting of matches

local CandelaEngine = require("candela.engine")
local CandelaConfig = require("candela.config")
local CandelaLightbox = {}

local M = {}

function M.setup()
    M.match_cache = {}
    CandelaLightbox = require("candela.lightbox")

    return M
end

---@param colors table
---@param ns integer
---@param hl_group string
local function register_highlight(colors, ns, hl_group)
    vim.api.nvim_set_hl_ns(ns)
    -- TODO: figure out foreground color situation

    colors.force = true

    vim.api.nvim_set_hl(0, hl_group, colors)
end

-- TODO: consolidate this with pattern_list hash_regex() and don't substring it?
---@param regex string
---@return string
local function hash_regex(regex)
    return vim.fn.sha256(regex):sub(1, 8)
end

---@param windows { color: CandelaWindow, highlight: CandelaWindow, lightbox: CandelaWindow }
---@param patterns CandelaPattern[]
function M.highlight_ui(windows, patterns)
    local ns = vim.api.nvim_create_namespace("CandelaUi")
    if #patterns == 0 then
        vim.api.nvim_buf_clear_namespace(windows.color.buf, ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(windows.highlight.buf, ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(windows.lightbox.buf, ns, 0, -1)
        return
    end

    for i, pattern in ipairs(patterns) do
        vim.api.nvim_buf_set_extmark(windows.color.buf, ns, i - 1, 0,
            { line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex) }
        )
        M.highlight_ui_toggle(windows.highlight, "highlight", i, pattern)
        M.highlight_ui_toggle(windows.lightbox, "lightbox", i, pattern)
    end
end

function M.highlight_ui_toggle(window, kind, row, pattern)
    local ns = vim.api.nvim_create_namespace("CandelaUi")

    if pattern[kind] == true then
        vim.api.nvim_buf_set_extmark(window.buf, ns, row - 1, 0,
            { line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex) }
        )
    end
end

---@param bufnr number
---@param id string
---@param pattern CandelaPattern
---@param cmd string
---@param args string[]
---@return number
function M.highlight_matches(bufnr, id, pattern, cmd, args)
    local ns = vim.api.nvim_create_namespace("CandelaNs_" .. hash_regex(pattern.regex))
    local hl_group = "CandelaHl_" .. hash_regex(pattern.regex)
    register_highlight({ bg = pattern.color }, ns, hl_group)

    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("[Candela] cannot search file with no file name", vim.log.levels.ERROR)
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
    M.match_cache[id] = {}
    local col = 0
    local count = 0
    for _, entry in ipairs(matches) do
        local row, line = entry.lineno, entry.line
        if row ~= nil and type(row) == "number" and line ~= nil and type(line) == "string" then
            local extmark_opts = {}
            if CandelaConfig.options.matching.hl_eol then
                extmark_opts = { line_hl_group = hl_group, priority = 100 }
            else
                extmark_opts = { end_col = string.len(line), hl_group = hl_group, strict = false, priority = 100 }
            end

            local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, col, extmark_opts)
            count = count + 1

            table.insert(M.match_cache[id], { extmark_id = extmark_id, row = row, end_col = string.len(line) })
            CandelaLightbox.add_to_cache(row, id)
        end
    end

    return count
end

---@return boolean
function M.toggle_match_highlights(bufnr, id, regex, toggle)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(regex)]
    if ns == nil then
        vim.notify(
            string.format("Candela: namespace does not exist: CandelaNs_%s", hash_regex(regex)),
            vim.log.levels.ERROR
        )
        return false
    end

    local hl_group = ""
    if toggle then
        hl_group = "CandelaHl_" .. hash_regex(regex)
    else
        hl_group = "Normal"
    end

    for _, match in ipairs(M.match_cache[id]) do
        local extmark_opts = {}
        if CandelaConfig.options.matching.hl_eol then
            extmark_opts = { id = match.extmark_id, line_hl_group = hl_group, priority = 100 }
        else
            local line = vim.api.nvim_buf_get_lines(bufnr, match.row - 1, match.row, false)[1]
            extmark_opts = {
                id = match.extmark_id,
                end_col = string.len(line),
                hl_group = hl_group,
                strict = false,
                priority = 100,
            }
        end

        vim.api.nvim_buf_set_extmark(bufnr, ns, match.row - 1, 0, extmark_opts)
    end

    return true
end

---@return boolean
function M.remove_match_highlights(bufnr, id, regex)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(regex)]
    if ns == nil then
        vim.notify(
            string.format("Candela: namespace does not exist: CandelaNs_%s", hash_regex(regex)),
            vim.log.levels.ERROR
        )
        return false
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    CandelaLightbox.remove_from_cache(M.match_cache[id], id)
    M.match_cache[id] = nil
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
