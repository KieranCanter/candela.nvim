-- Module for initializing and manipulating the Candela buffers/windows

local CandelaPatternList = require("candela.pattern_list")

---@class CandelaUi
---@field patterns_buf number
---@field colors_buf number
---@field regex_buf number
---@field highlight_buf number
---@field lightbox_buf number
---@field prompt_buf number
---@field patterns_win number
---@field colors_win number
---@field regex_win number
---@field highlight_win number
---@field lightbox_win number
---@field prompt_win number
---@field win_configs table<string, vim.api.keyset.win_config>

local CandelaUi = {}

---@return CandelaUi
function CandelaUi:setup()
    CandelaUi.patterns_buf = nil
    CandelaUi.colors_buf = nil
    CandelaUi.regex_buf = nil
    CandelaUi.highlight_buf = nil
    CandelaUi.lightbox_buf = nil
    CandelaUi.prompt_buf = nil
    CandelaUi.patterns_win = nil
    CandelaUi.colors_win = nil
    CandelaUi.regex_win = nil
    CandelaUi.highlight_win = nil
    CandelaUi.lightbox_win = nil
    CandelaUi.prompt_win = nil

    local initial_height = 7 -- reasonable starting height TODO: make as a config option?
    CandelaUi.win_configs = CandelaUi.create_window_configurations(initial_height)

    -- TODO: handle resizing of window when vim is resized

    return CandelaUi
end

function CandelaUi.create_window_configurations(height) -- TODO: make window size config options?
    local win_width = vim.o.columns
    local win_height = vim.o.lines

    local float_width = math.floor(win_width * 0.50) -- total window width before borders
    local pattern_color_width = 9 -- 7 space hex code, 1 space margin on each side
    local pattern_ops_width = 5 -- 1 space letter/symbol, 2 space margin on each side
    -- fill rest of width with regex window, minus 2 for border (1 space on each side)
    local pattern_regex_width = float_width - pattern_color_width - (pattern_ops_width * 2) - 2

    local pattern_height = height -- starting height
    local prompt_height = 1 -- 1 space height for prompt
    local float_height = pattern_height + 2 -- + prompt_height + 2

    local total_width = float_width + 6 -- total window width after borders

    -- Account for 2 border spaces worth of padding to center window in center of base window
    local horz_center = math.floor((win_width - total_width - 2) / 2)
    local vert_center = math.floor((win_height - pattern_height - prompt_height - 2) / 2)

    return {
        patterns = {
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
        },
        colors = {
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
        },
        regex = {
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
        },
        highlight = {
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
        },
        lightbox = {
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
        },
        prompt = {
            relative = "win",
            width = total_width,
            height = prompt_height,
            style = "minimal",
            title_pos = "left",
            border = "rounded",
            col = -1,
            row = pattern_height + 1,
            zindex = 15,
        },
    }
end

-- Ensure buffers exist and are valid
function CandelaUi:ensure_buffers()
    if not CandelaUi.patterns_buf or not vim.api.nvim_buf_is_valid(CandelaUi.patterns_buf) then
        CandelaUi.patterns_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = CandelaUi.patterns_buf })
    end

    if not CandelaUi.colors_buf or not vim.api.nvim_buf_is_valid(CandelaUi.colors_buf) then
        CandelaUi.colors_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = CandelaUi.colors_buf })
    end

    if not CandelaUi.regex_buf or not vim.api.nvim_buf_is_valid(CandelaUi.regex_buf) then
        CandelaUi.regex_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = CandelaUi.regex_buf })
        vim.api.nvim_create_autocmd("BufHidden", {
            buffer = CandelaUi.regex_buf,
            callback = function()
                CandelaUi:close_windows()
            end,
        })
    end

    if not CandelaUi.highlight_buf or not vim.api.nvim_buf_is_valid(CandelaUi.highlight_buf) then
        CandelaUi.highlight_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = CandelaUi.highlight_buf })
    end

    if not CandelaUi.lightbox_buf or not vim.api.nvim_buf_is_valid(CandelaUi.lightbox_buf) then
        CandelaUi.lightbox_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = CandelaUi.lightbox_buf })
    end

    if not CandelaUi.prompt_buf or not vim.api.nvim_buf_is_valid(CandelaUi.prompt_buf) then
        CandelaUi.prompt_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[CandelaUi.prompt_buf].buftype = "prompt"

        vim.api.nvim_create_autocmd("BufEnter", {
            buffer = CandelaUi.prompt_buf,
            callback = function()
                vim.cmd("startinsert")
            end,
        })
        vim.api.nvim_create_autocmd("BufLeave", {
            buffer = CandelaUi.prompt_buf,
            callback = function()
                CandelaUi:close_prompt_window_and_buffer()
                vim.api.nvim_set_current_win(CandelaUi.regex_win)
            end,
        })
    end
end

