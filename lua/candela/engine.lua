-- Regex engine to find matches

local CandelaEngine = {}

---@param cmd string[]: rg command to feed the engine
---@return table[]: list of maps
function CandelaEngine.ripgrep_lines(cmd)
    -- TODO: testing ripgrep
    local output = vim.fn.systemlist(cmd)
    local matches = {}

    for _, line in ipairs(output) do
        local lineno = tonumber(line:match("^(%d+):"))
        local linestr = line:match(":(.*)")
        table.insert(matches, { lineno = lineno, line = linestr })
    end

    return matches
end

return CandelaEngine
