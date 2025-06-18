-- Module for defining a single pattern

---@class CandelaPattern
---@field regex string
---@field color string
---@field highlight boolean
---@field lightbox boolean

local CandelaPattern = {}

---@param regex string:
---@param color string:
---@param highlight boolean:
---@param lightbox boolean:
---@return CandelaPattern
function CandelaPattern.new(regex, color, highlight, lightbox)
    local instance = {
        regex = regex,
        color = color,
        highlight = highlight,
        lightbox = lightbox,
    }

    return instance
end

---@param color string
---@return boolean
local function _is_valid_color(color)
    local valid_pattern = "#%x%x%x%x%x%x"
    if not string.match(color, valid_pattern) then
        -- TODO: notify error or something
        return false
    end
    return true
end


---@param new_color string
function CandelaPattern:change_color(new_color)
    if _is_valid_color(new_color) then
        self.color = new_color
    else
        -- TODO: notify error or something
    end
end

function CandelaPattern:toggle_highlight()
    self.highlight = not self.highlight
end

function CandelaPattern:toggle_lightbox()
    self.lightbox = not self.lightbox
end

return CandelaPattern
