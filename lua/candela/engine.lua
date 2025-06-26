-- regex engine to find matches

local CandelaEngine = {}

---@param pattern string
---@param filepath string
---@return number[]: list of matching line numbers
function CandelaEngine.ripgrep_lines(pattern, filepath)
  local cmd = { "rg", "--line-number", "--no-heading", pattern, filepath }
  local output = vim.fn.systemlist(cmd)
  local lines = {}

  for _, line in ipairs(output) do
    local lineno = tonumber(line:match("^(%d+):"))
    if lineno then
      table.insert(lines, lineno - 1)
    end
  end

  return lines
end

return CandelaEngine
