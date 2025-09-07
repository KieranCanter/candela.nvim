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

    vim.api.nvim_create_autocmd("VimEnter", {
        group = require("candela.init").CANDELA_AUGROUP,
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

---@param regexes string[]: empty table represents all patterns
---@return boolean: tells caller whether find was successful or not
function M.match(regexes)
    local bufnr = require("candela.ui").base_buf
    if not bufnr then
        bufnr = vim.api.nvim_get_current_buf()
        require("candela.ui").base_buf = bufnr
    end

    local search_str = ""
    local first = next(regexes)
    local second = next(regexes, next(regexes))

    if first ~= nil and second == nil then
        search_str = regexes[first]
    else
        if first == nil then
            for _, pattern in pairs(require("candela.pattern_list").patterns) do
                table.insert(regexes, pattern.regex)
            end
        end
        local parts = {}
        for _, regex in pairs(regexes) do
            table.insert(parts, "(" .. regex .. ")")
        end
        search_str = table.concat(parts, "|")
    end

    local case = get_match_case(search_str)
    vim.fn.setreg("/", "\\v" .. case .. search_str)
    local ok = pcall(vim.api.nvim_exec2, "normal! n", {})
    if not ok then
        vim.notify(string.format("[Candela] no matches found for /%s/", search_str), vim.log.levels.WARN)
        return false
    end

    return true
end

---@param matches table[]: keys: lineno, line
---@param kind "single"|"selected"|"all"
local function update_loclist(matches, kind)
    local loclist = {}
    for _, entry in ipairs(matches) do
        table.insert(loclist, {
            bufnr = require("candela.ui").base_buf,
            lnum = entry.lineno,
            text = entry.line,
        })
    end

    local context = { name = "Candela", type = kind }
    local title
    if kind == "single" then
        title = "[Candela] Single Pattern"
    elseif kind == "selected" then
        title = "[Candela] Selected Patterns"
    elseif kind == "all" then
        title = "[Candela] All Patterns"
    else
        vim.notify(
            "[Candela] to update location list, kind must be 'single', 'selected', or 'all', proceeding with 'single'",
            vim.log.levels.WARN
        )
        title = "[Candela] Single Pattern"
    end
    local what = { context = context, items = loclist, title = title }
    vim.fn.setloclist(0, {}, " ", what)
end

---@param regexes table<string>: empty table represents all patterns
---@return boolean: tells caller whether find was successful or not
function M.find(regexes)
    local bufnr = require("candela.ui").base_buf
    if not bufnr then
        bufnr = vim.api.nvim_get_current_buf()
        require("candela.ui").base_buf = bufnr
    end

    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("[Candela] cannot search file with no file name", vim.log.levels.ERROR)
        return false
    end

    local search_str = ""
    local search_kind = "selected"
    local first = next(regexes)
    local second = next(regexes, next(regexes))

    if first ~= nil and second == nil then
        search_str = regexes[first]
        search_kind = "single"
    else
        if first == nil then
            for _, pattern in pairs(require("candela.pattern_list").patterns) do
                table.insert(regexes, pattern.regex)
            end
            search_kind = "all"
        else
            search_kind = "selected"
        end
        local parts = {}
        for _, regex in ipairs(regexes) do
            table.insert(parts, "(" .. regex .. ")")
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
    if next(matches) == nil then
        vim.notify(string.format("[Candela] no matches found for /%s/", search_str), vim.log.levels.WARN)
        return false -- nothing to find, just exit
    end

    update_loclist(matches, search_kind)
    return true
end

return M
