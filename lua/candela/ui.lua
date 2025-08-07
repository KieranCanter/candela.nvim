-- Module for initializing and manipulating the user interface

local CandelaConfig = require("candela.config")
local CandelaWindow = require("candela.window")
local CandelaPatternList = require("candela.pattern_list")
local CandelaEngine = require("candela.engine")
local CandelaHighlighter = require("candela.highlighter")
local CandelaFinder = require("candela.finder")
local CandelaLightbox = require("candela.lightbox")

local candela_augroup = vim.api.nvim_create_augroup("Candela", { clear = true })

---@class CandelaUi
---@field windows table<string, CandelaWindow>
---@field base_buf number

local M = {}

local MIN_HEIGHT, MAX_HEIGHT = 0, 0
local PROMPT_OFFSET = 0

---@enum operations
local Operations = {
    ADD = 1,
    EDIT = 2,
    COPY = 3,
    CHANGE_COLOR = 4,
}

---@param field string: Field name
---@param field_val string|boolean|number
---@return string: String to input into buffer lines
local function format_field(field, field_val)
    if field == "color" and type(field_val) == "string" then
        return field_val
    elseif field == "count" then
        local win_width = vim.api.nvim_win_get_width(M.windows.count.win)
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
local function update_ui_lines()
    local all_lines = {
        color = {},
        count = {},
        regex = {},
        highlight = {},
        lightbox = {},
    }

    local pattern_list = {}
    for _, id in ipairs(CandelaPatternList.order) do
        local pattern = CandelaPatternList.patterns[id]
        table.insert(pattern_list, pattern)
        for field, _ in pairs(all_lines) do
            table.insert(all_lines[field], format_field(field, pattern[field]))
        end
    end

    for field, lines in pairs(all_lines) do
        vim.api.nvim_set_option_value("modifiable", true, { buf = M.windows[field].buf })
        vim.api.nvim_buf_set_lines(M.windows[field].buf, 0, -1, false, lines)
        vim.api.nvim_set_option_value("modifiable", false, { buf = M.windows[field].buf })
    end

    CandelaHighlighter.highlight_ui(M.windows, pattern_list)
end

-- Update toggle in the UI
---@param kind string: which toggle to update
---| `highlight`
---| `lightbox`
---@param row integer: row of UI to update
---@param pattern CandelaPattern: pattern to get value from
local function update_ui_toggle(kind, row, pattern)
    local toggled_line = format_field(kind, pattern[kind])

    vim.api.nvim_set_option_value("modifiable", true, { buf = M.windows[kind].buf })
    vim.api.nvim_buf_set_lines(M.windows[kind].buf, row - 1, row, false, { toggled_line })
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.windows[kind].buf })

    CandelaHighlighter.highlight_ui_toggle(M.windows[kind], kind, row, pattern)
end

---@param delete boolean?: if deleting a pattern, don't move cursor to bottom
local function resize_height(delete)
    local num_pats = #CandelaPatternList.order
    local old_height = vim.api.nvim_win_get_height(M.windows.patterns.win) - 2 -- Num of shown entries
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
    vim.api.nvim_win_set_config(M.windows.patterns.win, M.windows.patterns.config)

    -- Set inner window heights
    for name, win in pairs(M.windows) do
        if name ~= "prompt" and name ~= "patterns" then
            win.config.height = M.windows.patterns.config.height - 2
            vim.api.nvim_win_set_config(win.win, win.config)
        end
    end
end

local function refresh_all()
    if M.base_buf == M.curr_buf then
        vim.notify("Candela: current buffer is already being matched against, skipping refresh", vim.log.levels.INFO)
        return
    end

    for _, id in ipairs(CandelaPatternList.order) do
        local pattern = CandelaPatternList.patterns[id]
        if not CandelaHighlighter.remove_match_highlights(M.base_buf, id, pattern.regex) then
            return
        end

        local cmd = CandelaConfig.options.engine.command --[[@as string]]
        local args = CandelaConfig.options.engine.args
        local count = CandelaHighlighter.highlight_matches(M.curr_buf, id, pattern, cmd, args)
        if count == -1 then
            return
        end

        pattern.count = count
        M.show_patterns()
        update_ui_lines()
        resize_height()
        M.toggle()
    end

    M.base_buf = M.curr_buf
