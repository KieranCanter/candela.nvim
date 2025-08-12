local M = {}

-- TODO: use config case sensitivity for matching
---@param regex string
function M.match(regex)
    vim.fn.setreg("/", "\\v\\C" .. regex)
    vim.cmd("normal! n")
end

-- TODO: use config case sensitivity for matching
--@param patterns CandelaPattern[]
function M.match_all(patterns)
    local parts = {}
    for _, pattern in pairs(patterns) do
        table.insert(parts, "(" .. pattern.regex .. ")")
    end
    local search_str = table.concat(parts, "|")
    vim.fn.setreg("/", "\\v\\C" .. search_str)
    vim.cmd("normal! n")
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

    local context = {name = "Candela", type = kind}
    local title
    if kind == "single" then
        title = "Candela: Single Pattern"
    elseif kind == "all" then
        title = "Candela: All Patterns"
    else
        vim.notify(
            "[Candela]: to update location list, kind must be 'single' or 'all', proceeding with 'single'",
            vim.log.levels.WARN)
        title = "Candela: Single Pattern"
    end
    local what = { context = context, items = loclist, title = title }
    vim.fn.setloclist(0, {}, ' ', what)
end

-- TODO: use config case sensitivity for matching
-------- can I use match_cache to get the matches instead of rerunning engine?
-------- either way, use user config command + args instead of hardcoded rg
---@param bufnr number
---@param regex string
---@param engine fun(cmd: string[]): table[]
function M.find(bufnr, regex, engine)
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("[Candela] cannot search file with no file name", vim.log.levels.ERROR)
        return 0
    end

    local rg_cmd = { "rg", "--line-number", "--color=never", regex, filepath }
    local matches = engine(rg_cmd)

    update_loclist(matches, "single")
end

-- TODO: use config case sensitivity for matching
-------- can I use match_cache to get the matches instead of rerunning engine?
-------- either way, use user config command + args instead of hardcoded rg
---@param bufnr number
---@param patterns CandelaPattern[]
---@param engine fun(cmd: string[]): table[]
function M.find_all(bufnr, patterns, engine)
    if #patterns < 1 then
        vim.notify("[Candela] cannot run find_all on pattern list of length 0", vim.log.levels.ERROR)
        return
    end

    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("[Candela] cannot search file with no file name", vim.log.levels.ERROR)
        return 0
    end

    local parts = {}
    for _, pattern in pairs(patterns) do
        table.insert(parts, "(" .. pattern.regex .. ")")
    end
    local search_str = table.concat(parts, "|")

    local rg_cmd = { "rg", "--line-number", "--color=never", search_str, filepath }
    local matches = engine(rg_cmd)

    update_loclist(matches, "all")
end

return M
