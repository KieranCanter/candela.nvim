-- Module for initializing and manipulating the user interface

local CandelaPatternList = require("candela.pattern_list")
local CandelaWindow = require("candela.window")
local CandelaEngine = require("candela.engine")
local CandelaHighlighter = require("candela.highlighter")
local CandelaConfig = require("candela.config")

local candela_augroup = vim.api.nvim_create_augroup("Candela", { clear = true })

---@class CandelaUi
---@field windows table<string, CandelaWindow>

local CandelaUi = {}
CandelaUi.windows = {} -- singleton field

---@param opts table<string, number>
---@return CandelaUi
function CandelaUi.new(opts)
    CandelaUi.setup(opts)
    return CandelaUi
end

---@param opts table<string, number>
function CandelaUi.setup(opts)
    local win_width = vim.o.columns
    local win_height = vim.o.lines

    local float_width = math.floor(win_width * 0.50) -- total window width before borders
    local pattern_color_width = 9 -- 7 space hex code, 1 space margin on each side
    local pattern_ops_width = 5 -- 1 space letter/symbol, 2 space margin on each side
    -- fill rest of width with regex window, minus 2 for border (1 space on each side)
    local pattern_regex_width = float_width - pattern_color_width - (pattern_ops_width * 2) - 2

    local pattern_height = opts.height -- starting height
    local prompt_height = 1 -- 1 space height for prompt
    local float_height = pattern_height + 2 -- + prompt_height + 2

    local total_width = float_width + 6 -- total window width after borders

    -- Account for 2 border spaces worth of padding to center window in center of base window
    local horz_center = math.floor((win_width - total_width - 2) / 2)
    local vert_center = math.floor((win_height - pattern_height - prompt_height - 2) / 2)

    local patterns = CandelaWindow.new({
        relative = "editor",
        width = total_width,
        height = float_height,
        style = "minimal",
        focusable = false,
        title = " Patterns ",
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
        title = " Color ",
        title_pos = "center",
        border = "solid",
        col = 0,
        row = 0,
        zindex = 10,
    })
    local regex = CandelaWindow.new({
        relative = "win",
        width = pattern_regex_width,
        height = patterns.config.height - 2,
        style = "minimal",
        title = " Regex ",
        title_pos = "left",
        border = "solid",
        col = pattern_color_width + 2,
        row = 0,
        zindex = 10,
    })
    local highlight = CandelaWindow.new({
        relative = "win",
        width = pattern_ops_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = " H ",
        title_pos = "center",
        border = "solid",
        col = pattern_color_width + pattern_regex_width + 4,
        row = 0,
        zindex = 10,
    })
    local lightbox = CandelaWindow.new({
        relative = "win",
        width = pattern_ops_width,
        height = patterns.config.height - 2,
        style = "minimal",
        focusable = false,
        title = " L ",
        title_pos = "center",
        border = "solid",
        col = pattern_color_width + pattern_ops_width + pattern_regex_width + 6,
        row = 0,
        zindex = 10,
    })
    local prompt = CandelaWindow.new({
        relative = "win",
        width = total_width,
        height = prompt_height,
        style = "minimal",
        title_pos = "left",
        border = "rounded",
        col = -1,
        row = pattern_height + 1,
        zindex = 15,
    })

    CandelaUi.windows.patterns = patterns
    CandelaUi.windows.color = color
    CandelaUi.windows.regex = regex
    CandelaUi.windows.highlight = highlight
    CandelaUi.windows.lightbox = lightbox
    CandelaUi.windows.prompt = prompt

    -- TODO: handle resizing of window when vim is resized with autocmd

    for name, window in pairs(CandelaUi.windows) do
        window:ensure_buffer()
        vim.api.nvim_set_option_value("swapfile", false, { buf = window.buf })
        vim.api.nvim_set_option_value("filetype", "candela", { buf = window.buf })
        if name ~= "prompt" then
            vim.api.nvim_set_option_value("modifiable", false, { buf = window.buf })
        end
    end

    CandelaConfig.set_keymaps()
    CandelaConfig.set_patterns_keymaps(CandelaUi.windows.regex.buf)
    CandelaConfig.set_prompt_keymaps(CandelaUi.windows.prompt.buf)


    vim.api.nvim_create_autocmd("BufHidden", {
        group = candela_augroup,
        buffer = CandelaUi.windows.regex.buf,
        callback = function()
            CandelaUi.hide_patterns()
        end,
    })
end

