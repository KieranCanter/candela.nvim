local M = {}

local case_opt = ""
local system_ignorecase = nil
local system_smartcase = nil
local candela_ignorecase = nil
local candela_smartcase = nil

function M.set_candela_case()
    system_ignorecase = vim.api.nvim_get_option_value("ignorecase", { scope = "global" })
    system_smartcase = vim.api.nvim_get_option_value("smartcase", { scope = "global" })

    if system_ignorecase then
        candela_ignorecase = true
    else
        candela_ignorecase = false
    end
    if system_smartcase and system_ignorecase then
        candela_smartcase = true
    else
        candela_smartcase = false
    end
end

function M.setup(opts)
    case_opt = opts.matching.case
    system_ignorecase = vim.api.nvim_get_option_value("ignorecase", { scope = "global" })
    system_smartcase = vim.api.nvim_get_option_value("smartcase", { scope = "global" })
    candela_ignorecase = case_opt == "ignore" or case_opt == "smart"
    candela_smartcase = case_opt == "smart"

    local candela_augroup = vim.api.nvim_create_augroup("Candela", { clear = false })
    vim.api.nvim_create_autocmd("VimEnter", {
        group = candela_augroup,
        desc = "Initialize case-sensitivity globals to user options",
        callback = function()
            if case_opt == "system" then
                M.set_candela_case()
            end
        end,
    })
end

---@param regex string
---@return boolean
local function contains_uppercase(regex)
    return regex:match("[A-Z]") ~= nil
end

---@param regex string
---@return string
local function get_match_case(regex)
    if candela_smartcase then
        if contains_uppercase(regex) then
            return "\\C"
        else
            return "\\c"
        end
    elseif candela_ignorecase then
        return "\\c"
    else
        return "\\C"
    end
end

---@param patterns table<integer, CandelaPattern>
---@param count integer
function M.match(patterns, count)
    local search_str = ""
    if count == 1 then
        local _, pattern = next(patterns)
        if pattern == nil then
            vim.notify("[Candela] finder.match() count is 1 but pattern is nil", vim.log.levels.ERROR)
            return
        end
        search_str = pattern.regex
    else
        if count == 0 then
            patterns = require("candela.pattern_list").patterns
        end
        local parts = {}
        for _, pattern in pairs(patterns) do
            table.insert(parts, "(" .. pattern.regex .. ")")
        end
        search_str = table.concat(parts, "|")
    end

    local case = get_match_case(search_str)
    vim.fn.setreg("/", "\\v" .. case .. search_str)
    local ok = pcall(vim.api.nvim_exec2, "normal! n", {})
    if not ok then
        vim.notify(string.format("[Candela] no matches found for /%s/", search_str), vim.log.levels.WARN)
    end
end

---@param matches table[]: keys: lineno, line
---@param kind string: "single"|"all"
local function update_loclist(matches, kind)
    local loclist = {}
    for _, entry in ipairs(matches) do
        loclist[#loclist + 1] = {
            bufnr = require("candela.ui").base_buf,
            lnum = entry.lineno,
            text = entry.line,
        }
    end

    local context = { name = "Candela", type = kind }
    local title
    if kind == "single" then
        title = "Candela: Single Pattern"
    elseif kind == "selected" then
        title = "Candela: Selected Patterns"
    elseif kind == "all" then
        title = "Candela: All Patterns"
    else
        vim.notify(
            "Candela: to update location list, kind must be 'single', 'selected', or 'all', proceeding with 'single'",
            vim.log.levels.WARN
        )
        title = "Candela: Single Pattern"
    end
    local what = { context = context, items = loclist, title = title }
    vim.fn.setloclist(0, {}, " ", what)
end

-- TODO: can I use match_cache to get the matches instead of rerunning engine?
---@param bufnr number
---@param patterns table<integer, CandelaPattern>
---@param count integer
---@return boolean: tells caller whether find was successful or not
function M.find(bufnr, patterns, count)
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("[Candela] cannot search file with no file name", vim.log.levels.ERROR)
        return false
    end

    local search_str = ""
    local search_kind = "selected"

    if count == 1 then
        local _, pattern = next(patterns)
        if pattern == nil then
            vim.notify("[Candela] finder.find() count is 1 but pattern is nil", vim.log.levels.ERROR)
            return false
        end
        search_str = pattern.regex
        search_kind = "single"
    else
        if count == 0 then
            patterns = require("candela.pattern_list").patterns
            search_kind = "all"
        else
            search_kind = "selected"
        end
        local parts = {}
        for _, pattern in pairs(patterns) do
            table.insert(parts, "(" .. pattern.regex .. ")")
        end
        search_str = table.concat(parts, "|")
    end

    local cmd = require("candela.config").options.engine.command
    local args = require("candela.config").options.engine.args
    local command = { cmd }
    for _, arg in ipairs(args) do
        table.insert(command, arg)
    end
    table.insert(command, search_str)
    table.insert(command, filepath)

    local matches = require("candela.engine").get_matches(command)

    update_loclist(matches, search_kind)
    return true
end

return M