end

---@param icon string|nil: user config icon option
---@param type string: type of icon (e.g. "color" or "highlight" or "lightbox")
---@param subtype string|nil: subtype name (e.g. nil or "header" "toggle_on" or "toggle_off")
---@param header string: header to preface icon (e.g. "Color" or "HL" or "LB" or "")
---@param default string: default fallback value
---@return string: formatted UI string
local function format_icon(icon, type, subtype, header, default)
    if icon == nil then
        return default
    end

    local width = vim.fn.strwidth(icon)
    if width == 2 then
        if subtype == "toggle_on" or subtype == "toggle_off" then
            return string.format("   %s", icon)
        else
            return string.format("%s%s", header, icon)
        end
    elseif width == 1 then
        if subtype == "toggle_on" or subtype == "toggle_off" then
            return string.format("  %s  ", icon)
        else
            return string.format("%s %s", header, icon)
        end
    else
        vim.notify(
            string.format(
                '[Candela] icons.%s%s option must be string of len 1 or 2, got "%s". Proceeding with default of "%s".',
                type,
                subtype and "." .. subtype or "",
                icon,
                default
            ),
            vim.log.levels.WARN
        )
        return default
    end
end

---@param opts table
function M.setup(opts)
    MIN_HEIGHT, MAX_HEIGHT = opts.window.min_height, opts.window.max_height
    local pattern_color_width = 7 -- 7 space hexcode
    local pattern_count_width = 4 -- 4 digit, resize to fit larger digits once more patterns are made
    local pattern_ops_width = 5 -- 1 space letter/symbol, 2 space margin on each side
    local float_width = opts.window.width -- total window width
    -- Fit regex to rest of window leftover, subtract 1 for each space inbetween windows
    local pattern_regex_width = float_width - pattern_color_width - pattern_count_width - (pattern_ops_width * 2) - 6

    local pattern_height = MIN_HEIGHT + 2 -- starting height
    local prompt_height = 1 -- 1 space height for prompt

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

    -- Account for 2 border spaces worth of padding to center window in center of base window
    local horz_center = math.floor((vim.o.columns - float_width - 2) / 2)
    local vert_center = math.floor((vim.o.lines - pattern_height - prompt_height) / 2)

    local title = ""
    local icons = CandelaConfig.options.icons
    if icons.candela ~= nil then
        title = string.format(" %sCandela ", icons.candela)
    else
        title = " Candela "
    end
    local patterns = CandelaWindow.new({
        relative = "editor",
        width = float_width,
        height = pattern_height,
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "rounded",
        col = horz_center,
        row = vert_center,
        zindex = 1,
    })

    if icons.color ~= nil then
        if vim.fn.strwidth(icons.color) == 2 then
            title = string.format("%sColor", icons.color)
        else
            title = string.format("%s Color", icons.color)
        end
    else
        title = "Color"
    end
    title = format_icon(icons.color, "color", nil, "Color", "Color")
    local color = CandelaWindow.new({
        relative = "win",
        width = pattern_color_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "solid",
        col = 0,
        row = 0,
        zindex = 10,
    })

    local count = CandelaWindow.new({
        relative = "win",
        width = pattern_count_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = "",
        border = "solid",
        col = pattern_color_width + 1,
        row = 0,
        zindex = 10,
    })

    if icons.regex ~= nil then
        title = string.format(" %sRegex", icons.regex)
    else
        title = " Regex"
    end
    local regex = CandelaWindow.new({
        relative = "win",
        width = pattern_regex_width,
        height = patterns.config.height - 2,
        style = "minimal",
        title = title,
        title_pos = "left",
        border = "solid",
        col = pattern_color_width + pattern_count_width + 2,
        row = 0,
        zindex = 10,
    })

    title = format_icon(icons.highlight.header, "highlight", "header", "HL ", "  H  ")
    local highlight = CandelaWindow.new({
        relative = "win",
        width = pattern_ops_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "solid",
        col = pattern_color_width + pattern_count_width + pattern_regex_width + 3,
        row = 0,
        zindex = 10,
    })

    title = format_icon(icons.lightbox.header, "lightbox", "header", "LB ", "  L  ")
    local lightbox = CandelaWindow.new({
        relative = "win",
        width = pattern_ops_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = title,
        title_pos = "center",
        border = "solid",
        col = pattern_color_width + pattern_count_width + pattern_regex_width + pattern_ops_width + 4,
        row = 0,
        zindex = 10,
    })
    local prompt = CandelaWindow.new({
        relative = "win",
        width = float_width,
        height = prompt_height,
        style = "minimal",
        title_pos = "left",
        border = "rounded",
        col = -1,
        row = pattern_height + PROMPT_OFFSET,
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

    -- set highlight/lightbox toggling strings since they're constant
    local highlight_on_def = "  Y  "
    local highlight_off_def = "  N  "
    local lightbox_on_def = "  Y  "
    local lightbox_off_def = "  N  "
    M.highlight_on = format_icon(icons.highlight.toggle_on, "highlight", "toggle_on", "", highlight_on_def)
    M.highlight_off = format_icon(icons.highlight.toggle_off, "highlight", "toggle_off", "", highlight_off_def)
    M.lightbox_on = format_icon(icons.lightbox.toggle_on, "lightbox", "toggle_on", "", lightbox_on_def)
    M.lightbox_off = format_icon(icons.lightbox.toggle_off, "lightbox", "toggle_off", "", lightbox_off_def)

    -- TODO: handle resizing of window when vim is resized with autocmd
    -- TODO: handle resizing of count window when count exceeds width

    for name, window in pairs(M.windows) do
        window:ensure_buffer()
        vim.api.nvim_set_option_value("swapfile", false, { buf = window.buf })
        vim.api.nvim_set_option_value("filetype", "candela", { buf = window.buf })
        if name ~= "prompt" then
            vim.api.nvim_set_option_value("modifiable", false, { buf = window.buf })
        end
    end

    CandelaConfig.set_keymaps() -- NOTE: For dev purposes only
    CandelaConfig.set_patterns_keymaps(M.windows.regex.buf)
    CandelaConfig.set_prompt_keymaps(M.windows.prompt.buf)

    vim.api.nvim_create_autocmd("BufHidden", {
        group = candela_augroup,
        buffer = M.windows.regex.buf,
        callback = function()
            M.hide_patterns()
        end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = candela_augroup,
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
        group = candela_augroup,
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
                refresh_all()
            end
        end,
    })

    return M.windows
end

-- Open patterns window
function M.show_patterns()
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
    vim.api.nvim_set_option_value("winhighlight", "Normal:Comment", { win = M.windows.count.win })
end

---@param operation operations: type of operation to conduct
---@param curr_line number?: index of currently selected line at time of operation
---@param curr_pattern CandelaPattern?: currently selected pattern
local function show_prompt(operation, curr_line, curr_pattern)
    if curr_line == nil and operation ~= Operations.ADD then
        vim.notify(string.format("Candela: current line can't be nil when running %s", operation), vim.log.levels.ERROR)
        return
    end
    if curr_pattern == nil and operation ~= Operations.ADD then
        vim.notify(
            string.format("Candela: current pattern can't be nil when running %s", operation),
            vim.log.levels.ERROR
        )
        return
    end
    ---@cast curr_line number
    ---@cast curr_pattern CandelaPattern

    M.windows.prompt:ensure_buffer()
    M.windows.prompt:attach_to(M.windows.patterns)
    vim.fn.prompt_setprompt(M.windows.prompt.buf, " > ")
    vim.api.nvim_set_option_value("buftype", "prompt", { buf = M.windows.prompt.buf })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = candela_augroup,
        buffer = M.windows.prompt.buf,
        desc = "Start the user in insert mode upon entering prompt window",
        callback = function()
            vim.api.nvim_cmd({ cmd = "startinsert" }, {})
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = candela_augroup,
        buffer = M.windows.prompt.buf,
        desc = "Ensure the regex window is focused after leaving prompt window",
        callback = function()
            vim.api.nvim_set_current_win(M.windows.regex.win)
        end,
    })
    vim.api.nvim_create_autocmd("QuitPre", {
        group = candela_augroup,
        desc = "Delete the prompt buffer right before quitting to prevent neovim asking to save prompt",
        callback = function()
            if M.windows.prompt.buf and vim.api.nvim_buf_is_valid(M.windows.prompt.buf) then
                vim.api.nvim_buf_delete(M.windows.prompt.buf, { force = true })
            end
        end,
    })

    if operation == Operations.ADD then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            local new_id, new_pattern = CandelaPatternList.add_pattern(regex)
            if new_id == nil or new_pattern == nil then
                return M.hide_prompt()
            end

            local cmd = CandelaConfig.options.engine.command --[[@as string]]
            local args = CandelaConfig.options.engine.args
            local count = CandelaHighlighter.highlight_matches(M.base_buf, new_id, new_pattern, cmd, args)
            if count == -1 then
                return
            end

            new_pattern.count = count
            update_ui_lines()
            resize_height()
            M.hide_prompt()

            if CandelaLightbox.window:is_open() then
                CandelaLightbox.update_folds()
            end
        end)
    elseif operation == Operations.EDIT then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            local old_regex = curr_pattern.regex
            local old_id = CandelaPatternList.order[curr_line]
            local new_id, new_pattern = CandelaPatternList.edit_pattern(curr_line --[[@as number]], regex)
            if new_id == nil or new_pattern == nil then
                return M.hide_prompt()
            end

            if not CandelaHighlighter.remove_match_highlights(M.base_buf, old_id, old_regex) then
                return
            end

            local cmd = CandelaConfig.options.engine.command --[[@as string]]
            local args = CandelaConfig.options.engine.args
            local count = CandelaHighlighter.highlight_matches(M.base_buf, new_id, new_pattern, cmd, args)
            if count == -1 then
                return
            end

            new_pattern.count = count
            update_ui_lines()
            M.hide_prompt()

            if CandelaLightbox.window:is_open() then
                CandelaLightbox.update_folds()
            end
        end)
    elseif operation == Operations.COPY then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            local new_id, new_pattern = CandelaPatternList.add_pattern(regex)
            if new_id == nil or new_pattern == nil then
                return M.hide_prompt()
            end

            local cmd = CandelaConfig.options.engine.command --[[@as string]]
            local args = CandelaConfig.options.engine.args
            local count = CandelaHighlighter.highlight_matches(M.base_buf, new_id, new_pattern, cmd, args)
            if count == -1 then
                return
            end

            new_pattern.count = count
            update_ui_lines()
            resize_height()
            M.hide_prompt()

            if CandelaLightbox.window:is_open() then
                CandelaLightbox.update_folds()
            end
        end)
    elseif operation == Operations.CHANGE_COLOR then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(color)
            local new_pattern = CandelaPatternList.change_pattern_color(curr_line, color)
            if new_pattern == nil then
                return
            end

            if not CandelaHighlighter.change_highlight_color(curr_pattern.regex, new_pattern.color) then
                return
            end

            update_ui_lines()
            resize_height()
            M.hide_prompt()
        end)
    else
        local operation_names = {}
        for comm, _ in pairs(Operations) do
            table.insert(operation_names, comm)
        end
        vim.notify(
            string.format('Candela: invalid operation "%s", must be one of: %s', operation, vim.inspect(operation_names)),
            vim.log.levels.ERROR
        )
        return
    end

    M.windows.prompt:open_window(true)

    -- Set prompt window height
    M.windows.prompt.config.row = M.windows.patterns.config.height + PROMPT_OFFSET
    vim.api.nvim_win_set_config(M.windows.prompt.win, M.windows.prompt.config)