-- Open patterns window
function CandelaUi.show_patterns()
    if CandelaUi.windows.regex:is_open() then
        return
    end

    if CandelaUi.windows.patterns == nil then
        vim.notify("Need patterns window to attach to", vim.log.levels.ERROR)
    end

    CandelaUi.windows.patterns:open_window() -- open patterns first to attach other windows

    for name, win in pairs(CandelaUi.windows) do
        if name ~= "patterns" then
            win:attach_to(CandelaUi.windows.patterns)
            if name == "regex" then
                win:open_window(true)
            elseif name ~= "prompt" then
                win:open_window()
            end
        end
    end
end

-- HACK: could probably make this better/clean up prompt window/buffer handling consolidate to one for patterns + prompt?
-- HACK: should probably split operations up into separate functions to reduce conditional processing/new file for operations?
---@param operation string: type of operation to conduct
function CandelaUi.show_prompt(operation)
    CandelaUi.windows.prompt:ensure_buffer()
    CandelaUi.windows.prompt:attach_to(CandelaUi.windows.patterns)
    vim.fn.prompt_setprompt(CandelaUi.windows.prompt.buf, " > ")
    vim.api.nvim_set_option_value("buftype", "prompt", { buf = CandelaUi.windows.prompt.buf })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = candela_augroup,
        buffer = CandelaUi.windows.prompt.buf,
        desc = "Start the user in insert mode upon entering prompt window",
        callback = function()
            vim.api.nvim_cmd( { cmd = "startinsert" }, {})
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = candela_augroup,
        buffer = CandelaUi.windows.prompt.buf,
        desc = "Ensure the regex window is focused after leaving prompt window",
        callback = function()
            CandelaUi.hide_prompt()
            vim.defer_fn(function ()
                vim.api.nvim_set_current_win(CandelaUi.windows.regex.win)
            end, 1)
        end,
    })
    vim.api.nvim_create_autocmd("QuitPre", {
        group = candela_augroup,
        desc = "Delete the prompt buffer right before quitting to prevent neovim asking to save prompt",
        callback = function()
            if CandelaUi.windows.prompt.buf and vim.api.nvim_buf_is_valid(CandelaUi.windows.prompt.buf) then
                vim.api.nvim_buf_delete(CandelaUi.windows.prompt.buf, { force = true })
            end
        end,
    })

    if operation == "add" then
        CandelaUi.windows.prompt.config.title = " Add Regex "
        vim.fn.prompt_setcallback(CandelaUi.windows.prompt.buf, function(regex)
            local new_pattern = CandelaPatternList.add(regex)
            if new_pattern ~= nil then
                CandelaUi.update_lines()
                CandelaUi.resize_height()
                CandelaUi.hide_prompt()
                --CandelaHighlighter.highlight_matches(CandelaUi.base_buf, new_pattern)
            end
        end)
        CandelaUi.windows.prompt:open_window(true)
    elseif operation == "edit" then
        if #CandelaPatternList.patterns == 0 then
            vim.notify("Must need at least one pattern to edit", vim.log.levels.ERROR)
            return
        end

        CandelaUi.windows.prompt.config.title = " Edit Regex "
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local curr_pattern = CandelaPatternList.get_pattern(curr_line)
        vim.schedule(function ()
            vim.api.nvim_paste(curr_pattern.regex, false, -1)
        end)

        vim.fn.prompt_setcallback(CandelaUi.windows.prompt.buf, function(regex)
            CandelaPatternList.edit(curr_line, regex)
            CandelaUi.update_lines()
            CandelaUi.hide_prompt()
        end)

        CandelaUi.windows.prompt:open_window(true)
    elseif operation == "copy" then
        CandelaUi.windows.prompt.config.title = " Copy Regex "
        if #CandelaPatternList.patterns == 0 then
            vim.notify("Must need at least one pattern to copy", vim.log.levels.ERROR)
            return
        end

        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local curr_pattern = CandelaPatternList.get_pattern(curr_line)
        vim.schedule(function ()
            vim.api.nvim_paste(curr_pattern.regex, false, -1)
        end)

        vim.fn.prompt_setcallback(CandelaUi.windows.prompt.buf, function(regex)
            CandelaPatternList.add(regex)
            CandelaUi.update_lines()
            CandelaUi.resize_height()
            CandelaUi.hide_prompt()
        end)

        CandelaUi.windows.prompt:open_window(true)
    elseif operation == "remove" then
        if #CandelaPatternList.patterns == 0 then
            vim.notify("Must need at least one pattern to remove", vim.log.levels.ERROR)
            return
        end

        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        CandelaPatternList.remove(curr_line)
        CandelaUi.update_lines()
        CandelaUi.resize_height() -- TODO: Shrink height if size decreases
    elseif operation == "change_color" then
        if #CandelaPatternList.patterns == 0 then
            vim.notify("Must need at least one pattern to change color", vim.log.levels.ERROR)
            return
        end

        CandelaUi.windows.prompt.config.title = " Change Color "
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local curr_pattern = CandelaPatternList.get_pattern(curr_line)
        vim.schedule(function ()
            vim.api.nvim_paste(curr_pattern.color, false, -1)
        end)

        vim.fn.prompt_setcallback(CandelaUi.windows.prompt.buf, function(color)
            CandelaPatternList.change_color(curr_line, color)
            CandelaUi.update_lines()
            CandelaUi.resize_height()
            CandelaUi.hide_prompt()
        end)

        CandelaUi.windows.prompt:open_window(true)
    elseif operation == "toggle_highlight" then
        if #CandelaPatternList.patterns == 0 then
            vim.notify("Must need at least one pattern to toggle highlight", vim.log.levels.ERROR)
            return
        end

        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        CandelaPatternList.toggle_highlight(curr_line)
        CandelaUi.update_lines()
    elseif operation == "toggle_lightbox" then
        if #CandelaPatternList.patterns == 0 then
            vim.notify("Must need at least one pattern to toggle lightbox", vim.log.levels.ERROR)
            return
        end

        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        CandelaPatternList.toggle_lightbox(curr_line)
        CandelaUi.update_lines()
    else
        vim.notify(string.format("Candela: invalid operation \"%s\"", operation))
    end
