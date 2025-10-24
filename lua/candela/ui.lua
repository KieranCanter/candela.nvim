local CandelaPatternList = require("candela.pattern_list")
local CandelaHighlighter = require("candela.highlighter")
local CandelaLightbox = require("candela.lightbox")

---@class CandelaUi
---@field windows table<string, CandelaWindow>
---@field base_buf number

local M = {}

local CANDELA_AUGROUP = require("candela.init").CANDELA_AUGROUP
local WIDTH_COEFF = 0
local MIN_HEIGHT, MAX_HEIGHT = 0, 0
local MARGIN = 0
local MIN_COUNT_WIDTH = 0
local TOGGLE_WIDTH = 0
local PROMPT_OFFSET = 0

local selected_patterns = {}

---@enum operations
local Operations = {
    ADD = 1,
    EDIT = 2,
    COPY = 3,
    CHANGE_COLOR = 4,
    IMPORT = 5,
    EXPORT = 6,
}

---@param dest table
---@param src table
local function extend_table(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

---@param num number
---@param max number
---@return number
local function clamp_max(num, max)
    if num > max then
        return max
    else
        return num
    end
end

local function set_size_and_loc()
    local color_width = M.windows.color.config.width or 7 -- 7 space hexcode -- NOTE: may need to change in the future with new color spaces
    local count_width = M.windows.count.config.width or MIN_COUNT_WIDTH
    local ops_width = TOGGLE_WIDTH -- width of highlight/lightbox toggles
    local curr_width = math.floor(vim.o.columns * WIDTH_COEFF)
    local max_width = vim.o.columns - MARGIN
    local width = clamp_max(curr_width, max_width)
    -- Fit regex to rest of window leftover, subtract 1 for each space inbetween windows
    local regex_width = width - color_width - count_width - (ops_width * 2) - 6

    local pattern_height = nil
    local curr_pattern_height = nil
    local max_pattern_height = vim.o.lines - MARGIN
    if #CandelaPatternList.order then
        curr_pattern_height = MIN_HEIGHT + 2 -- minimum height
    else
        curr_pattern_height = M.windows.patterns.config.height --[[@as integer]]
    end
    pattern_height = clamp_max(curr_pattern_height, max_pattern_height)
    local prompt_height = 1 -- 1 space height for prompt

    -- Account for 2 border spaces worth of padding to center window in center of base window
    local horz_center = math.floor((vim.o.columns - width - 2) / 2)
    local vert_center = math.floor((vim.o.lines - pattern_height - prompt_height) / 2)

    -- Patterns
    extend_table(M.windows.patterns.config, {
        width = width,
        height = pattern_height,
        col = horz_center,
        row = vert_center,
    })

    -- Color
    extend_table(M.windows.color.config, {
        width = color_width,
        height = M.windows.patterns.config.height - 2,
        col = 0,
        row = 0,
    })

    -- Count
    extend_table(M.windows.count.config, {
        width = count_width,
        height = M.windows.patterns.config.height - 2,
        col = color_width + 1,
        row = 0,
    })

    -- Regex
    extend_table(M.windows.regex.config, {
        width = regex_width,
        height = M.windows.patterns.config.height - 2,
        col = color_width + count_width + 2,
        row = 0,
    })

    -- Highlight
    extend_table(M.windows.highlight.config, {
        width = ops_width,
        height = M.windows.patterns.config.height - 2,
        col = color_width + count_width + regex_width + 3,
        row = 0,
    })

    -- Lightbox
    extend_table(M.windows.lightbox.config, {
        width = ops_width,
        height = M.windows.patterns.config.height - 2,
        col = color_width + count_width + regex_width + ops_width + 4,
        row = 0,
    })

    -- Prompt
    extend_table(M.windows.prompt.config, {
        width = width,
        height = prompt_height,
        col = -1,
        row = pattern_height + PROMPT_OFFSET,
    })

    -- Set window config dynamically if the window is open
    for _, window in pairs(M.windows) do
        if window:is_open() then
            vim.api.nvim_win_set_config(window.win, window.config)
        end
    end
end

---@param delete boolean?: if deleting a pattern, don't move cursor to bottom
function M.resize_height(delete)
    local num_pats = #CandelaPatternList.order
    local old_height = M.windows.patterns.config.height - 2 -- Num of shown entries
    local is_under_min_height = old_height == MIN_HEIGHT and num_pats <= MIN_HEIGHT
    local is_over_max_height = old_height == MAX_HEIGHT and num_pats >= MAX_HEIGHT

    if is_over_max_height then
        if not delete then
            for name, window in pairs(M.windows) do
                if name ~= "prompt" and name ~= "patterns" then
                    vim.api.nvim_win_set_cursor(window.win, { num_pats, 0 })
                end
            end
        end
        return
    end

    if is_under_min_height then
        return
    end

    -- Set patterns window height
    local new_height = num_pats ~= 0 and (num_pats + 2) or (MIN_HEIGHT + 2)
    local prompt_height = M.windows.prompt.config.height
    local new_vert_center = math.floor((vim.o.lines - new_height - prompt_height) / 2)
    M.windows.patterns.config.row = new_vert_center
    M.windows.patterns.config.height = new_height
    if vim.api.nvim_win_is_valid(M.windows.patterns.win) then
        vim.api.nvim_win_set_config(M.windows.patterns.win, M.windows.patterns.config)
    end

    -- Set inner window heights
    for name, win in pairs(M.windows) do
        if name ~= "prompt" and name ~= "patterns" then
            win.config.height = M.windows.patterns.config.height - 2
            if vim.api.nvim_win_is_valid(M.windows.patterns.win) then
                vim.api.nvim_win_set_config(win.win, win.config)
            end
        end
    end
end

---@param color_width integer?
---@param count_width integer?
local function resize_width(color_width, count_width)
    color_width = color_width or M.windows.color.config.width
    count_width = count_width or MIN_COUNT_WIDTH
    local ops_width = TOGGLE_WIDTH
    local curr_width = math.floor(vim.o.columns * WIDTH_COEFF)
    local max_width = vim.o.columns - MARGIN
    local width = clamp_max(curr_width, max_width)
    -- Fit regex to rest of window leftover, subtract 1 for each space inbetween windows
    local regex_width = width - color_width - count_width - (ops_width * 2) - 6

    -- Color
    M.windows.color.config.width = color_width
    -- Count
    M.windows.count.config.width = count_width
    M.windows.count.config.col = color_width + 1
    -- Regex
    M.windows.regex.config.width = regex_width
    M.windows.regex.config.col = color_width + count_width + 2

    -- Set window config dynamically if the window is open
    for _, window in pairs(M.windows) do
        if window:is_open() then
            vim.api.nvim_win_set_config(window.win, window.config)
        end
    end
end

---@param field string: Field name
---@param field_val string|boolean|number
---@return string: String to input into buffer lines
local function format_field(field, field_val)
    if field == "color" and type(field_val) == "string" then
        return field_val
    elseif field == "count" then
        local win_width = M.windows.count.config.width
        local line = tostring(field_val)
        local right_aligned = string.rep(" ", win_width - #line) .. line
        return right_aligned
    elseif field == "regex" then
        return string.format(" /%s/", field_val) or ""
    elseif field == "highlight" then
        return field_val and M.highlight_on or M.highlight_off
    elseif field == "lightbox" then
        return field_val and M.lightbox_on or M.lightbox_off
    else
        vim.notify(string.format("[Candela] %s is not a valid field", field), vim.log.levels.ERROR)
        return "no value"
    end
end

-- Update lines of the patterns buffers
function M.update_ui_lines()
    local all_lines = {
        color = {},
        count = {},
        regex = {},
        highlight = {},
        lightbox = {},
    }
    local longest_count = MIN_COUNT_WIDTH --[[@as integer]]

    local pattern_list = {}
    for i, id in ipairs(CandelaPatternList.order) do
        local pattern = CandelaPatternList.patterns[id]
        table.insert(pattern_list, pattern)
        for field, _ in pairs(all_lines) do
            table.insert(all_lines[field], format_field(field, pattern[field]))
            -- Get longest count width to resize if needed
            if field == "count" then
                longest_count = math.max(longest_count, tostring(all_lines[field][i]):len())
            end
        end
    end

    for field, lines in pairs(all_lines) do
        vim.api.nvim_set_option_value("modifiable", true, { buf = M.windows[field].buf })
        vim.api.nvim_buf_set_lines(M.windows[field].buf, 0, -1, false, lines)
        vim.api.nvim_set_option_value("modifiable", false, { buf = M.windows[field].buf })
    end

    if longest_count ~= M.windows.count.config.width then
        M.windows.count.config.width = longest_count
        resize_width(nil, longest_count)
    end

    CandelaHighlighter.highlight_ui(M.windows, pattern_list)
    M.unselect_all()
end

-- Update toggle in the UI
---@param kind "highlight"|"lightbox"
---@param row integer: row of UI to update
---@param pattern CandelaPattern: pattern to get value from
local function update_ui_toggle(kind, row, pattern)
    local toggled_line = format_field(kind, pattern[kind])

    vim.api.nvim_set_option_value("modifiable", true, { buf = M.windows[kind].buf })
    vim.api.nvim_buf_set_lines(M.windows[kind].buf, row - 1, row, false, { toggled_line })
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.windows[kind].buf })

    CandelaHighlighter.highlight_ui_toggle(M.windows[kind], kind, row, pattern)
