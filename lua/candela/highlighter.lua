---@class CandelaMatchEntry
---@field extmark_id integer
---@field row integer 1-indexed line number
---@field end_col integer byte length of matched line

local M = {}
M.match_cache = {} ---@type table<string, CandelaMatchEntry[]>
M.base_buf = nil ---@type integer|nil

---@param regex string
---@return integer namespace id
local function get_ns(regex)
    return vim.api.nvim_create_namespace("CandelaNs_" .. require("candela.patterns").hash(regex))
end

---@param regex string
---@return string highlight group name
local function get_hl_group(regex)
    return "CandelaHl_" .. require("candela.patterns").hash(regex):sub(1, 8)
end

--- Run engine on a single pattern, apply highlights to base buffer.
---@param regex string
---@return integer count of matches, -1 on error
function M.highlight(regex)
    local patterns = require("candela.patterns")
    local p = patterns.get(regex)
    if not p then
        return -1
    end
    if not M.base_buf then
        vim.notify("[Candela] no base buffer set, run :Candela refresh or open a file first", vim.log.levels.WARN)
        return -1
    end

    local ns = get_ns(regex)
    local hl = get_hl_group(regex)
    vim.api.nvim_set_hl(0, hl, { bg = p.color, force = true })

    local filepath = vim.api.nvim_buf_get_name(M.base_buf)
    if filepath == "" then
        vim.notify("[Candela] cannot search file with no name", vim.log.levels.ERROR)
        return -1
    end

    local cfg = require("candela.config").options
    local command = { cfg.engine.command }
    vim.list_extend(command, cfg.engine.args)
    table.insert(command, regex)
    table.insert(command, filepath)

    local matches = require("candela.engine").get_matches(command)
    M.match_cache[regex] = {}
    local count = 0

    for _, entry in ipairs(matches) do
        if entry.lineno and entry.line then
            local opts = cfg.matching.hl_eol and { line_hl_group = hl, priority = 100 }
                or { end_col = #entry.line, hl_group = hl, strict = false, priority = 100 }

            local eid = vim.api.nvim_buf_set_extmark(M.base_buf, ns, entry.lineno - 1, 0, opts)
            count = count + 1
            table.insert(M.match_cache[regex], { extmark_id = eid, row = entry.lineno, end_col = #entry.line })
            require("candela.lightbox").add_to_cache(entry.lineno, regex)
        end
    end

    if not p.highlight then
        M.toggle_highlights(regex, false)
    end

    p.count = count
    if vim.g.candela_debug then
        vim.notify(string.format("[Candela] highlighted /%s/: %d matches", regex, count), vim.log.levels.DEBUG)
    end
    return count
end

--- Remove all highlights for a pattern from the base buffer.
---@param regex string
function M.remove(regex)
    if vim.g.candela_debug then
        vim.notify(string.format("[Candela] removing highlights for /%s/", regex), vim.log.levels.DEBUG)
    end
    local ns = get_ns(regex)
    if M.base_buf and vim.api.nvim_buf_is_valid(M.base_buf) then
        vim.api.nvim_buf_clear_namespace(M.base_buf, ns, 0, -1)
    end
    if M.match_cache[regex] then
        require("candela.lightbox").remove_from_cache(M.match_cache[regex], regex)
        M.match_cache[regex] = nil
    end
end

--- Remove all highlights for all patterns.
function M.remove_all()
    for regex, _ in pairs(M.match_cache) do
        M.remove(regex)
    end
end

--- Toggle highlight visibility for a pattern's matches.
---@param regex string
---@param toggle boolean true to show highlights, false to hide
function M.toggle_highlights(regex, toggle)
    local cache = M.match_cache[regex]
    if not cache or not M.base_buf then
        return
    end

    local ns = get_ns(regex)
    local hl = toggle and get_hl_group(regex) or "Normal"
    local hl_eol = require("candela.config").options.matching.hl_eol

    for _, match in ipairs(cache) do
        local opts = hl_eol and { id = match.extmark_id, line_hl_group = hl, priority = 100 }
            or {
                id = match.extmark_id,
                end_col = match.end_col,
                hl_group = hl,
                strict = false,
                priority = 100,
            }
        vim.api.nvim_buf_set_extmark(M.base_buf, ns, match.row - 1, 0, opts)
    end
end

--- Update the highlight group color for a pattern.
---@param regex string
function M.update_color(regex)
    local p = require("candela.patterns").get(regex)
    if not p then
        return
    end
    vim.api.nvim_set_hl(0, get_hl_group(regex), { bg = p.color, force = true })
end

--- Re-run engine on all patterns for current base buffer.
function M.refresh()
    if vim.g.candela_debug then
        vim.notify("[Candela] refreshing all highlights", vim.log.levels.DEBUG)
    end
    M.remove_all()
    for regex, _ in pairs(require("candela.patterns").patterns) do
        M.highlight(regex)
    end
end

--- Build lines from pattern data and push to UI.
--- M.patterns is the source of truth. Buffer is just a view.
--- Preserves existing buffer order, appends new patterns at the end.
function M.refresh_ui()
    local ui = require("candela.ui")
    local patterns = require("candela.patterns")

    -- Start with current buffer order, skip duplicates and deleted patterns
    local lines = {}
    local seen = {}
    for _, regex in ipairs(ui.get_lines()) do
        if not seen[regex] and patterns.get(regex) then
            table.insert(lines, regex)
            seen[regex] = true
        end
    end

    -- Append any patterns not already in the buffer
    for regex, _ in pairs(patterns.patterns) do
        if not seen[regex] then
            table.insert(lines, regex)
        end
    end

    ui.render(lines)
end

return M