end

function M.add()
    M.windows.prompt.config.title = " Add Regex "
    show_prompt(Operations.ADD)
end

function M.edit()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to edit regex", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to edit", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Edit Regex "
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)

    vim.schedule(function()
        vim.api.nvim_paste(curr_pattern.regex, false, -1)
    end)

    show_prompt(Operations.EDIT, curr_line, curr_pattern)
end

function M.copy()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to copy regex", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to copy", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Copy Regex "
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    vim.schedule(function()
        vim.api.nvim_paste(curr_pattern.regex, false, -1)
    end)

    show_prompt(Operations.COPY, curr_line, curr_pattern)
end

---@param ask boolean: show the confirmation message or not
function M.delete(ask)
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to delete pattern", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to delete", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_id = CandelaPatternList.order[curr_line]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    if ask then
        local choice = vim.fn.confirm(
            string.format("Do you want to delete pattern %d: /%s/?", curr_line, curr_pattern.regex),
            "&Yes\n&No",
            2
        )
        if choice ~= 1 then
            vim.notify("Candela: delete canceled", vim.log.levels.INFO)
            return
        end
    end

    if not CandelaPatternList.delete_pattern(curr_line) then
        return
    end

    if not CandelaHighlighter.remove_match_highlights(M.base_buf, curr_id, curr_pattern.regex) then
        return
    end

    if CandelaLightbox.window:is_open() then
        CandelaLightbox.update_folds()
    end

    update_ui_lines()
    resize_height(true)
