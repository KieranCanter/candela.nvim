-- Module for defining the list of patterns

local CandelaPattern = require("candela.pattern")

---@class CandelaPatternList: CandelaPattern[]

local CandelaPatternList = {}
CandelaPatternList.patterns = {}

CandelaPatternList.palette = {
    dark = {
        "#003f5c", -- deep blue
        "#2f4b7c", -- indigo
        "#665191", -- muted purple
        "#a05195", -- plum
        "#d45087", -- rose
        "#f95d6a", -- coral red
        "#ff7c43", -- burnt orange
        "#ffa600", -- gold
        "#b59f3b", -- olive yellow
        "#5f7e0e", -- moss green
        "#2f9e44", -- forest green
        "#228c99", -- teal
        "#1c7ed6", -- azure
        "#4263eb", -- strong blue
        "#5c5f66", -- soft gray
        "#7c4dff", -- electric purple,
    },
    light = {
        "#3c8fcf", -- muted blue
        "#61afef", -- sky blue
        "#88c0d0", -- nord light blue
        "#81a1c1", -- nord steel
        "#56b6c2", -- teal
        "#98c379", -- green
        "#c3e88d", -- pastel green
        "#e5c07b", -- soft yellow
        "#fab387", -- peach
        "#f78c6c", -- orange
        "#e06c75", -- red
        "#ff6ac1", -- pink
        "#c678dd", -- purple
        "#bb9af7", -- violet
        "#7dcfff", -- light aqua
        "#9aedfe", -- icy cyan,
    },
}
local next_color_index = 1

---@return CandelaPattern
function CandelaPatternList.get_pattern(index)
    return CandelaPatternList.patterns[index]
end

---@return table<string>
function CandelaPatternList.get_palette()
    local mode = vim.o.background
    return CandelaPatternList.palette[mode] or CandelaPatternList.palette.dark
end

---@return string
function CandelaPatternList.get_next_color()
    local palette = CandelaPatternList.get_palette()
    local next_color = palette[next_color_index]
    next_color_index = (next_color_index % #palette) + 1
    return next_color
end

---@param regex string
---@return CandelaPattern|nil
function CandelaPatternList.add(regex)
    if regex == "" then
        vim.notify("Candela: Regex cannot be empty", vim.log.levels.ERROR)
        return
    end
    if require("candela.ui").base_buf == "" then
        vim.notify("Candela: No valid base buffer", vim.log.levels.ERROR)
        return
    end

    local color = CandelaPatternList.get_next_color()
    local highlight = true
    local lightbox = true
    local count = 0

    local new_pattern = CandelaPattern.new(regex, color, highlight, lightbox, count)
    for _, pattern in ipairs(CandelaPatternList.patterns) do
        if pattern.regex == new_pattern.regex then
            vim.notify(string.format("Regex /%s/ already exists.", pattern.regex), vim.log.levels.ERROR)
            return
        end
    end
    table.insert(CandelaPatternList.patterns, new_pattern)

    return new_pattern
end

---@param index number: index of pattern to edit
---@param new_regex string: new regex to change pattern to
---@return CandelaPattern|nil
function CandelaPatternList.edit(index, new_regex)
    local pattern = CandelaPatternList.patterns[index]
    if pattern.regex == new_regex then
        return
    end
    for _, pat in ipairs(CandelaPatternList.patterns) do
        if pat.regex == new_regex then
            vim.notify(string.format("Regex /%s/ already exists.", pat.regex), vim.log.levels.ERROR)
            return
        end
    end

    pattern:edit_regex(new_regex)
    return pattern
end

---@param index number: index of pattern to remove
---@return boolean
function CandelaPatternList.remove(index)
    if index < 1 or index > #CandelaPatternList.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
        return false
    end

    local regex = CandelaPatternList.patterns[index].regex
    local choice =
        vim.fn.confirm(string.format("Do you want to remove pattern %d: /%s/?", index, regex), "&Yes\n&No", 2)
    if choice == 1 then
        table.remove(CandelaPatternList.patterns, index)
        vim.notify(string.format("Candela: removed pattern %d: /%s/", index, regex), vim.log.levels.INFO)
    else
        vim.notify("Candela: remove canceled", vim.log.levels.INFO)
        return false
    end

    return true
end

---@param index number: index of pattern to change color of
---@return CandelaPattern|nil
function CandelaPatternList.change_color(index, new_color)
    local pattern = CandelaPatternList.patterns[index]
    if index < 1 or index > #CandelaPatternList.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
        return
    end
    pattern:change_color(new_color)
    return pattern
end

---@param index number: index of pattern to toggle highlight on
---@return boolean
function CandelaPatternList.toggle_highlight(index)
    local pattern = CandelaPatternList.patterns[index]
    if index < 1 or index > #CandelaPatternList.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_highlight()
    return pattern.highlight
end

---@param index number: index of pattern to toggle lightbox on
---@return boolean
function CandelaPatternList.toggle_lightbox(index)
    local pattern = CandelaPatternList.patterns[index]
    if index < 1 or index > #CandelaPatternList.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_lightbox()
    return pattern.lightbox
end

function CandelaPatternList.clear()
    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: cannot clear an empty patterns list", vim.log.levels.INFO)
        return
    end

    local choice = vim.fn.confirm("Do you want to clear all patterns?", "&Yes\n&No", 2)
    if choice == 1 then
        CandelaPatternList.patterns = {}
        vim.notify("Candela: cleared all patterns", vim.log.levels.INFO)
    else
        vim.notify("Candela: clear canceled", vim.log.levels.INFO)
        return
    end
end

return CandelaPatternList