end

function M.update_ui()
    local was_open = M.windows.patterns:is_open()
    if not was_open then
        M.show_patterns()
    end

    M.update_ui_lines()

    if not was_open then
        M.hide_patterns()
    end
end

local function refresh_to_curr_buf()
    for _, id in ipairs(CandelaPatternList.order) do
        local pattern = CandelaPatternList.patterns[id]
        if pattern.count ~= 0 then
            if not CandelaHighlighter.remove_match_highlights(M.base_buf, id, pattern.regex) then
                return
            end
        end

        local CandelaConfig = require("candela.config")
        local cmd = CandelaConfig.options.engine.command --[[@as string]]
        local args = CandelaConfig.options.engine.args
        local count = CandelaHighlighter.highlight_matches(M.curr_buf, id, pattern, cmd, args)
        if count == -1 then
            return
        end

        pattern.count = count
        M.update_ui_lines()
        M.resize_height()
    end
end

---@param icon string|nil: user config icon option
---@param header string: string to use as header
---@return string: formatted UI string
local function format_header(icon, header)
    local pre = ""
    if icon and vim.fn.strwidth(icon) == 2 then
        pre = icon
    elseif icon and vim.fn.strwidth(icon) == 1 then
        pre = icon .. " "
    end

    return pre .. header
