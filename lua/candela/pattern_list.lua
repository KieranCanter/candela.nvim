-- Module for defining the list of patterns

---@class CandelaPatternList: CandelaPattern[]

local CandelaPatternList = {}

---@param regex string
function CandelaPatternList:add(regex)
    -- TODO: CandelaPattern:new() and add to list
end

---@param old_pattern_index number: index of pattern to edit
---@param new_regex string: new regex to change pattern to
function CandelaPatternList:edit(old_pattern_index, new_regex)
    -- TODO: get pattern in list and change regex to new_regex
end

return CandelaPatternList
