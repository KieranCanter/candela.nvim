-- Module for defining the list of patterns

local CandelaPattern = require("candela.pattern")

local M = {}
M.patterns = {}
M.order = {}

---@param palette table
local function shuffle(palette)
    local result = { unpack(palette) }
    for i = #result, 2, -1 do
        local j = math.random(i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

---@param mode "constant"|"random"
---@param default string
local function make_cycler(mode, default)
    local index = 1
    local palette = M.get_palette()
    if mode == "constant" then
        return function()
            local next_color = palette[index]
            index = (index % #palette) + 1
            return next_color
        end
    elseif mode == "random" then
        local shuffled = {}
        return function()
            if index > #shuffled then
                shuffled = shuffle(palette)
                index = 1
            end
            local next_color = shuffled[index]
            index = index + 1
            return next_color
        end
    else
        vim.notify(
            string.format(
                '[Candela] option "%s" not supported for palette.cycle, proceeding with default "%s"',
                mode,
                default
            ),
            vim.log.levels.WARN
        )
        make_cycler(default, default)
    end
end

-- TODO: move to a colors module?
function M.setup(opts)
    local defaults = require("candela.config").defaults

    -- Set palette colors
    if opts.palette.use == "replace" then
        M.palette = opts.palette.colors
    elseif opts.palette.use == "prepend" then
        M.palette = opts.palette.colors
        for _, color in ipairs(defaults.palette.colors.dark) do
            table.insert(M.palette.dark, color)
        end
        for _, color in ipairs(defaults.palette.colors.light) do
            table.insert(M.palette.light, color)
        end
    elseif opts.palette.use == "append" then
        M.palette = defaults.palette.colors
        for _, color in ipairs(opts.palette.colors.dark) do
            table.insert(M.palette.dark, color)
        end
        for _, color in ipairs(opts.palette.colors.light) do
            table.insert(M.palette.light, color)
        end
    else
        vim.notify(
            string.format(
                '[Candela] option "%s" not supported for palette.use, proceeding with default "%s"',
                opts.palette.use,
                defaults.palette.use
            ),
            vim.log.levels.WARN
        )
        M.palette = opts.palette.colors
    end

    -- Set type of cycler
    M.next_color = make_cycler(opts.palette.cycle, defaults.palette.cycle)
end

---@param index integer
---@return integer|nil, CandelaPattern|nil
function M.get_id_and_pattern_by_index(index)
    local id = M.order[index]
    if id == nil then
        vim.notify(string.format("[Candela] didn't find pattern at index %d", index), vim.log.levels.ERROR)
        return nil, nil
    end
    return id, M.patterns[id]
end

---@param regex string
---@return integer|nil, CandelaPattern|nil
function M.get_id_and_pattern_by_regex(regex)
    for id, pattern in pairs(M.patterns) do
        if pattern.regex == regex then
            return id, pattern
        end
    end
    vim.notify(string.format("[Candela] didn't find pattern with regex /%s/", regex), vim.log.levels.ERROR)
    return nil, nil
end

---@return table<string>
function M.get_palette()
    local mode = vim.o.background
    return M.palette[mode] or M.palette.dark
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
function M.add_pattern(regex, color, highlight, lightbox)
    local ui = require("candela.ui")
    if regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return
    end
    if ui.base_buf == nil or vim.api.nvim_buf_get_name(ui.base_buf) == "" then
        ui.base_buf = vim.api.nvim_get_current_buf()
    end

    local new_id = hash_regex(regex)
    if M.patterns[new_id] ~= nil then
        vim.notify(string.format("[Candela] regex /%s/ already exists.", regex), vim.log.levels.ERROR)
        return
    end

    -- Set new pattern fields
    color = color ~= nil and color or M.next_color()
    highlight = highlight ~= nil and highlight or true
    lightbox = lightbox ~= nil and lightbox or true
    local cmd = require("candela.config").options.engine.command --[[@as string]]
    local args = require("candela.config").options.engine.args
    local count = require("candela.highlighter").highlight_matches(ui.base_buf, new_id, regex, color, cmd, args)
    if count == -1 then
        return
    end

    local new_pattern = CandelaPattern.new(regex, color, highlight, lightbox, count)
    M.patterns[new_id] = new_pattern
    table.insert(M.order, new_id)

    new_pattern.count = count
    ui.update_ui_lines()
    ui.resize_height()

    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end
end

---@param index_or_regex integer|string: index or regex of pattern to edit
---@param new_regex string: new regex to change pattern to
function M.edit_pattern(index_or_regex, new_regex)
    if new_regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return
    end

    local old_id = nil
    local pattern = nil
    local index = nil
    if type(index_or_regex) == "number" then
        old_id, pattern = M.get_id_and_pattern_by_index(index_or_regex)
        index = index_or_regex
    elseif type(index_or_regex) == "string" then
        old_id, pattern = M.get_id_and_pattern_by_regex(index_or_regex)
        for i, id in ipairs(M.order) do
            if old_id == id then
                index = i
            end
        end
    end
    if old_id == nil or pattern == nil then
        return
    end
    if index == nil then
        vim.notify(
            string.format("[Candela] couldn't find index for regex /%s/", index_or_regex),
            vim.log.levels.ERROR
        )
        return
    end

    if pattern.regex == new_regex then -- user didn't change regex when editing, do nothing
        return
    end

    local new_id = hash_regex(new_regex)
    if M.patterns[new_id] ~= nil then
        vim.notify(string.format("[Candela] regex /%s/ already exists.", new_regex), vim.log.levels.ERROR)
        return
    end

    local ui = require("candela.ui")
    if not require("candela.highlighter").remove_match_highlights(ui.base_buf, old_id, pattern.regex) then
        return -- failed removing match highlights, return out
    end

    -- Replace id in order array and set old id key to nil + set new id key to edited pattern in patterns table
    M.order[index] = new_id
    pattern:edit_regex(new_regex)
    M.patterns[old_id] = nil
    M.patterns[new_id] = pattern

    local cmd = require("candela.config").options.engine.command --[[@as string]]
    local args = require("candela.config").options.engine.args
    local count =
        require("candela.highlighter").highlight_matches(ui.base_buf, new_id, pattern.regex, pattern.color, cmd, args)
    if count == -1 then
        return -- failed highlighting matches, return out
    end

    pattern.count = count
    ui.update_ui_lines()

    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end
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

    require("candela.ui").update_ui_lines()

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

    require("candela.ui").update_ui_lines()

    return true
end

---@param index_or_regex integer|string: index or regex of pattern to change color of
function M.change_pattern_color(index_or_regex, new_color)
    if new_color == "" then
        vim.notify("[Candela] color cannot be empty", vim.log.levels.ERROR)
        return
    end

    local id = nil
    local pattern = nil
    local index = nil
    if type(index_or_regex) == "number" then
        id, pattern = M.get_id_and_pattern_by_index(index_or_regex)
        index = index_or_regex
    elseif type(index_or_regex) == "string" then
        id, pattern = M.get_id_and_pattern_by_regex(index_or_regex)
        for i, curr_id in ipairs(M.order) do
            if curr_id == id then
                index = i
            end
        end
    end
    if id == nil or pattern == nil then
        return
    end
    if index == nil then
        vim.notify(
            string.format("[Candela] couldn't find index for regex /%s/", index_or_regex),
            vim.log.levels.ERROR
        )
        return
    end

    if pattern.color == new_color then -- user didn't change color when editing, do nothing
        return
    end

    if not require("candela.highlighter").change_highlight_color(pattern.regex, new_color) then
        return -- failed changing highlight color, return out
    end

    pattern:change_color(new_color)
    require("candela.ui").update_ui_lines()

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