end

---@param icon string|nil: user config icon toggle_on option
---@param type "highlight"|"lightbox"
---@return string: formatted toggle string
local function format_toggle(icon, type)
    if not icon then
        icon = "Y"
    end

    local width = 0
    if type == "highlight" then
        width = M.windows.highlight.config.width
    elseif type == "lightbox" then
        width = M.windows.lightbox.config.width
    else
        vim.notify(string.format('[Candela] toggle type "%s" not defined', type), vim.log.levels.ERROR)
    end

    local spaces = string.rep(" ", (width - vim.fn.strwidth(icon)) / 2)
    return spaces .. icon .. spaces
end

---@param opts table
function M.setup(opts)
    ---@param name string: name of option
    ---@return integer
    local function validate_config_num(name)
        local mins = {
            margin = 0,
            width = 0,
            min_height = 1,
            max_height = 1,
            min_count_width = 1,
            toggle_width = 1,
        }
        local maxs = {
            margin = math.huge,
            width = 1,
            min_height = math.huge,
            max_height = math.huge,
            min_count_width = math.huge,
            toggle_width = math.huge,
        }

        local CandelaConfig = require("candela.config")
        if opts.window[name] < mins[name] or opts.window[name] > maxs[name] then
            vim.notify(
                string.format(
                    "[Candela] option window.%s cannot be less than %s or greater than %s, got %s. "
                        .. "Proceeding with default of %s",
                    name,
                    mins[name],
                    maxs[name],
                    opts.window[name],
                    CandelaConfig.defaults.window[name]
                )
            )
            return CandelaConfig.defaults.window[name] --[[@as integer]]
        end

        return opts.window[name]
    end

    WIDTH_COEFF = validate_config_num("width")
    MIN_HEIGHT = validate_config_num("min_height")
    MAX_HEIGHT = validate_config_num("max_height")
    MARGIN = validate_config_num("margin")
    MIN_COUNT_WIDTH = validate_config_num("min_count_width")
    TOGGLE_WIDTH = validate_config_num("toggle_width")

    local defaults = require("candela.config").defaults
    if opts.window.prompt_offset == "overlap" then
        PROMPT_OFFSET = 0
    elseif opts.window.prompt_offset == "border" then
        PROMPT_OFFSET = 1
    else
        vim.notify(
            string.format(
                '"%s" is not a valid option value for `window.prompt_offset`, using "%s" as default.'
                    .. ' Valid values: "overlap", "border".',
                opts.window.prompt_offset,
                defaults.prompt_offset
            ),
            vim.log.levels.WARN
        )
        PROMPT_OFFSET = 0
    end

    local CandelaWindow = require("candela.window")

    local title = ""
    local icons = require("candela.config").options.icons

    title = " " .. format_header(icons.candela, "Candela") .. " " -- add spacing margin
    local patterns = CandelaWindow.new({
        relative = "editor",
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "rounded",
        zindex = 1,
    })

    title = format_header(icons.color, "Color")
    local color = CandelaWindow.new({
        relative = "win",
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "solid",
        zindex = 10,
    })

    local count = CandelaWindow.new({
        relative = "win",
        style = "minimal",
        focusable = false,
        title = "",
        border = "solid",
        zindex = 10,
    })

    title = format_header(icons.regex, "Regex")
    local regex = CandelaWindow.new({
        relative = "win",
        style = "minimal",
        title = title,
        title_pos = "left",
        border = "solid",
        zindex = 10,
    })

    title = format_header(icons.highlight.header, "HL")
    local highlight = CandelaWindow.new({
        relative = "win",
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "solid",
        zindex = 10,
    })

    title = format_header(icons.lightbox.header, "LB")
    local lightbox = CandelaWindow.new({
        relative = "win",
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "solid",
        zindex = 10,
    })
    local prompt = CandelaWindow.new({
        relative = "win",
        style = "minimal",
        title_pos = "left",
        border = "rounded",
        zindex = 15,
    })

    M.windows = {
        patterns = patterns,
        color = color,
        count = count,
        regex = regex,
        highlight = highlight,
        lightbox = lightbox,
        prompt = prompt,
    }

    set_size_and_loc()

    -- set highlight/lightbox toggling strings since they're constant
    M.highlight_on = format_toggle(icons.highlight.toggle_on, "highlight")
    M.highlight_off = format_toggle(icons.highlight.toggle_off, "highlight")
    M.lightbox_on = format_toggle(icons.lightbox.toggle_on, "lightbox")
    M.lightbox_off = format_toggle(icons.lightbox.toggle_off, "lightbox")

    for name, window in pairs(M.windows) do
        window:ensure_buffer()
        vim.api.nvim_set_option_value("swapfile", false, { buf = window.buf })
        vim.api.nvim_set_option_value("filetype", "candela", { buf = window.buf })
        if name ~= "prompt" then
            vim.api.nvim_set_option_value("modifiable", false, { buf = window.buf })
        end
    end

    require("candela.mappings").set_patterns_keymaps()

    vim.api.nvim_create_autocmd("VimResized", {
        group = CANDELA_AUGROUP,
        callback = function()
            set_size_and_loc()
        end,
    })

    vim.api.nvim_create_autocmd("BufHidden", {
        group = CANDELA_AUGROUP,
        buffer = M.windows.regex.buf,
        callback = function()
            M.hide_patterns()
        end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = CANDELA_AUGROUP,
        buffer = M.windows.regex.buf,
        callback = function()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            if col ~= 0 then
                local row = vim.api.nvim_win_get_cursor(0)[1]
                vim.api.nvim_win_set_cursor(0, { row, 0 })
            end
        end,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = CANDELA_AUGROUP,
        callback = function(args)
            local bufnr = args.buf

            -- Filter out special buffers
            local bt = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
            local name = vim.api.nvim_buf_get_name(bufnr)
            local buflisted = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })

            if bt ~= "" or name == "" or not buflisted then
                return
            end

            M.curr_buf = bufnr

            if opts.matching.auto_refresh then
                M.refresh()
            end
        end,
    })

    -- Return the functions designed to be part of public API via require("candela").ui
    return {
        M.show_patterns,
        M.hide_patterns,
        M.hide_prompt,
        M.toggle,
        M.toggle_select_pattern,
        M.add,
        M.edit,
        M.copy,
        M.delete,
        M.clear,
        M.refresh,
        M.change_color,
        M.toggle_highlight,
        M.toggle_lightbox,
        M.locate,
        M.import,
        M.export,
        M.help,
    }
