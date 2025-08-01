-- Module for initializing and manipulating the user interface

local CandelaConfig = require("candela.config")
local CandelaWindow = require("candela.window")
local CandelaPatternList = require("candela.pattern_list")
local CandelaEngine = require("candela.engine")
local CandelaHighlighter = require("candela.highlighter")
local CandelaFinder = require("candela.finder")

local candela_augroup = vim.api.nvim_create_augroup("Candela", { clear = true })

---@class CandelaUi
---@field windows table<string, CandelaWindow>
---@field base_buf number

local M = {}

local Commands = {}

---@param field string: Field name
---@param field_val string|boolean|number
---@return string: String to input into buffer lines
local function format_field(field, field_val)
    if type(field_val) == "boolean" then
        return field_val and "  ✓  " or "  ✘  "
    elseif field == "regex" then
        return string.format(" /%s/", field_val) or ""
    elseif type(field_val) == "number" then
        local win_width = vim.api.nvim_win_get_width(M.windows.count.win)
        local line = tostring(field_val)
        local right_aligned = string.rep(" ", win_width - #line) .. line
        return right_aligned
    else
        return field_val or ""
    end
end

-- Update lines of the patterns buffers
local function update_lines()
    local all_lines = {
        color = {},
        count = {},
        regex = {},
        highlight = {},
        lightbox = {},
    }

    for _, pattern in ipairs(CandelaPatternList.patterns) do
        for field, _ in pairs(all_lines) do
            table.insert(all_lines[field], format_field(field, pattern[field]))
        end
    end

    for field, lines in pairs(all_lines) do
        vim.api.nvim_set_option_value("modifiable", true, { buf = M.windows[field].buf })
        vim.api.nvim_buf_set_lines(M.windows[field].buf, 0, -1, false, lines)
        vim.api.nvim_set_option_value("modifiable", false, { buf = M.windows[field].buf })
    end

    CandelaHighlighter.highlight_ui(M.windows, CandelaPatternList.patterns)
end

-- TODO: revise this better
-- If the number of patterns in list exceeds the height of the current height, increase height of patterns windows
local function resize_height()
    local curr_height = vim.api.nvim_win_get_height(M.windows.regex.win) -- Num of shown entries
    if #CandelaPatternList.patterns > curr_height then
        local new_height = math.min(M.windows.patterns.config.height + 1, vim.o.lines - 6)
        local prompt_height = M.windows.prompt.config.height
        local new_vert_center = math.floor((vim.o.lines - new_height - prompt_height - 2) / 2)
        M.windows.patterns.config.row = new_vert_center
        M.windows.patterns.config.height = new_height
        vim.api.nvim_win_set_config(M.windows.patterns.win, M.windows.patterns.config)

        for name, win in pairs(M.windows) do
            if name ~= "prompt" and name ~= "patterns" then
                win.config.height = M.windows.patterns.config.height - 2
                vim.api.nvim_win_set_config(win.win, win.config)
            end
        end
        M.windows.prompt.config.row = M.windows.patterns.config.height
        vim.api.nvim_win_set_config(M.windows.prompt.win, M.windows.prompt.config)
    end
end

local function refresh_all()
    for _, pattern in ipairs(CandelaPatternList.patterns) do
        if not CandelaHighlighter.remove_match_highlights(M.base_buf, pattern.regex) then
            return
        end

        local cmd = CandelaConfig.options.engine.command
        local args = CandelaConfig.options.engine.args
        local count = CandelaHighlighter.highlight_matches(M.curr_buf, pattern, cmd, args)
        if count == -1 then
            return
        end

        pattern.count = count
        M.show_patterns()
        update_lines()
        resize_height()
        M.toggle()
    end

    M.base_buf = M.curr_buf
end

---@param opts table
function M.setup(opts)
    local pattern_color_width = 7 -- 7 space hexcode
    local pattern_count_width = 4 -- 3 digit, resize to fit larger digits once more patterns are made
    local pattern_regex_width = opts.window.width
    local pattern_ops_width = 5 -- 1 space letter/symbol, 2 space margin on each side
    local float_width = pattern_regex_width + pattern_color_width + (pattern_ops_width * 3) + 4 -- total window width

    local pattern_height = opts.window.height -- starting height
    local prompt_height = 1 -- 1 space height for prompt
    local float_height = pattern_height + 2 -- + prompt_height + 2

    local defaults = require("candela.config").defaults
    local prompt_layout = 0
    if opts.window.prompt_layout == "overlap" then
        prompt_layout = 2
    elseif opts.window.prompt_layout == "border" then
        prompt_layout = 3
    else
        vim.notify(
            string.format(
                '"%s" is not a valid option value for `window.prompt_layout`, using "%s" as default.'
                    .. ' Valid values: "overlap", "border".',
                opts.window.prompt_layout,
                defaults.prompt_layout
            ),
            vim.log.levels.WARN
        )
        prompt_layout = 2
    end

    -- Account for 2 border spaces worth of padding to center window in center of base window
    local horz_center = math.floor((vim.o.columns - float_width - 2) / 2)
    local vert_center = math.floor((vim.o.lines - pattern_height - prompt_height - 2) / 2)

    local patterns = CandelaWindow.new({
        relative = "editor",
        width = float_width,
        height = float_height,
        style = "minimal",
        focusable = false,
        title = " Candela ",
        title_pos = "center",
        border = "rounded",
        col = horz_center,
        row = vert_center,
        zindex = 1,
    })
    local color = CandelaWindow.new({
        relative = "win",
        width = pattern_color_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = "Color",
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
        col = pattern_color_width,
        row = 0,
        zindex = 10,
    })
    local regex = CandelaWindow.new({
        relative = "win",
        width = pattern_regex_width,
        height = patterns.config.height - 2,
        style = "minimal",
        title = " Regex",
        title_pos = "left",
        border = "solid",
        col = pattern_color_width + pattern_ops_width,
        row = 0,
        zindex = 10,
    })
    local highlight = CandelaWindow.new({
        relative = "win",
        width = pattern_ops_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = "H",
        title_pos = "center",
        border = "solid",
        col = pattern_color_width + pattern_regex_width + pattern_ops_width + 1,
        row = 0,
        zindex = 10,
    })
    local lightbox = CandelaWindow.new({
        relative = "win",
        width = pattern_ops_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = "L",
        title_pos = "center",
        border = "solid",
        col = pattern_color_width + pattern_regex_width + ((pattern_ops_width + 1) * 2),
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
        row = pattern_height + prompt_layout,
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

    local i = 0
    for comm, _ in pairs(require("candela.commands").commands) do
        Commands[string.upper(comm)] = i
        i = i + 1
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

    vim.wo[M.windows.count.win].winhighlight = "Normal:Comment"
end

---@param command string: type of command to conduct
---@param curr_line number?: index of currently selected line at time of command
---@param curr_pattern CandelaPattern?: currently selected pattern
local function show_prompt(command, curr_line, curr_pattern)
    if curr_line == nil and command ~= Commands.ADD then
        vim.notify(string.format("Candela: current line can't be nil when running %s", command), vim.log.levels.ERROR)
        return
    end
    if curr_pattern == nil and command ~= Commands.ADD then
        vim.notify(
            string.format("Candela: current pattern can't be nil when running %s", command),
            vim.log.levels.ERROR
        )
        return
    end

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

    if command == Commands.ADD then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            local new_pattern = CandelaPatternList.add_pattern(regex)
            if new_pattern == nil then
                return M.hide_prompt()
            end

            local cmd = CandelaConfig.options.engine.command
            local args = CandelaConfig.options.engine.args
            local count = CandelaHighlighter.highlight_matches(M.base_buf, new_pattern, cmd, args)
            if count == -1 then
                return
            end

            new_pattern.count = count
            update_lines()
            resize_height()
            M.hide_prompt()
        end)
    elseif command == Commands.EDIT then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            local old_regex = curr_pattern.regex
            local new_pattern = CandelaPatternList.edit_pattern(curr_line, regex)
            if new_pattern == nil then
                return M.hide_prompt()
            end

            if not CandelaHighlighter.remove_match_highlights(M.base_buf, old_regex) then
                return
            end

            local cmd = CandelaConfig.options.engine.command
            local args = CandelaConfig.options.engine.args
            local count = CandelaHighlighter.highlight_matches(M.base_buf, new_pattern, cmd, args)
            if count == -1 then
                return
            end

            new_pattern.count = count
            update_lines()
            M.hide_prompt()
        end)
    elseif command == Commands.COPY then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(regex)
            local new_pattern = CandelaPatternList.add_pattern(regex)
            if new_pattern == nil then
                return M.hide_prompt()
            end

            local cmd = CandelaConfig.options.engine.command
            local args = CandelaConfig.options.engine.args
            local count = CandelaHighlighter.highlight_matches(M.base_buf, new_pattern, cmd, args)
            if count == -1 then
                return
            end

            new_pattern.count = count
            update_lines()
            resize_height()
            M.hide_prompt()
        end)
    elseif command == Commands.CHANGE_COLOR then
        vim.fn.prompt_setcallback(M.windows.prompt.buf, function(color)
            local new_pattern = CandelaPatternList.change_pattern_color(curr_line, color)
            if new_pattern == nil then
                return
            end

            if not CandelaHighlighter.change_highlight_color(curr_pattern.regex, new_pattern.color) then
                return
            end

            update_lines()
            resize_height()
            M.hide_prompt()
        end)
    else
        local command_names = {}
        for comm, _ in pairs(Commands) do
            table.insert(command_names, comm)
        end
        vim.notify(
            string.format('Candela: invalid command "%s", must be one of: %s', command, vim.inspect(command_names)),
            vim.log.levels.ERROR
        )
        return
    end

    M.windows.prompt:open_window(true)
