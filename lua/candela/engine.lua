---@class CandelaMatch
---@field lineno integer
---@field line string

local M = {}

---@param cmd string[]: command to feed the engine
---@return string[]: list of matched lines
function M.run_search(cmd)
    local matches = vim.fn.systemlist(cmd)
    return matches
end

---@param cmd string[]: command to feed the engine
---@return CandelaMatch[]: array of maps
function M.get_matches(cmd)
    local output = M.run_search(cmd)

    ---@type CandelaMatch[]
    local matches = {}

    for _, line in ipairs(output) do
        local lineno = tonumber(line:match("(%d+):"))
        local linestr = line:match("%d+:(.*)")
        table.insert(matches, { lineno = lineno, line = linestr })
    end

    return matches
end


return M
