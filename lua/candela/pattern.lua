-- Module for defining a pattern object for Candela to work with

---@class CandelaPattern
---@field color string
---@field regex string
---@field highlight boolean
---@field lightbox boolean

local CandelaPattern = {}
CandelaPattern.__index = CandelaPattern

---@param col string
---@param reg string
---@param hl boolean
---@param lb boolean
---@return CandelaPattern
function CandelaPattern:new(col, reg, hl, lb)
    local pattern = setmetatable({}, CandelaPattern)
    pattern.color = col
    pattern.regex = reg
    pattern.highlight = hl
    pattern.lightbox = lb

    return pattern
end

return CandelaPattern
