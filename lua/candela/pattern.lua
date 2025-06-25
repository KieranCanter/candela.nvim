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

---@param pattern CandelaPattern
---@param regex string
function CandelaPattern.edit_regex(pattern, regex)
    pattern.regex = regex
end

---@param color string
---@return boolean
local function _is_valid_color(color)
    local valid_pattern = "#%x%x%x%x%x%x"
    if not string.match(color, valid_pattern) then
        return false
    end
    return true
end


---@param pattern CandelaPattern
---@param new_color string
function CandelaPattern.change_color(pattern, new_color)
    if _is_valid_color(new_color) then
        pattern.color = new_color
    else
        vim.notify(string.format(
            "Candela: \"%s\" is not a valid hex code", new_color),
            vim.log.levels.ERROR
        )
    end
end

---@param pattern CandelaPattern
function CandelaPattern.toggle_highlight(pattern)
    pattern.highlight = not pattern.highlight
end

---@param pattern CandelaPattern
function CandelaPattern.toggle_lightbox(pattern)
    pattern.lightbox = not pattern.lightbox
end

return CandelaPattern
