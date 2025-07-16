-- Regex engine to find matches

local CandelaEngine = {}

---@class CandelaMatch
---@field lineno integer
---@field line string

---@param cmd string[]: command to feed the engine
---@return string[]: list of matched lines
function CandelaEngine.run_search(cmd)
    local matches = vim.fn.systemlist(cmd)
    return matches
end

---@param cmd string[]: command to feed the engine
---@return CandelaMatch[]: array of maps
function CandelaEngine.get_matches(cmd)
    local output = CandelaEngine.run_search(cmd)

    ---@type CandelaMatch[]
    local matches = {}

    for _, line in ipairs(output) do
        local lineno = tonumber(line:match("^(%d+):"))
        local linestr = line:match(":(.*)")
        table.insert(matches, { lineno = lineno, line = linestr })
    end

    return matches
end


return CandelaEngine
