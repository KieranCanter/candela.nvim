-- Module for defining the list of patterns

local CandelaPattern = require("candela.pattern")

---@class CandelaPatternList: CandelaPattern[]

local CandelaPatternList = {}
CandelaPatternList.patterns = {}

---@return CandelaPatternList
function CandelaPatternList.get()
    return CandelaPatternList.patterns
end

---@return CandelaPattern
function CandelaPatternList.get_pattern(index)
    return CandelaPatternList.patterns[index]
end

---@param regex string
---@param color? string --|generate_color()
---@param highlight? boolean = true
---@param lightbox? boolean = true
function CandelaPatternList.add(regex, color, highlight, lightbox)
    if regex == nil then
        vim.notify("Regex cannot be empty", vim.log.levels.ERROR)
        return
    end

    color = color or "#FFFFFF" -- TODO: implement function to generate color from pool of colors
    if highlight == nil then
        highlight = true
    end
    if lightbox == nil then
        lightbox = true
    end

    local new_pattern = CandelaPattern.new(regex, color, highlight, lightbox)
    for _, pattern in ipairs(CandelaPatternList.patterns) do
        if pattern.regex == new_pattern.regex then
            vim.notify(string.format("Regex /%s/ already exists.", pattern.regex), vim.log.levels.ERROR)
            return
        end
    end
    table.insert(CandelaPatternList.patterns, new_pattern)
end

---@param old_pattern_index number: index of pattern to edit
---@param new_regex string: new regex to change pattern to
function CandelaPatternList.edit(old_pattern_index, new_regex)
    CandelaPatternList.patterns[old_pattern_index].regex = new_regex
end

function CandelaPatternList.clear()
    CandelaPatternList.patterns = {}
end

return CandelaPatternList
