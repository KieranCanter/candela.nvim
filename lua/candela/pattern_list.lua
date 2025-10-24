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

-- NOTE: Plan to move to a colors module eventually once more color space support is added
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

    -- Return the functions designed to be part of public API via require("candela").patterns
    return {
        M.add,
        M.edit,
        M.delete,
        M.clear,
        M.change_color,
        M.toggle_highlight,
        M.toggle_lightbox,
    }
end

---@param index integer
---@return string|nil, CandelaPattern|nil
function M.get_id_and_pattern_by_index(index)
    local id = M.order[index]
    if id == nil then
        vim.notify(string.format("[Candela] didn't find pattern at index %d", index), vim.log.levels.ERROR)
        return nil, nil
    end
    return id, M.patterns[id]
end

---@param regex string
---@return string|nil, CandelaPattern|nil
function M.get_id_and_pattern_by_regex(regex)
    for id, pattern in pairs(M.patterns) do
        if pattern.regex == regex then
            return id, pattern
        end
    end
    vim.notify(string.format("[Candela] didn't find pattern with regex /%s/", regex), vim.log.levels.ERROR)
    return nil, nil
end

---@param index_or_regex integer|string
---@return string|nil, CandelaPattern|nil, integer|nil
local function get_id_pattern_index(index_or_regex)
    local id = nil
    local pattern = nil
    local index = nil
    if type(index_or_regex) == "number" then
        id, pattern = M.get_id_and_pattern_by_index(index_or_regex)
        index = index_or_regex
    elseif type(index_or_regex) == "string" then
        id, pattern = M.get_id_and_pattern_by_regex(index_or_regex)
        for i, id in ipairs(M.order) do
            if id == id then
                index = i
            end
        end
    end
    if id == nil or pattern == nil then
        return nil, nil, nil
    end
    if index == nil then
        vim.notify(string.format("[Candela] couldn't find index for regex /%s/", index), vim.log.levels.ERROR)
        return nil, nil, nil
    end

    return id, pattern, index
end

---@param index integer: index to search for
---@return string|nil
function M.get_regex_from_index(index)
    if index < 1 or index > #M.order then
        return nil
    else
        local id = M.order[index]
        return M.patterns[id].regex
    end
end

---@param index integer: index to search for
---@return string|nil
function M.get_color_from_index(index)
    if index < 1 or index > #M.order then
        return nil
    else
        local id = M.order[index]
        return M.patterns[id].color
    end
end

---@param regex string: regex to search for
---@return integer|nil
function M.get_index_from_regex(regex)
    local target_id = M.hash_regex(regex)
    for i, id in ipairs(M.order) do
        if target_id == id then
            return i
        end
    end
    return nil
end

---@return table<string>
function M.get_palette()
    local mode = vim.o.background
    return M.palette[mode] or M.palette.dark
end

---@param regex string
---@return string
function M.hash_regex(regex)
    return vim.fn.sha256(regex)
end

---@param regex string
---@param color? string
---@param highlight? boolean
---@param lightbox? boolean
function M.add(regex, color, highlight, lightbox)
    local ui = require("candela.ui")
    if regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return
    end
    if ui.base_buf == nil or vim.api.nvim_buf_get_name(ui.base_buf) == "" then
        ui.base_buf = vim.api.nvim_get_current_buf()
    end

    local new_id = M.hash_regex(regex)
    if M.patterns[new_id] ~= nil then
        vim.notify(string.format("[Candela] regex /%s/ already exists.", regex), vim.log.levels.ERROR)
        return
    end

    -- Set new pattern fields
    color = (color == nil) and M.next_color() or color --[[@as string]]
    highlight = (highlight == nil) and true or highlight --[[@as boolean]]
    lightbox = (lightbox == nil) and true or lightbox --[[@as boolean]]
    local cmd = require("candela.config").options.engine.command --[[@as string]]
    local args = require("candela.config").options.engine.args

    local new_pattern = require("candela.pattern").new(regex, color, highlight, lightbox, 0)
    local count = require("candela.highlighter").highlight_matches(ui.base_buf, new_id, new_pattern, cmd, args)
    if count == -1 then
        return
    end

    new_pattern.count = count
    M.patterns[new_id] = new_pattern
    table.insert(M.order, new_id)

    ui.update_ui_lines()
    ui.resize_height()

    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end
end

