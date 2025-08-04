-- module to control the highlighting of matches

local CandelaEngine = require("candela.engine")
local CandelaConfig = require("candela.config")

local M = {}

function M.setup()
    M.match_cache = {}

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

function M.highlight_ui(windows, patterns)
    local ns = vim.api.nvim_create_namespace("CandelaUi")
    if #patterns == 0 then
        vim.api.nvim_buf_clear_namespace(windows.color.buf, ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(windows.highlight.buf, ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(windows.lightbox.buf, ns, 0, -1)
        return
    end

    local color_end = 7 -- end index of hex code #123456

    for i, pattern in ipairs(patterns) do
        vim.api.nvim_buf_set_extmark(windows.color.buf, ns, i - 1, 0, {
            end_col = color_end,
            line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex),
        })
        if pattern.highlight == true then
            vim.api.nvim_buf_set_extmark(windows.highlight.buf, ns, i - 1, 0, {
                line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex),
            })
        end
        if pattern.lightbox == true then
            vim.api.nvim_buf_set_extmark(windows.lightbox.buf, ns, i - 1, 0, {
                line_hl_group = "CandelaHl_" .. hash_regex(pattern.regex),
            })
        end
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
    M.match_cache[regex] = nil
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

---@param buf integer
function M.higlight_cache(buf)
    local patterns = require("candela.pattern_list").patterns
    for _, pattern in ipairs(patterns) do
        local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(pattern.regex)]
        local hl_group = "CandelaHl_" .. hash_regex(pattern.regex)
        if ns == nil then
            vim.notify(
                string.format("Candela: namespace does not exist: CandelaNs_%s", hash_regex(pattern.regex)),
                vim.log.levels.ERROR
            )
            return
        end

        for _, lineno in ipairs(M.match_cache[pattern.regex]) do
            vim.api.nvim_buf_set_extmark(buf, ns, lineno - 1, 0, {
                end_col = string.len(vim.api.nvim_buf_get_lines(buf, lineno - 1, -1, false)[1]),
                hl_group = hl_group,
                priority = 100,
            })
        end
    end
end

---@return integer[]
function M.get_match_ranges()
    local ranges = {}

    for regex, lines in pairs(M.match_cache) do
        local start, prev = lines[1], lines[1]
        ranges[regex] = {}
        for i = 2, #lines do
            local curr = lines[i]
            if curr ~= prev + 1 then
                table.insert(ranges[regex], { start, prev })
                start = curr
            end
            prev = curr
        end

        table.insert(ranges[regex], { start, prev })
    end

    return ranges
end

---@return table[lineno, ns, hl_group]
function M.get_flattened_match_cache()
    local flattened = {}
    local seen = {}

    for regex, lines in pairs(M.match_cache) do
        local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. hash_regex(regex)]
        local hl_group = "CandelaHl_" .. hash_regex(regex)
        for _, lineno in ipairs(lines) do
            if not seen[lineno] then
                table.insert(flattened, { lineno = lineno, ns = ns, hl_group = hl_group })
                seen[lineno] = true
            end
        end
    end

    table.sort(flattened, function(a, b)
        return a.lineno < b.lineno
    end)

    return flattened
end

return M