end

function M.add()
    M.windows.prompt.config.title = " Add Regex "
    show_prompt(Commands.ADD)
end

function M.edit()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to edit regex", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to edit", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Edit Regex "
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)

    vim.schedule(function()
        vim.api.nvim_paste(curr_pattern.regex, false, -1)
    end)

    show_prompt(Commands.EDIT, curr_line, curr_pattern)
end

function M.copy()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to copy regex", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to copy", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Copy Regex "
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    vim.schedule(function()
        vim.api.nvim_paste(curr_pattern.regex, false, -1)
    end)

    show_prompt(Commands.COPY, curr_line, curr_pattern)
end

---@param ask boolean: show the confirmation message or not
function M.delete(ask)
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to delete pattern", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to delete", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
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

    if not CandelaHighlighter.remove_match_highlights(M.base_buf, curr_pattern.regex) then
        return
    end

    update_lines()
    resize_height() -- TODO: Shrink height if size decreases
end

---@param ask boolean: show the confirmation message or not
function M.clear(ask)
    if #CandelaPatternList.patterns == 0 then
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

    local patterns = CandelaPatternList.patterns
    CandelaPatternList.clear_patterns()
    for _, pattern in ipairs(patterns) do
        if CandelaHighlighter.remove_match_highlights(M.base_buf, pattern.regex) then
            update_lines()
            -- M.reset_height() -- TODO: Implement reset_height()
        end
    end