end

---@param ask boolean: show the confirmation message or not
function M.clear(ask)
    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to clear", vim.log.levels.ERROR)
        return
    end

    if ask then
        local choice = vim.fn.confirm("Do you want to clear all patterns?", "&Yes\n&No", 2)
        if choice ~= 1 then
            vim.notify("Candela: clear canceled", vim.log.levels.INFO)
            return
        end
    end

    local order = CandelaPatternList.order
    local patterns = CandelaPatternList.patterns
    CandelaPatternList.clear_patterns()
    for _, id in ipairs(order) do
        local pattern = patterns[id]
        if CandelaHighlighter.remove_match_highlights(M.base_buf, id, pattern.regex) then
            update_ui_lines()
        end
    end
    resize_height()

    if CandelaLightbox.window:is_open() then
        CandelaLightbox.update_folds()
    end
end

function M.refresh()
    refresh_all()
    CandelaLightbox.refresh()
end

function M.change_color()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex color", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to change color", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Change Color "
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    vim.schedule(function()
        vim.api.nvim_paste(curr_pattern.color, false, -1)
    end)

    show_prompt(Operations.CHANGE_COLOR, curr_line, curr_pattern)
end

function M.toggle_highlight()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex highlight", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to toggle highlight", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_id = CandelaPatternList.order[curr_line]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    local is_highlighted = CandelaPatternList.toggle_pattern_highlight(curr_line)
    if not CandelaHighlighter.toggle_match_highlights(M.base_buf, curr_id, curr_pattern.regex, is_highlighted) then
        return
    end

    update_ui_toggle("highlight", curr_line, curr_pattern)
