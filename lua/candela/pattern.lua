---@class CandelaPattern
---@field regex string
---@field color string
---@field highlight boolean
---@field lightbox boolean
---@field count integer
local M = {}
M.__index = M

---@param regex string
---@param color string
---@param highlight boolean
---@param lightbox boolean
---@param count integer
---@return CandelaPattern
function M.new(regex, color, highlight, lightbox, count)
    return setmetatable({
        regex = regex,
        color = color,
        highlight = highlight,
        lightbox = lightbox,
        count = count,
    }, M)
end

---@param new_regex string
function M:edit_regex(new_regex)
    self.regex = new_regex
end

--- Convert a color string (swatch name, 3-digit hex, or 6-digit hex) to uppercase #RRGGBB.
---@param color string
---@return string|nil normalized hex color, nil if invalid
function M.convert_color_string(color)
    local swatches = require("candela.config").options.palette.swatches
    local name = color:match("^%s*([%w]+)%s*$")
    if name then
        local bg = swatches[vim.o.background] or swatches.dark
        local swatch = bg[name] or bg[name:upper()]
        if swatch then
            return swatch:upper()
        end
    end

    -- 6-digit hex
    local r, g, b = color:match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
    if r then
        return string.format("#%s%s%s", r, g, b):upper()
    end

    -- 3-digit hex
    r, g, b = color:match("^%s*#?(%x)(%x)(%x)%s*$")
    if r then
        return string.format("#%s%s%s%s%s%s", r, r, g, g, b, b):upper()
    end

    return nil
end

---@param new_color string raw input (hex or swatch name)
function M:change_color(new_color)
    local converted = M.convert_color_string(new_color)
    if converted then
        self.color = converted
    else
        vim.notify(string.format('[Candela] "%s" is not a valid color format', new_color), vim.log.levels.ERROR)
    end
end

function M:toggle_highlight()
    self.highlight = not self.highlight
end

function M:toggle_lightbox()
    self.lightbox = not self.lightbox
end

--- Completion function for color input.
--- Returns palette colors and swatch names for the current background.
---@param arglead string
---@return string[]
function M.complete_colors(arglead)
    local opts = require("candela.config").options.palette
    local bg = vim.o.background or "dark"
    local items = {}

    -- Swatch names
    local swatches = opts.swatches[bg] or opts.swatches.dark or {}
    for name, _ in pairs(swatches) do
        table.insert(items, name)
    end

    -- Palette hex colors
    local colors = opts.colors[bg] or opts.colors.dark or {}
    for _, hex in ipairs(colors) do
        table.insert(items, hex)
    end

    if arglead == "" then
        return items
    end
    return vim.tbl_filter(function(item)
        return item:lower():find(arglead:lower(), 1, true) ~= nil
    end, items)
end

return M
