-- Regex engine to find matches

local CandelaEngine = {}

---@param regex string
---@param filepath string
---@return number[]: list of matching line numbers
function CandelaEngine.ripgrep_lines(regex, filepath)
  -- TODO: testing ripgrep
  local cmd = { "rg", "--line-number", "--color=never", regex, filepath }
  local output = vim.fn.systemlist(cmd)
  local matches = {}

  for _, line in ipairs(output) do
    local lineno = tonumber(line:match("^(%d+):"))
    local linestr = line:match(":(.*)")
    if lineno then
      table.insert(matches, { lineno, string.len(linestr) })
    end
  end

  return matches
end

return CandelaEngine