end

-- Open patterns window
function M.show_patterns()
    local is_setup = true
    if M.windows.regex.win == nil then
        is_setup = false
    end

    if M.base_buf == nil or vim.api.nvim_buf_get_name(M.base_buf) == "" then
        M.base_buf = vim.api.nvim_get_current_buf()
    end

    if M.windows.regex:is_open() then
        return
    end

    if M.windows.patterns == nil then
        vim.notify("Need patterns window to attach to", vim.log.levels.ERROR)
    end

    M.windows.patterns:open_window() -- open patterns first to attach other windows

    for name, win in pairs(M.windows) do
        if name ~= "patterns" then
            win:attach_to(M.windows.patterns)
            if name == "regex" then
                win:open_window(true)
            elseif name ~= "prompt" then
                win:open_window()
            end
        end
    end

    vim.api.nvim_set_option_value("wrap", false, { win = M.windows.regex.win })
    vim.api.nvim_set_option_value("wrap", false, { win = M.windows.count.win })
    vim.api.nvim_set_option_value("winhighlight", "Normal:Comment", { win = M.windows.count.win })

    if not is_setup then
        for _, window in pairs(M.windows) do
            if window.win and vim.api.nvim_win_is_valid(window.win) then
                vim.api.nvim_win_call(window.win, function()
                    vim.wo.scrollbind = true
                end)
            end
        end
        vim.api.nvim_exec2("syncbind", {})
    end