end

function M.refresh()
    refresh_all()
end

function M.change_color()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex color", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to change color", vim.log.levels.ERROR)
        return
    end

    M.windows.prompt.config.title = " Change Color "
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    vim.schedule(function()
        vim.api.nvim_paste(curr_pattern.color, false, -1)
    end)

    show_prompt(Commands.CHANGE_COLOR, curr_line, curr_pattern)
end

function M.toggle_highlight()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex highlight", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to toggle highlight", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    local is_highlighted = CandelaPatternList.toggle_pattern_highlight(curr_line)
    if is_highlighted then
        local cmd = CandelaConfig.options.engine.command
        local args = CandelaConfig.options.engine.args
        local count = CandelaHighlighter.highlight_matches(M.base_buf, curr_pattern, cmd, args)
        if count == -1 then
            return
        end
        curr_pattern.count = count
    else
        if not CandelaHighlighter.remove_match_highlights(M.base_buf, curr_pattern.regex) then
            return
        end
    end
    update_lines()
end

function M.toggle_lightbox()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to toggle regex lightbox", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to toggle lightbox", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    CandelaPatternList.toggle_pattern_lightbox(curr_line)
    -- NOTE: TEMPORARY FOR TESTING
    if CandelaPatternList.toggle_pattern_highlight(curr_line) then
        local cmd = CandelaConfig.options.engine.command
        local args = CandelaConfig.options.engine.args
        local count = CandelaHighlighter.highlight_matches(M.base_buf, curr_pattern, cmd, args)
        if count == -1 then
            return
        end
        curr_pattern.count = count
    else
        if not CandelaHighlighter.remove_match_highlights(M.base_buf, curr_pattern.regex) then
            return
        end
    end
    -- NOTE: END TEMPORARY FOR TESTING
    update_lines()
end

function M.match()
    if vim.api.nvim_get_current_win() ~= M.windows.regex.win then
        vim.notify("Candela: must be in patterns window to match regex", vim.log.levels.ERROR)
        return
    end

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to match", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    M.toggle()
    CandelaFinder.match(curr_pattern.regex)
end

function M.match_all()
    if #CandelaPatternList.patterns == 0 then
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

    if #CandelaPatternList.patterns == 0 then
        vim.notify("Candela: no patterns to find", vim.log.levels.ERROR)
        return
    end

    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local curr_pattern = CandelaPatternList.get_pattern(curr_line)
    M.toggle()
    CandelaFinder.find(M.base_buf, curr_pattern.regex, CandelaEngine.get_matches)
end

function M.find_all()
    if #CandelaPatternList.patterns == 0 then
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
