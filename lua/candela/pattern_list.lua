-- Module for defining the list of patterns

local CandelaPattern = require("candela.pattern")

---@class CandelaPatternList: CandelaPattern[]

local M = {}
M.patterns = {}

local next_color_index = 1
M.palette = {
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

function M.setup(opts)
    M.palette = opts.palette.colors
end

---@return CandelaPattern
function M.get_pattern(index)
    return M.patterns[index]
end

---@return table<string>
function M.get_palette()
    local mode = vim.o.background
    return M.palette[mode] or M.palette.dark
end

---@return string
function M.get_next_color()
    local palette = M.get_palette()
    local next_color = palette[next_color_index]
    next_color_index = (next_color_index % #palette) + 1
    return next_color
end

---@param regex string
---@return CandelaPattern|nil
function M.add_pattern(regex)
    if regex == "" then
        vim.notify("Candela: Regex cannot be empty", vim.log.levels.ERROR)
        return
    end
    if require("candela.ui").base_buf == "" then
        vim.notify("Candela: No valid base buffer", vim.log.levels.ERROR)
        return
    end

    local color = M.get_next_color()
    local highlight = true
    local lightbox = true
    local count = 0

    local new_pattern = CandelaPattern.new(regex, color, highlight, lightbox, count)
    for _, pattern in ipairs(M.patterns) do
        if pattern.regex == new_pattern.regex then
            vim.notify(string.format("Regex /%s/ already exists.", pattern.regex), vim.log.levels.ERROR)
            return
        end
    end
    table.insert(M.patterns, new_pattern)

    return new_pattern
end

---@param index number: index of pattern to edit
---@param new_regex string: new regex to change pattern to
---@return CandelaPattern|nil
function M.edit_pattern(index, new_regex)
    if new_regex == "" then
        vim.notify("Candela: Regex cannot be empty", vim.log.levels.ERROR)
        return
    end
    if require("candela.ui").base_buf == "" then
        vim.notify("Candela: No valid base buffer", vim.log.levels.ERROR)
        return
    end

    local pattern = M.patterns[index]
    if pattern.regex == new_regex then
        return
    end
    for _, pat in ipairs(M.patterns) do
        if pat.regex == new_regex then
            vim.notify(string.format("Regex /%s/ already exists.", pat.regex), vim.log.levels.ERROR)
            return
        end
    end

    pattern:edit_regex(new_regex)
    return pattern
end

---@param index number: index of pattern to delete
---@return boolean
function M.delete_pattern(index)
    if index < 1 or index > #M.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
        return false
    end

    local regex = M.patterns[index].regex
    table.remove(M.patterns, index)
    vim.notify(string.format("Candela: deleted pattern %d: /%s/", index, regex), vim.log.levels.INFO)
    return true
end

---@return boolean
function M.clear_patterns()
    if #M.patterns == 0 then
        vim.notify("Candela: cannot clear an empty patterns list", vim.log.levels.INFO)
        return false
    end

    M.patterns = {}
    vim.notify("Candela: cleared all patterns", vim.log.levels.INFO)
    return true
end

---@param index number: index of pattern to change color of
---@return CandelaPattern|nil
function M.change_pattern_color(index, new_color)
    local pattern = M.patterns[index]
    if index < 1 or index > #M.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
        return
    end
    pattern:change_color(new_color)
    return pattern
end

---@param index number: index of pattern to toggle highlight on
---@return boolean
function M.toggle_pattern_highlight(index)
    local pattern = M.patterns[index]
    if index < 1 or index > #M.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_highlight()
    return pattern.highlight
end

---@param index number: index of pattern to toggle lightbox on
---@return boolean
function M.toggle_pattern_lightbox(index)
    local pattern = M.patterns[index]
    if index < 1 or index > #M.patterns then
        vim.notify(string.format("Candela: no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_lightbox()
    return pattern.lightbox
end

return M