end

---@param operation operations: type of operation to conduct
---@param index number?: index of currently selected line at time of operation
local function show_prompt(operation, index)
    M.windows.prompt:ensure_buffer()
    M.windows.prompt:attach_to(M.windows.patterns)
    vim.fn.prompt_setprompt(M.windows.prompt.buf, " > ")
    vim.api.nvim_set_option_value("buftype", "prompt", { buf = M.windows.prompt.buf })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = CANDELA_AUGROUP,
        buffer = M.windows.prompt.buf,
        desc = "Start the user in insert mode upon entering prompt window",
        callback = function()
            require("candela.mappings").set_prompt_keymaps()
            vim.api.nvim_cmd({ cmd = "startinsert" }, {})
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = CANDELA_AUGROUP,
        buffer = M.windows.prompt.buf,
        desc = "Ensure the regex window is focused after leaving prompt window",
        callback = function()
            vim.api.nvim_set_current_win(M.windows.regex.win)
        end,
    })
    vim.api.nvim_create_autocmd("QuitPre", {
        group = CANDELA_AUGROUP,
        desc = "Delete the prompt buffer right before quitting to prevent neovim asking to save prompt",
        callback = function()
            if M.windows.prompt.buf and vim.api.nvim_buf_is_valid(M.windows.prompt.buf) then
                vim.api.nvim_buf_delete(M.windows.prompt.buf, { force = true })
            end
        end,
    })

    if operation == Operations.ADD then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            CandelaPatternList.add(regex)
            M.hide_prompt()
        end)
    elseif operation == Operations.EDIT then
        if not index then
            vim.notify(
                string.format("[Candela] index must be specified for %s operations", operation),
                vim.log.levels.ERROR
            )
            return
        end

        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(new_regex)
            CandelaPatternList.edit(index, new_regex)
            M.hide_prompt()
        end)
    elseif operation == Operations.COPY then
        if not index then
            vim.notify(
                string.format("[Candela] index must be specified for %s operations", operation),
                vim.log.levels.ERROR
            )
            return
        end

        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            local _, curr_pattern = CandelaPatternList.get_id_and_pattern_by_index(index) --[[@as CandelaPattern]]
            CandelaPatternList.add(regex, curr_pattern.color, curr_pattern.highlight, curr_pattern.lightbox)
            M.hide_prompt()
        end)
    elseif operation == Operations.CHANGE_COLOR then
        if not index then
            vim.notify(
                string.format("[Candela] index must be specified for %s operations", operation),
                vim.log.levels.ERROR
            )
            return
        end

        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(new_color)
            CandelaPatternList.change_color(index, new_color)
            M.hide_prompt()
        end)
    elseif operation == Operations.IMPORT then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(path)
            require("candela.io").import(path)
            M.hide_prompt()
        end)
    elseif operation == Operations.EXPORT then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(path)
            require("candela.io").export(path)
            M.hide_prompt()
        end)
    else
        local operation_names = {}
        for comm, _ in pairs(Operations) do
            table.insert(operation_names, comm)
        end
        vim.notify(
            string.format(
                '[Candela] invalid operation "%s", must be one of: %s',
                operation,
                vim.inspect(operation_names)
            ),
            vim.log.levels.ERROR
        )
        return
    end

    M.windows.prompt:open_window(true)

    -- Set prompt window height
    M.windows.prompt.config.row = M.windows.patterns.config.height + PROMPT_OFFSET
    vim.api.nvim_win_set_config(M.windows.prompt.win, M.windows.prompt.config)