---@param index_or_regex integer|string: index or regex of pattern to edit
---@param new_regex string: new regex to change pattern to
function M.edit(index_or_regex, new_regex)
    if new_regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return
    end

    local old_id, pattern, index = get_id_pattern_index(index_or_regex)
    if old_id == nil or pattern == nil or index == nil then
        return
    end

    if pattern.regex == new_regex then -- user didn't change regex when editing, do nothing
        return
    end

    local new_id = M.hash_regex(new_regex)
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
    local count = require("candela.highlighter").highlight_matches(ui.base_buf, new_id, pattern, cmd, args)
    if count == -1 then
        return -- failed highlighting matches, return out
    end

    pattern.count = count
    ui.update_ui_lines()

    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end
end

---@param index_or_regex integer|string: index or regex of pattern to edit
---@return boolean
function M.delete(index_or_regex)
    local old_id, pattern, index = get_id_pattern_index(index_or_regex)
    if old_id == nil or pattern == nil or index == nil then
        return false
    end

    if index < 1 or index > #M.order then
        vim.notify(string.format("[Candela] no pattern at index %d", index), vim.log.levels.ERROR)
        return false
    end

    local ui = require("candela.ui")
    if not require("candela.highlighter").remove_match_highlights(ui.base_buf, old_id, pattern.regex) then
        return false -- failed removing match highlights, return out
    end

    table.remove(M.order, index)
    M.patterns[old_id] = nil

    vim.notify(string.format("[Candela] deleted pattern %d: /%s/", index_or_regex, pattern.regex), vim.log.levels.INFO)

    ui.update_ui_lines()
    ui.resize_height()
    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end

    return true
end

---@return boolean
function M.clear()
    if #M.order == 0 then
        vim.notify("[Candela] cannot clear an empty patterns list", vim.log.levels.INFO)
        return false
    end

    local ui = require("candela.ui")
    for id, pattern in pairs(M.patterns) do
        if not require("candela.highlighter").remove_match_highlights(ui.base_buf, id, pattern.regex) then
            return false -- failed removing match highlights, return out
        end
    end

    M.order = {}
    M.patterns = {}
    vim.notify("[Candela] cleared all patterns", vim.log.levels.INFO)

    ui.update_ui_lines()
    ui.resize_height()
    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end

    return true
end

---@param index_or_regex integer|string: index or regex of pattern to change color of
function M.change_color(index_or_regex, new_color)
    if new_color == "" then
        vim.notify("[Candela] color cannot be empty", vim.log.levels.ERROR)
        return
    end

    local old_id, pattern, index = get_id_pattern_index(index_or_regex)
    if old_id == nil or pattern == nil or index == nil then
        return
    end

    new_color = require("candela.pattern").convert_color_string(new_color)
    if new_color == nil then
        vim.notify(string.format('[Candela] "%s" is not of a valid color format', new_color), vim.log.levels.ERROR)
        return
    end
    if string.upper(pattern.color) == string.upper(new_color) then -- user didn't change color when editing, do nothing
        return
    end

    if not require("candela.highlighter").change_highlight_color(pattern.regex, new_color) then
        return -- failed changing highlight color, return out
    end

    pattern:change_color(new_color)
    require("candela.ui").update_ui_lines()
    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end

    return pattern
end

---@param index_or_regex integer|string: index or regex of pattern to toggle highlight on
---@return boolean
function M.toggle_highlight(index_or_regex)
    local id, pattern, index = get_id_pattern_index(index_or_regex)
    if id == nil or pattern == nil or index == nil then
        return false
    end

    if index < 1 or index > #M.order then
        vim.notify(string.format("[Candela] no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_highlight()

    local ui = require("candela.ui")
    if not require("candela.highlighter").toggle_match_highlights(ui.base_buf, id, pattern.regex, pattern.highlight) then
        return false
    end

    ui.update_ui_lines()

    if require("candela.lightbox").window:is_open() then
        require("candela.lightbox").update_folds()
    end
    return pattern.highlight
end

---@param index_or_regex integer|string: index or regex of pattern to toggle lightbox on
---@return boolean
function M.toggle_lightbox(index_or_regex)
    local id, pattern, index = get_id_pattern_index(index_or_regex)
    if id == nil or pattern == nil or index == nil then
        return false
    end

    if index < 1 or index > #M.order then
        vim.notify(string.format("[Candela] no pattern at index %d", index), vim.log.levels.ERROR)
    end
    pattern:toggle_lightbox()

    local lightbox = require("candela.lightbox")
    local highlighter = require("candela.highlighter")
    if pattern.lightbox then
        lightbox.add_many_to_cache(highlighter.match_cache[id], id)
    else
        lightbox.remove_from_cache(highlighter.match_cache[id], id)
    end
    lightbox.update_folds()

    require("candela.ui").update_ui_lines()

    return pattern.lightbox
end

return M
