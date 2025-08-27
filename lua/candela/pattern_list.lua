-- Module for defining the list of patterns

local CandelaPattern = require("candela.pattern")

local M = {}
M.patterns = {}
M.order = {}

local next_color_index = 1

function M.setup(opts)
    M.palette = opts.palette.colors
end

---@return CandelaPattern
function M.get_pattern(index)
    local id = M.order[index]
    return M.patterns[id]
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
---@return string
local function hash_regex(regex)
    return vim.fn.sha256(regex)
end

---@param regex string
---@param color? string
---@param highlight? boolean
---@param lightbox? boolean
---@return string?, CandelaPattern?
function M.add_pattern(regex, color, highlight, lightbox)
    if regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return
    end
    if require("candela.ui").base_buf == "" then
        vim.notify("[Candela] no valid base buffer", vim.log.levels.ERROR)
        return
    end

    color = color ~= nil and color or M.get_next_color()
    highlight = highlight ~= nil and highlight or true
    lightbox = lightbox ~= nil and lightbox or true
    local count = 0

    local new_pattern = CandelaPattern.new(regex, color, highlight, lightbox, count)
    local new_id = hash_regex(regex)
    if M.patterns[new_id] ~= nil then
        vim.notify(string.format("[Candela] regex /%s/ already exists.", regex), vim.log.levels.ERROR)
        return
    end

    M.patterns[new_id] = new_pattern
    table.insert(M.order, new_id)

    return new_id, new_pattern
end

---@param index number: index of pattern to edit
---@param new_regex string: new regex to change pattern to
---@return string?, CandelaPattern?
function M.edit_pattern(index, new_regex)
    if new_regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return
    end
    if require("candela.ui").base_buf == "" then
        vim.notify("[Candela] no valid base buffer", vim.log.levels.ERROR)
        return
    end

    local old_id = M.order[index]
    local pattern = M.patterns[old_id]
    if pattern.regex == new_regex then -- user didn't change regex when editing, do nothing
        return
    end

    local new_id = hash_regex(new_regex)
    if M.patterns[new_id] ~= nil then
        vim.notify(string.format("[Candela] regex /%s/ already exists.", new_regex), vim.log.levels.ERROR)
        return
    end

    -- Replace id in order array and set old id key to nil + set new id key to edited pattern in patterns table
    M.order[index] = new_id
    pattern:edit_regex(new_regex)
    M.patterns[old_id] = nil
    M.patterns[new_id] = pattern

    return new_id, pattern
end

---@param index number: index of pattern to delete
---@return boolean
function M.delete_pattern(index)
    if index < 1 or index > #M.order then
        vim.notify(string.format("[Candela] no pattern at index %d", index), vim.log.levels.ERROR)
        return false
    end

    local id = M.order[index]
    local regex = M.patterns[id].regex
    table.remove(M.order, index)
    M.patterns[id] = nil
    vim.notify(string.format("[Candela] deleted pattern %d: /%s/", index, regex), vim.log.levels.INFO)

    return true
end

---@return boolean
function M.clear_patterns()
    if #M.order == 0 then
        vim.notify("[Candela] cannot clear an empty patterns list", vim.log.levels.INFO)
        return false
    end

    M.order = {}
    M.patterns = {}
    vim.notify("[Candela] cleared all patterns", vim.log.levels.INFO)
    return true
end

---@param index number: index of pattern to change color of
---@return CandelaPattern?
function M.change_pattern_color(index, new_color)
    local id = M.order[index]
    local pattern = M.patterns[id]
    if index < 1 or index > #M.order then
        vim.notify(string.format("[Candela] no pattern at index %d", index), vim.log.levels.ERROR)
        return
    end
    pattern:change_color(new_color)

    return pattern
end

---@param index number: index of pattern to toggle highlight on
---@return boolean
function M.toggle_pattern_highlight(index)
    local id = M.order[index]
    local pattern = M.patterns[id]
    if index < 1 or index > #M.order then
        vim.notify(string.format("[Candela] no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_highlight()

    return pattern.highlight
end

---@param index number: index of pattern to toggle lightbox on
---@return boolean
function M.toggle_pattern_lightbox(index)
    local id = M.order[index]
    local pattern = M.patterns[id]
    if index < 1 or index > #M.order then
        vim.notify(string.format("[Candela] no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_lightbox()

    return pattern.lightbox
end

return M