end

---@param index_or_regex integer|string?
---@return integer|nil, string|nil
local function get_index_and_color(index_or_regex)
    local index
    local color
    if not index_or_regex then
        index = vim.api.nvim_win_get_cursor(0)[1]
        color = CandelaPatternList.get_color_from_index(index)
    elseif type(index_or_regex) == "number" then
        index = index_or_regex
        color = CandelaPatternList.get_color_from_index(index)
    else
        index = CandelaPatternList.get_index_from_regex(index_or_regex --[[@as string]])
        if index then
            color = CandelaPatternList.get_color_from_index(index)
        end
    end
    return index, color
end

function M.add()
    M.show_patterns()
    M.windows.prompt.config.title = " Add Regex "

    show_prompt(Operations.ADD)
    vim.api.nvim_set_option_value("completefunc", "", { buf = M.windows.prompt.buf })
end

function M.edit()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("[Candela] must be in patterns window to run UI commands", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to edit", vim.log.levels.ERROR)
        return
    end

    local index = vim.api.nvim_win_get_cursor(0)[1]
    local regex = CandelaPatternList.get_regex_from_index(index)
    if regex == nil then
        vim.notify(string.format("[Candela] pattern does not exist at index %d", index), vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Edit Regex "

    vim.schedule(function()
        vim.api.nvim_paste(regex --[[@as string]], false, -1)
    end)

    show_prompt(Operations.EDIT, index)
    vim.api.nvim_set_option_value("completefunc", "", { buf = M.windows.prompt.buf })
end

function M.copy()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("[Candela] must be in patterns window to run UI commands", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to copy", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Copy Regex "

    local index = vim.api.nvim_win_get_cursor(0)[1]
    local regex = CandelaPatternList.get_regex_from_index(index)
    if regex == nil then
        vim.notify(string.format("[Candela] pattern does not exist at index %d", index), vim.log.levels.ERROR)
        return
    end

    vim.schedule(function()
        vim.api.nvim_paste(regex --[[@as string]], false, -1)
    end)

    show_prompt(Operations.COPY, index)
    vim.api.nvim_set_option_value("completefunc", "", { buf = M.windows.prompt.buf })
end

---@param ask boolean: show the confirmation message or not
function M.delete(ask)
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("[Candela] must be in patterns window to run UI commands", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to delete", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local _, curr_pattern = CandelaPatternList.get_id_and_pattern_by_index(curr_line)
    if curr_pattern == nil then
        return
    end
    if ask then
        local choice = vim.fn.confirm(
            string.format("Do you want to delete pattern %d: /%s/?", curr_line, curr_pattern.regex),
            "&Yes\n&No",
            2
        )
        if choice ~= 1 then
            vim.notify("[Candela] delete canceled", vim.log.levels.INFO)
            return
        end
    end

    if not CandelaPatternList.delete(curr_line) then
        return
    end
end

---@param ask boolean: show the confirmation message or not
function M.clear(ask)
    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to clear", vim.log.levels.ERROR)
        return
    end

    if ask then
        local choice = vim.fn.confirm("Do you want to clear all patterns?", "&Yes\n&No", 2)
        if choice ~= 1 then
            vim.notify("[Candela] clear canceled", vim.log.levels.INFO)
            return
        end
    end

    if not CandelaPatternList.clear() then
        return
    end
end

---@param force boolean?: defaults to false
---@param keep_base_buffer boolean?: defaults to false
function M.refresh(force, keep_base_buffer)
    if not force and not keep_base_buffer and M.base_buf == M.curr_buf then
        vim.notify("[Candela] current buffer is already being matched against, skipping refresh", vim.log.levels.INFO)
        return
    end

    refresh_to_curr_buf()
    if not keep_base_buffer then
        M.base_buf = M.curr_buf
    end
    CandelaLightbox.refresh()
end

function M.change_color()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("[Candela] must be in patterns window to run UI commands", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to change color", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Change Color "

    local index = vim.api.nvim_win_get_cursor(0)[1]
    local color = CandelaPatternList.get_color_from_index(index)
    if color == nil then
        vim.notify(string.format("[Candela] pattern does not exist at index %d", index), vim.log.levels.ERROR)
        return
    end

    vim.schedule(function()
        vim.api.nvim_paste(color --[[@as string]], false, -1)
    end)

    show_prompt(Operations.CHANGE_COLOR, index)
    vim.api.nvim_set_option_value("completefunc", "", { buf = M.windows.prompt.buf })
end

function M.toggle_highlight()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("[Candela] must be in patterns window to run UI commands", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to toggle highlight", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_id, curr_pattern = CandelaPatternList.get_id_and_pattern_by_index(curr_line)
    if curr_pattern == nil then
        return
    end

    local is_highlighted = CandelaPatternList.toggle_highlight(curr_line)
    if not CandelaHighlighter.toggle_match_highlights(M.base_buf, curr_id, curr_pattern.regex, is_highlighted) then
        return
    end

    update_ui_toggle("highlight", curr_line, curr_pattern)
end

function M.toggle_lightbox()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("[Candela] must be in patterns window to run UI commands", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to toggle lightbox", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_id = CandelaPatternList.order[curr_line]
    local is_lightboxed = CandelaPatternList.toggle_lightbox(curr_line)
    if is_lightboxed then
        CandelaLightbox.add_many_to_cache(CandelaHighlighter.match_cache[curr_id], curr_id)
    else
        CandelaLightbox.remove_from_cache(CandelaHighlighter.match_cache[curr_id], curr_id)
    end
    CandelaLightbox.update_folds()

    local _, curr_pattern = CandelaPatternList.get_id_and_pattern_by_index(curr_line)
    if curr_pattern == nil then
        return
    end
    update_ui_toggle("lightbox", curr_line, curr_pattern)
end

---@param all boolean: whether to match selected patterns or all
---@param command "match" | "find": type of command to run
function M.locate(all, command)
    if #CandelaPatternList.order == 0 then
        vim.notify("[Candela] no patterns to match", vim.log.levels.ERROR)
        return false
    end

    local cmd
    if command == "match" then
        cmd = require("candela.finder").match
    elseif command == "find" then
        cmd = require("candela.finder").find
    else
        vim.notify(
            string.format('[Candela] "%s" is not a valid locate command, must be "match" or "find"', command),
            vim.log.levels.ERROR
        )
    end

    local selected = {}
    if not all then
        if next(selected_patterns) == nil then
            local curr_line = vim.api.nvim_win_get_cursor(0)[1]
            local _, pattern = CandelaPatternList.get_id_and_pattern_by_index(curr_line)
            if pattern == nil then
                return false
            end
            table.insert(selected, pattern.regex)
        else
            local patterns = CandelaPatternList.patterns
            for id, _ in pairs(selected_patterns) do
                local pattern = patterns[id]
                table.insert(selected, pattern.regex)
            end
        end
    end

    M.hide_prompt()
    M.hide_patterns()
    local success = cmd(selected)
    if success and command == "find" then
        vim.api.nvim_cmd({ cmd = "lopen" }, {})
    end
end

function M.import()
    M.windows.prompt.config.title = " Import Patterns from File "
    show_prompt(Operations.IMPORT)
    vim.api.nvim_set_option_value(
        "completefunc",
        "v:lua.require'candela.io'.filepath_completion",
        { buf = M.windows.prompt.buf }
    )
    vim.api.nvim_input("<C-x><C-u>")
    vim.api.nvim_input("<C-p>")
end

function M.export()
    M.windows.prompt.config.title = " Export Patterns to File (leave blank for default) "
    show_prompt(Operations.EXPORT)
    vim.api.nvim_set_option_value(
        "completefunc",
        "v:lua.require'candela.io'.filepath_completion",
        { buf = M.windows.prompt.buf }
    )
    vim.api.nvim_input("<C-x><C-u>")
    vim.api.nvim_input("<C-p>")
end

function M.help()
    local help = require("candela.mappings").help
    help.win = vim.api.nvim_open_win(help.buf, true, help.config)
end

function M.hide_patterns()
    for name, win in pairs(M.windows) do
        if name ~= "prompt" and win:is_open() then
            win:hide_window()
        end
    end
    M.unselect_all()
end

function M.hide_prompt()
    if M.windows.prompt:is_open() then
        M.windows.prompt:close_window()
        vim.api.nvim_buf_set_lines(M.windows.prompt.buf, 0, -1, false, {})
    end
end

function M.toggle()
    if M.windows.prompt:is_open() then
        M.hide_patterns()
        M.hide_prompt()
    elseif M.windows.regex:is_open() then
        M.hide_patterns()
    else
        M.show_patterns()
    end
end

---@param index_or_regex integer|string?
function M.toggle_select_pattern(index_or_regex)
    if not index_or_regex and vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify(
            "[Candela] must be in patterns window to select patterns if no index or regex is given",
            vim.log.levels.ERROR
        )
        return
    end

    if #CandelaPatternList.order == 0 then
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local id = CandelaPatternList.order[curr_line]
    if selected_patterns[id] then
        CandelaHighlighter.highlight_selected(M.windows.regex, curr_line, false)
        selected_patterns[id] = nil
    else
        CandelaHighlighter.highlight_selected(M.windows.regex, curr_line, true)
        selected_patterns[id] = true
    end
end

function M.unselect_all()
    local ns = vim.api.nvim_create_namespace("CandelaUi")
    vim.api.nvim_buf_clear_namespace(M.windows.regex.buf, ns, 0, -1)
    selected_patterns = {}
end

function M.regen_colors()
    for i, _ in ipairs(CandelaPatternList.order) do
        local new_color = CandelaPatternList.next_color()
        CandelaPatternList.change_color(i, new_color)
    end

    M.refresh(true, true)
end

return M
