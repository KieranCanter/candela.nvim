-- Module for defining a single pattern

---@class CandelaPattern
---@field regex string
---@field color string
---@field highlight boolean
---@field lightbox boolean
---@field count number
---@field edit_regex fun(self, new_regex: string)
---@field convert_color_string fun(self)
---@field change_color fun(self, new_color: string)
---@field toggle_highlight fun(self)
---@field toggle_lightbox fun(self)

local M = {}

---@param regex string
---@param color string
---@param highlight boolean
---@param lightbox boolean
---@param count number
---@return CandelaPattern
function M.new(regex, color, highlight, lightbox, count)
    local instance = {
        regex = regex,
        color = color,
        highlight = highlight,
        lightbox = lightbox,
        count = count,
    }

    setmetatable(instance, { __index = M })
    return instance
end

---@param self CandelaPattern
---@param new_regex string
function M:edit_regex(new_regex)
    self.regex = new_regex
end

-- NOTE: Plan to add more color support in the future for other color spaces like RGB, LCH, OKLCH, HSL, HSV
-- Maybe through a user config where user can set a specific color space or leave it to "variable" in which they have to
-- define what kind of color space they're using e.g. rgb(255, 255, 255) or oklch(100, 150, 360)
---@return string|nil
function M:convert_color_string(color)
    local SWATCHES = require("candela.config").options.palette.swatches
    local color_string = string.match(color, "^%s*[%s%w]+%s*$")

    local swatch = SWATCHES[vim.o.background][color_string] or SWATCHES[vim.o.background][string.upper(color_string)]
    if swatch ~= nil then
        print(string.upper(swatch))
    end

    -- 6-digit hex code
    local r, g, b = string.match(color, "^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
    if r and g and b then
        return string.upper(string.format("#%s%s%s", r, g, b))
    end

    -- 3-digit hex code
    r, g, b = string.match(color, "^%s*#?(%x)(%x)(%x)%s*$")
    if r and g and b then
        return string.upper(string.format("#%s%s%s%s%s%s", r, r, g, g, b, b))
    end

    return nil
end

---@param self CandelaPattern
---@param new_color string
function M:change_color(new_color)
    if string.match(new_color, "^#%x%x%x%x%x%x$") ~= nil then
        self.color = new_color
    end

    local converted = self.convert_color_string(new_color)
    if converted ~= nil then
        self.color = converted
    else
        vim.notify(string.format('[Candela] "%s" is not of a valid color format', new_color), vim.log.levels.ERROR)
    end
end

---@param self CandelaPattern
function M:toggle_highlight()
    self.highlight = not self.highlight
end

---@param self CandelaPattern
function M:toggle_lightbox()
    self.lightbox = not self.lightbox
end

return M
