-- Module for defining a single pattern

---@class CandelaPattern
---@field regex string
---@field color string
---@field highlight boolean
---@field lightbox boolean
---@field count number
---@field edit_regex fun(self, new_regex: string)
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

---@param color string
---@return boolean
local function _is_valid_color(color)
    local valid_pattern = "#%x%x%x%x%x%x"
    if not string.match(color, valid_pattern) or string.len(color) ~= 7 then
        return false
    end
    return true
end


---@param self CandelaPattern
---@param new_color string
function M:change_color(new_color)
    if _is_valid_color(new_color) then
        self.color = new_color
    else
        vim.notify(string.format(
            "Candela: \"%s\" is not a valid hex code", new_color),
            vim.log.levels.ERROR
        )
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
