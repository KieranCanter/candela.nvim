---@alias CandelaLocateKind "single"|"all"

local M = {}

local candela_ignorecase = false
local candela_smartcase = false

--- Update case sensitivity from vim options.
function M.set_candela_case()
    local ic = vim.api.nvim_get_option_value("ignorecase", { scope = "global" })
    local sc = vim.api.nvim_get_option_value("smartcase", { scope = "global" })
    candela_ignorecase = ic
    candela_smartcase = ic and sc
end

--- Initialize case settings from config. Idempotent.
function M.init()
    local case = require("candela.config").options.matching.case
    if case == "system" then
        M.set_candela_case()
    else
        candela_ignorecase = case == "ignore" or case == "smart"
        candela_smartcase = case == "smart"
    end
end

---@param regex string
---@return string vim case flag
local function get_match_case(regex)
    if candela_smartcase then
        return regex:match("[A-Z]") and "\\C" or "\\c"
    elseif candela_ignorecase then
        return "\\c"
    else
        return "\\C"
    end
end

---@return integer bufnr
local function get_base_buf()
    local hl = require("candela.highlighter")
    if not hl.base_buf then
        hl.base_buf = vim.api.nvim_get_current_buf()
    end
    return hl.base_buf
end

---@param regexes string[] empty = use all patterns
---@return string[]
local function collect_regexes(regexes)
    if #regexes > 0 then
        return regexes
    end
    local all = {}
    for regex, _ in pairs(require("candela.patterns").patterns) do
        table.insert(all, regex)
    end
    return all
end

--- Set vim search register and jump to first match.
---@param regexes string[] empty = use all patterns
---@return boolean success
function M.vimmatch(regexes)
    M.init()
    regexes = collect_regexes(regexes)
    if #regexes == 0 then
        vim.notify("[Candela] no patterns", vim.log.levels.WARN)
        return false
    end

    local parts = {}
    for _, r in ipairs(regexes) do
        table.insert(parts, "(" .. r .. ")")
    end
    local search = table.concat(parts, "|")
    local case = get_match_case(search)

    require("candela.ui").close()
    vim.fn.setreg("/", "\\v" .. case .. search)
    local ok = pcall(vim.api.nvim_exec2, "normal! n", {})
    if not ok then
        vim.notify(string.format("[Candela] no matches for /%s/", search), vim.log.levels.WARN)
        return false
    end
    return true
end

--- Run engine search and populate location list.
---@param regexes string[] empty = use all patterns
---@return boolean success
function M.loclist(regexes)
    M.init()
    regexes = collect_regexes(regexes)
    if #regexes == 0 then
        vim.notify("[Candela] no patterns", vim.log.levels.WARN)
        return false
    end

    local bufnr = get_base_buf()
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("[Candela] cannot search file with no name", vim.log.levels.ERROR)
        return false
    end

    local parts = {}
    for _, r in ipairs(regexes) do
        table.insert(parts, "(" .. r .. ")")
    end
    local search = table.concat(parts, "|")

    local cfg = require("candela.config").options
    local command = { cfg.engine.command }
    vim.list_extend(command, cfg.engine.args)
    table.insert(command, search)
    table.insert(command, filepath)

    local matches = require("candela.engine").get_matches(command)
    if #matches == 0 then
        vim.notify(string.format("[Candela] no matches for /%s/", search), vim.log.levels.WARN)
        return false
    end

    local kind = #regexes == 1 and "single" or "all"
    local loclist = {}
    for _, e in ipairs(matches) do
        table.insert(loclist, { bufnr = bufnr, lnum = e.lineno, text = e.line })
    end
    vim.fn.setloclist(0, {}, " ", {
        context = { name = "Candela", type = kind },
        items = loclist,
        title = "[Candela] " .. kind:sub(1, 1):upper() .. kind:sub(2) .. " Pattern(s)",
    })
    return true
end

return M