-- Open windows based on config
---@param enter boolean: whether to enter the regex window on open or not
function CandelaUi:open_windows(enter)
    if CandelaUi:is_open() then
        return
    end

    CandelaUi:ensure_buffers()

    CandelaUi.patterns_win = vim.api.nvim_open_win(CandelaUi.patterns_buf, false, CandelaUi.win_configs.patterns)

    CandelaUi.win_configs.colors.win = CandelaUi.patterns_win
    CandelaUi.win_configs.regex.win = CandelaUi.patterns_win
    CandelaUi.win_configs.highlight.win = CandelaUi.patterns_win
    CandelaUi.win_configs.lightbox.win = CandelaUi.patterns_win

    CandelaUi.colors_win = vim.api.nvim_open_win(CandelaUi.colors_buf, false, CandelaUi.win_configs.colors)
    CandelaUi.regex_win = vim.api.nvim_open_win(CandelaUi.regex_buf, enter, CandelaUi.win_configs.regex)
    CandelaUi.highlight_win = vim.api.nvim_open_win(CandelaUi.highlight_buf, false, CandelaUi.win_configs.highlight)
    CandelaUi.lightbox_win = vim.api.nvim_open_win(CandelaUi.lightbox_buf, false, CandelaUi.win_configs.lightbox)
end

---@param operation string: one of (add|edit|copy)
function CandelaUi:set_prompt_window(operation)
    CandelaUi.win_configs.prompt.win = CandelaUi.patterns_win
    vim.fn.prompt_setprompt(CandelaUi.prompt_buf, " > ")

    if operation == "add" then
        CandelaUi.win_configs.prompt.title = " Add Regex "
        vim.fn.prompt_setcallback(CandelaUi.prompt_buf, function(regex)
            -- TODO: add(input) function to add new pattern
            -- TODO: update_window function
            CandelaPatternList.add(regex)
            print(vim.inspect(CandelaPatternList))
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    elseif operation == "edit" then
        CandelaUi.win_configs.prompt.title = " Edit Regex "
        -- TODO: curr_pattern = Candela.get_curr_pattern() to get currently selected pattern at the the time of edit
        -- TODO: append curr_pattern.regex to CandelaUi.prompt.buf lines
        vim.fn.prompt_setcallback(CandelaUi.prompt_buf, function(input)
            -- TODO: edit(curr_pattern, input) function to edit existing pattern's regex
            -- TODO: update_window function
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    elseif operation == "copy" then
        CandelaUi.win_configs.prompt.title = " Copy To "
        -- TODO: curr_pattern = Candela.get_curr_pattern() to get currently selected pattern at the the time of edit
        -- TODO: append curr_pattern.regex to CandelaUi.prompt.buf lines
        vim.fn.prompt_setcallback(CandelaUi.prompt_buf, function(input)
            -- TODO: add(input) function to edit existing pattern's regex
            -- TODO: update_window function
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    else
        vim.notify(string.format("Candela: invalid operation %s: must be one of (add|edit|copy)", operation))
    end
end

---@param operation string: one of (add|edit|copy)
function CandelaUi:display_prompt_window(operation)
    if not CandelaUi:is_open() then
        CandelaUi:open_windows(false)
    end
    CandelaUi:set_prompt_window(operation)
    CandelaUi.prompt_win = vim.api.nvim_open_win(CandelaUi.prompt_buf, true, CandelaUi.win_configs.prompt)
end

-- Check if the UI is open
function CandelaUi:is_open()
    return CandelaUi.regex_win and vim.api.nvim_win_is_valid(CandelaUi.regex_win)
end

-- Close all open windows
function CandelaUi:close_windows()
    if CandelaUi.patterns_win and vim.api.nvim_win_is_valid(CandelaUi.patterns_win) then
        vim.api.nvim_win_close(CandelaUi.patterns_win, true)
        CandelaUi.patterns_win = nil
    end

    if CandelaUi.colors_win and vim.api.nvim_win_is_valid(CandelaUi.colors_win) then
        vim.api.nvim_win_close(CandelaUi.colors_win, true)
        CandelaUi.colors_win = nil
    end

    if CandelaUi.regex_win and vim.api.nvim_win_is_valid(CandelaUi.regex_win) then
        vim.api.nvim_win_close(CandelaUi.regex_win, true)
        CandelaUi.regex_win = nil
    end

    if CandelaUi.highlight_win and vim.api.nvim_win_is_valid(CandelaUi.highlight_win) then
        vim.api.nvim_win_close(CandelaUi.highlight_win, true)
        CandelaUi.highlight_win = nil
    end

    if CandelaUi.lightbox_win and vim.api.nvim_win_is_valid(CandelaUi.lightbox_win) then
        vim.api.nvim_win_close(CandelaUi.lightbox_win, true)
        CandelaUi.lightbox_win = nil
    end
end

-- Close prompt window
function CandelaUi:close_prompt_window_and_buffer()
    if CandelaUi.prompt_win and vim.api.nvim_win_is_valid(CandelaUi.prompt_win) then
        vim.api.nvim_win_close(CandelaUi.prompt_win, true)
        vim.api.nvim_buf_delete(CandelaUi.prompt_buf, { force = true })
        CandelaUi.prompt_win = nil
        CandelaUi.prompt_buf = nil
    end
end

-- Toggle UI
function CandelaUi:toggle()
    if CandelaUi:is_open() then
        CandelaUi:close_windows()
    else
        CandelaUi:open_windows(true)
    end
end

return CandelaUi
