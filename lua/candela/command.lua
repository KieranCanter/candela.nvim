-- Module for defining commands

---@class CandelaCommands
---@field regex string
---@field color string
---@field highlight boolean
---@field lightbox boolean


local CandelaPattern = {}
CandelaPattern.__index = CandelaPattern

function CandelaPattern:new()
    local pattern = setmetatable({
        regex = nil,
        color = nil,
        highlight = true,
        lightbox = true,
    }, self)

    return pattern
end

return CandelaPattern