end

---@param name string: Field name
---@param field string|boolean: CandelaPattern[field]
---@return string: String to input into buffer lines
local function _format_field(name, field)
    if type(field) == "boolean" then
        return field and "  ✓  " or "  ✘  "
    elseif name == "regex" then
        return ("/" .. field .. "/") or ""
    else
        return field or ""
    end
end

-- Update lines of the patterns buffers
function CandelaUi.update_lines()
    local all_lines = {
        color = {},
        regex = {},
        highlight = {},
        lightbox = {},
    }

    for _, pattern in ipairs(CandelaPatternList.patterns) do
        for field, _ in pairs(all_lines) do
            table.insert(all_lines[field], _format_field(field, pattern[field]))
        end
    end

    for field, lines in pairs(all_lines) do
        vim.api.nvim_set_option_value("modifiable", true, { buf = CandelaUi.windows[field].buf })
        vim.api.nvim_buf_set_lines(CandelaUi.windows[field].buf, 0, -1, false, lines)
        vim.api.nvim_set_option_value("modifiable", false, { buf = CandelaUi.windows[field].buf })
    end
end

-- If the number of patterns in list exceeds the height of the current height, increase height of patterns windows
function CandelaUi.resize_height()
    local curr_height = vim.api.nvim_win_get_height(CandelaUi.windows.regex.win) -- Num of shown entries
    if #CandelaPatternList.patterns > curr_height then
        local new_height = math.min(CandelaUi.windows.patterns.config.height + 1, vim.o.lines - 6)
        local prompt_height = CandelaUi.windows.prompt.config.height
        local new_vert_center = math.floor((vim.o.lines - new_height - prompt_height - 2) / 2)
        CandelaUi.windows.patterns.config.row = new_vert_center
        CandelaUi.windows.patterns.config.height = new_height
        vim.api.nvim_win_set_config(CandelaUi.windows.patterns.win, CandelaUi.windows.patterns.config)

        for name, win in pairs(CandelaUi.windows) do
            if name ~= "prompt" and name ~= "patterns" then
                win.config.height = CandelaUi.windows.patterns.config.height - 2
                vim.api.nvim_win_set_config(win.win, win.config)
            end
        end
        CandelaUi.windows.prompt.config.row = CandelaUi.windows.patterns.config.height
        vim.api.nvim_win_set_config(CandelaUi.windows.prompt.win, CandelaUi.windows.prompt.config)
    end
end

function CandelaUi.hide_patterns()
    for name, win in pairs(CandelaUi.windows) do
        if name ~= "prompt" and win:is_open() then
            win:close_window()
        end
    end
end

function CandelaUi.hide_prompt()
    if CandelaUi.windows.prompt:is_open() then
        CandelaUi.windows.prompt:close_window()
        vim.api.nvim_buf_set_lines(CandelaUi.windows.prompt.buf, 0, -1, false, {})
    end
end

function CandelaUi.toggle()
    if CandelaUi.windows.prompt:is_open() then
        CandelaUi.hide_prompt()
    elseif CandelaUi.windows.regex:is_open() then
        CandelaUi.hide_patterns()
    else
        CandelaUi.show_patterns()
    end
end

return CandelaUi