end

function M.toggle_lightbox()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex lightbox", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to toggle lightbox", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_id = CandelaPatternList.order[curr_line]
    local is_lightboxed = CandelaPatternList.toggle_pattern_lightbox(curr_line)
    if is_lightboxed then
        CandelaLightbox.add_many_to_cache(CandelaHighlighter.match_cache[curr_id], curr_id)
    else
        CandelaLightbox.remove_from_cache(CandelaHighlighter.match_cache[curr_id], curr_id)
    end
    CandelaLightbox.update_folds()

    update_ui_toggle("lightbox", curr_line, CandelaPatternList.get_pattern(curr_line))
end

function M.match()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to match regex", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to match", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    M.toggle()
    CandelaFinder.match(curr_pattern.regex)
end

function M.match_all()
    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to match all", vim.log.levels.ERROR)
        return
    end

    M.hide_prompt()
    M.hide_patterns()
    CandelaFinder.match_all(CandelaPatternList.patterns)
end

function M.find()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to find instances of regex", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to find", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    M.toggle()
    CandelaFinder.find(M.base_buf, curr_pattern.regex, CandelaEngine.get_matches)
end

function M.find_all()
    if #CandelaPatternList.order == 0 then
        vim.notify("Candela: no patterns to find all", vim.log.levels.ERROR)
        return
    end

    M.hide_prompt()
    M.hide_patterns()
    CandelaFinder.find_all(M.base_buf, CandelaPatternList.patterns, CandelaEngine.get_matches)
end

function M.help()
    vim.notify("Candela: help subcommand not implemented yet", vim.log.levels.WARN)
end

function M.hide_patterns()
    for name, win in pairs(M.windows) do
        if name ~= "prompt" and win:is_open() then
            win:close_window()
        end
    end
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

return M
