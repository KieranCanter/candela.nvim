--- Pattern storage. Flat dictionary keyed by regex.
--- Order is owned by the UI buffer, not this module.

local M = {}

---@type table<string, CandelaPattern>
M.patterns = {}

---@type table<string, boolean>
M.selected = {}

---@type fun(): string
M.next_color = nil
M.palette = nil

---@param t string[]
---@return string[]
local function shuffle(t)
    local r = { unpack(t) }
    for i = #r, 2, -1 do
        local j = math.random(i)
        r[i], r[j] = r[j], r[i]
    end
    return r
end

---@param mode "constant"|"random"
---@param default "constant"|"random"
---@return fun(): string
local function make_cycler(mode, default)
    local idx = 1
    local pal = M.get_palette()
    if mode == "constant" then
        return function()
            local c = pal[idx]
            idx = (idx % #pal) + 1
            return c
        end
    elseif mode == "random" then
        local s = {}
        return function()
            if idx > #s then
                s = shuffle(pal)
                idx = 1
            end
            local c = s[idx]
            idx = idx + 1
            return c
        end
    else
        vim.notify(
            string.format('[Candela] palette.cycle "%s" not supported, using "%s"', mode, default),
            vim.log.levels.WARN
        )
        return make_cycler(default, default)
    end
end

--- Initialize palette and color cycler from config. Idempotent.
function M.init()
    if M.next_color then
        return
    end
    local opts = require("candela.config").options
    local defaults = require("candela.config").defaults

    if opts.palette.use == "prepend" then
        M.palette = vim.deepcopy(opts.palette.colors)
        for _, c in ipairs(defaults.palette.colors.dark) do
            table.insert(M.palette.dark, c)
        end
        for _, c in ipairs(defaults.palette.colors.light) do
            table.insert(M.palette.light, c)
        end
    elseif opts.palette.use == "append" then
        M.palette = vim.deepcopy(defaults.palette.colors)
        for _, c in ipairs(opts.palette.colors.dark) do
            table.insert(M.palette.dark, c)
        end
        for _, c in ipairs(opts.palette.colors.light) do
            table.insert(M.palette.light, c)
        end
    else
        M.palette = opts.palette.colors
    end

    M.next_color = make_cycler(opts.palette.cycle, defaults.palette.cycle)
end

---@return string[] palette colors for current background
function M.get_palette()
    if not M.palette then
        M.init()
    end
    return M.palette[vim.o.background] or M.palette.dark
end

---@param regex string
---@return string sha256 hash
function M.hash(regex)
    return vim.fn.sha256(regex)
end

---@param regex string
---@return CandelaPattern|nil
function M.get(regex)
    return M.patterns[regex]
end

---@return integer
function M.count()
    return vim.tbl_count(M.patterns)
end

--- Resolve a UI buffer line index or regex string to a regex key.
---@param index_or_regex string|integer
---@return string|nil regex key in patterns, or nil if not found
function M.resolve(index_or_regex)
    if type(index_or_regex) == "string" and M.patterns[index_or_regex] then
        return index_or_regex
    end
    local idx = tonumber(index_or_regex)
    if not idx then
        return nil
    end
    local ui = require("candela.ui")
    if not ui.buf or not vim.api.nvim_buf_is_valid(ui.buf) then
        return nil
    end
    local lines = vim.api.nvim_buf_get_lines(ui.buf, 0, -1, false)
    local line = lines[idx]
    if line and M.patterns[line] then
        return line
    end
    return nil
end

---@param regex string
---@param color? string hex color or swatch name
---@param highlight? boolean defaults to true
---@param lightbox? boolean defaults to true
---@return string|nil regex key on success, nil on failure
function M.add(regex, color, highlight, lightbox)
    M.init()
    if regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return nil
    end
    if M.patterns[regex] then
        vim.notify(string.format("[Candela] regex /%s/ already exists", regex), vim.log.levels.ERROR)
        return nil
    end

    color = color or M.next_color()
    highlight = (highlight == nil) and true or highlight
    lightbox = (lightbox == nil) and true or lightbox

    M.patterns[regex] = require("candela.pattern").new(regex, color, highlight, lightbox, 0)
    if vim.g.candela_debug then
        vim.notify(string.format("[Candela] pattern added: /%s/ color=%s", regex, color), vim.log.levels.DEBUG)
    end
    return regex
end

---@param old_regex string
---@param new_regex string
---@return string|nil new regex key on success, nil on failure
function M.edit(old_regex, new_regex)
    if new_regex == "" then
        vim.notify("[Candela] regex cannot be empty", vim.log.levels.ERROR)
        return nil
    end
    local p = M.patterns[old_regex]
    if not p then
        return nil
    end
    if old_regex == new_regex then
        return old_regex
    end
    if M.patterns[new_regex] then
        vim.notify(string.format("[Candela] regex /%s/ already exists", new_regex), vim.log.levels.ERROR)
        return nil
    end

    M.patterns[old_regex] = nil
    p:edit_regex(new_regex)
    M.patterns[new_regex] = p
    if vim.g.candela_debug then
        vim.notify(string.format("[Candela] pattern edited: /%s/ -> /%s/", old_regex, new_regex), vim.log.levels.DEBUG)
    end
    return new_regex
end

---@param regex string
---@return boolean success
function M.delete(regex)
    if not M.patterns[regex] then
        return false
    end
    M.patterns[regex] = nil
    M.selected[regex] = nil
    if vim.g.candela_debug then
        vim.notify(string.format("[Candela] pattern deleted: /%s/", regex), vim.log.levels.DEBUG)
    end
    return true
end

---@return boolean success
function M.clear()
    if vim.tbl_isempty(M.patterns) then
        return false
    end
    M.patterns = {}
    M.selected = {}
    return true
end

---@param regex string
---@param new_color string hex color or swatch name
---@return CandelaPattern|nil pattern on success
function M.change_color(regex, new_color)
    local p = M.patterns[regex]
    if not p then
        return nil
    end
    local color_str = require("candela.pattern").convert_color_string(new_color)
    if not color_str then
        return nil
    end
    if string.upper(p.color) == string.upper(color_str) then
        return p
    end
    p:change_color(color_str)
    return p
end

---@param regex string
---@return boolean|nil new highlight state, nil if pattern not found
function M.toggle_highlight(regex)
    local p = M.patterns[regex]
    if not p then
        return nil
    end
    p:toggle_highlight()
    return p.highlight
end

---@param regex string
---@return boolean|nil new lightbox state, nil if pattern not found
function M.toggle_lightbox(regex)
    local p = M.patterns[regex]
    if not p then
        return nil
    end
    p:toggle_lightbox()
    return p.lightbox
end

--- Regenerate all pattern colors from the palette cycler.
function M.regen_colors()
    M.init()
    for regex, _ in pairs(M.patterns) do
        M.change_color(regex, M.next_color())
    end
end

---@param regex string
function M.add_to_selected(regex)
    M.selected[regex] = true
end

---@param regex string
function M.remove_from_selected(regex)
    M.selected[regex] = nil
end

function M.add_all_to_selected()
    for _, pattern in pairs(M.patterns) do
        M.selected[pattern.regex] = true
    end
end

function M.clear_selected()
    M.selected = {}
end

function M.get_selected()
    return M.selected
end

return M
