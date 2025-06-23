-- Module for initializing and manipulating the user interface

local CandelaPatternList = require("candela.pattern_list")
local CandelaWindow = require("candela.window")
local candela_group = vim.api.nvim_create_augroup("Candela", { clear = true })

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
    local colors = CandelaWindow.new({
        relative = "win",
        width = pattern_color_width,
        height = pattern_height,
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
        height = pattern_height,
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
        height = pattern_height,
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
        height = pattern_height,
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
    CandelaUi.windows.colors = colors
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

    vim.api.nvim_create_autocmd("BufHidden", {
        group = candela_group,
        buffer = CandelaUi.windows.regex.buf,
        callback = function()
            CandelaUi.hide_patterns()
        end,
    })
end

-- Open patterns window
function CandelaUi.show_patterns()
    if CandelaUi._is_open() then
        return
    end

    if CandelaUi.windows.patterns == nil then
        vim.notify("Need patterns window to attach to", vim.log.levels.ERROR)
    end
    CandelaUi.windows.patterns:open_window() -- open patterns first to attach other windows

    for name, win in pairs(CandelaUi.windows) do
        if name ~= "patterns" and name ~= "prompt" then
            win:attach_to(CandelaUi.windows.patterns)
            if name == "regex" then
                win:open_window(true)
            else
                win:open_window()
            end
        end
    end
end

-- HACK: could probably make this better?
-- HACK: REFACTOR PROMPT WINDOW TO NOT DELETE BUFFER BUT INSTEAD JUST WIPE THE BUFFER CONTENT
---@param operation "add"|"edit"|"copy": type of operation to conduct
function CandelaUi.show_prompt(operation)
    CandelaUi.windows.prompt:ensure_buffer()
    CandelaUi.windows.prompt:attach_to(CandelaUi.windows.patterns)
    vim.api.nvim_set_option_value("buftype", "prompt", { buf = CandelaUi.windows.prompt.buf })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = candela_group,
        buffer = CandelaUi.windows.prompt.buf,
        callback = function()
            vim.fn.prompt_setprompt(CandelaUi.windows.prompt.buf, " > ")
            vim.api.nvim_cmd( { cmd = "startinsert" }, {})
        end,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
        group = candela_group,
        buffer = CandelaUi.windows.prompt.buf,
        callback = function()
            CandelaUi.hide_prompt()
            vim.api.nvim_set_current_win(CandelaUi.windows.regex.win)
        end,
    })

    if operation == "add" then
        CandelaUi.windows.prompt.config.title = " Add Regex "
        vim.fn.prompt_setcallback(CandelaUi.windows.prompt.buf, function(regex)
            -- TODO: add(input) function to add new pattern
            -- TODO: update_window function
            CandelaPatternList.add(regex)
            print(vim.inspect(CandelaPatternList.get()))
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    elseif operation == "edit" then
        CandelaUi.windows.prompt.config.title = " Edit Regex "
        -- TODO: curr_pattern = Candela.get_curr_pattern() to get currently selected pattern at the the time of edit
        -- TODO: append curr_pattern.regex to ui.prompt.buf lines
        vim.fn.prompt_setcallback(CandelaUi.windows.prompt.buf, function(input)
            -- TODO: edit(curr_pattern, input) function to edit existing pattern's regex
            -- TODO: update_window function
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    elseif operation == "copy" then
        CandelaUi.windows.prompt.config.title = " New Regex from Existing "
        -- TODO: curr_pattern = Candela.get_curr_pattern() to get currently selected pattern at the the time of edit
        -- TODO: append curr_pattern.regex to ui.prompt.buf lines
        vim.fn.prompt_setcallback(CandelaUi.windows.prompt.buf, function(input)
            -- TODO: add(input) function to edit existing pattern's regex
            -- TODO: update_window function
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    else
        vim.notify(string.format("Candela: invalid operation \"%s\": must be one of (add|edit|copy)", operation))
    end
    CandelaUi.windows.prompt:open_window(true)
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
        CandelaUi.windows.prompt:close_window(true)
    end
end

function CandelaUi.toggle()
    if CandelaUi._is_open() then
        CandelaUi.hide_prompt()
        CandelaUi.hide_patterns()
    else
        CandelaUi.show_patterns()
    end
end

---@return boolean
function CandelaUi._is_open()
    for _, window in pairs(CandelaUi.windows) do
        if window:is_open() then
            return true
        end
    end

    return false
end

return CandelaUi
