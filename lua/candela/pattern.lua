-- Module for defining a single pattern

---@class CandelaPattern
---@field color string
---@field regex string
---@field highlight boolean
---@field lightbox boolean

local CandelaPattern = {}

---@param col string: color
---@param reg string: regex
---@param hl boolean: enable highlight
---@param lb boolean: enable lightbox
---@return CandelaPattern
function CandelaPattern:new(col, reg, hl, lb)
    self.color = col
    self.regex = reg
    self.highlight = hl
    self.lightbox = lb

    return self
end

---@param new_color string
function CandelaPattern:change_color(new_color)
    if _is_valid_color(new_color) then
        self.color = new_color
    else
        -- TODO: notify error or something
    end
end

---@param color string
---@return boolean
function _is_valid_color(color)
    -- TODO: check format of color string
    return true
end

function CandelaPattern:toggle_highlight()
    self.highlight = not self.highlight
end

function CandelaPattern:toggle_lightbox()
    self.lightbox = not self.lightbox
end

return CandelaPattern
