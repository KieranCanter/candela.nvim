-- Module for defining user configuration

--[[
-- Config ideas:
-- * window sizing
-- * syntax highlighting
-- * fold vs remove unlightboxed lines
--]]

---@class CandelaConfig
---@field defaults table<string, any>
---@field options table<string, any>
local CandelaConfig = {}

CandelaConfig.defaults = {
    -- Use log syntax highlighting
    height = 7,
    syntax_highlighting = true,
}

CandelaConfig.options = {}

---@return CandelaConfig
function CandelaConfig.setup(opts)
    CandelaConfig.options = vim.tbl_deep_extend("force", vim.deepcopy(CandelaConfig.defaults), opts or {})
    return CandelaConfig.options
end

return CandelaConfig
