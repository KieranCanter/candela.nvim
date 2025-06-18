-- Module for initializing and manipulating the user interface

local CandelaPatternList = require("candela.pattern_list")

---@class CandelaUi
---@field patterns_buf number|nil
---@field colors_buf number|nil
---@field regex_buf number|nil
---@field highlight_buf number|nil
---@field lightbox_buf number|nil
---@field prompt_buf number|nil
---@field patterns_win number|nil
---@field colors_win number|nil
---@field regex_win number|nil
---@field highlight_win number|nil
---@field lightbox_win number|nil
---@field prompt_win number|nil
---@field win_configs table<string, vim.api.keyset.win_config>

local CandelaUi = {}
local ui = {
    patterns_buf = nil,
    colors_buf = nil,
    regex_buf = nil,
    highlight_buf = nil,
    lightbox_buf = nil,
    prompt_buf = nil,
    patterns_win = nil,
    colors_win = nil,
    regex_win = nil,
    highlight_win = nil,
    lightbox_win = nil,
    prompt_win = nil,
    win_configs = {},
}

---@return CandelaUi
function CandelaUi.setup(opts)
    local initial_height = 7 -- reasonable starting height TODO: make as a config option?
    -- TODO: add more window sizing config options?
    ui.win_configs = CandelaUi.create_window_configurations(initial_height)

    -- TODO: handle resizing of window when vim is resized with autocmd

    return ui
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
function CandelaUi.ensure_buffers()
    if not ui.patterns_buf or not vim.api.nvim_buf_is_valid(ui.patterns_buf) then
        ui.patterns_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = ui.patterns_buf })
    end

    if not ui.colors_buf or not vim.api.nvim_buf_is_valid(ui.colors_buf) then
        ui.colors_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = ui.colors_buf })
    end

    if not ui.regex_buf or not vim.api.nvim_buf_is_valid(ui.regex_buf) then
        ui.regex_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = ui.regex_buf })
        vim.api.nvim_create_autocmd("BufHidden", {
            buffer = ui.regex_buf,
            callback = function()
                CandelaUi.close_windows()
            end,
        })
    end

    if not ui.highlight_buf or not vim.api.nvim_buf_is_valid(ui.highlight_buf) then
        ui.highlight_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = ui.highlight_buf })
    end

    if not ui.lightbox_buf or not vim.api.nvim_buf_is_valid(ui.lightbox_buf) then
        ui.lightbox_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("modifiable", false, { buf = ui.lightbox_buf })
    end

    if not ui.prompt_buf or not vim.api.nvim_buf_is_valid(ui.prompt_buf) then
        ui.prompt_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[ui.prompt_buf].buftype = "prompt"

        vim.api.nvim_create_autocmd("BufEnter", {
            buffer = ui.prompt_buf,
            callback = function()
                vim.cmd("startinsert")
            end,
        })
        vim.api.nvim_create_autocmd("BufLeave", {
            buffer = ui.prompt_buf,
            callback = function()
                CandelaUi.close_prompt_window_and_buffer()
                vim.api.nvim_set_current_win(ui.regex_win)
            end,
        })
    end
end

-- Open windows based on config
---@param enter boolean: whether to enter the regex window on open or not
function CandelaUi.open_windows(enter)
    if CandelaUi.is_open() then
        return
    end

    CandelaUi.ensure_buffers()

    ui.patterns_win = vim.api.nvim_open_win(ui.patterns_buf, false, ui.win_configs.patterns)

    ui.win_configs.colors.win = ui.patterns_win
    ui.win_configs.regex.win = ui.patterns_win
    ui.win_configs.highlight.win = ui.patterns_win
    ui.win_configs.lightbox.win = ui.patterns_win

    ui.colors_win = vim.api.nvim_open_win(ui.colors_buf, false, ui.win_configs.colors)
    ui.regex_win = vim.api.nvim_open_win(ui.regex_buf, enter, ui.win_configs.regex)
    ui.highlight_win = vim.api.nvim_open_win(ui.highlight_buf, false, ui.win_configs.highlight)
    ui.lightbox_win = vim.api.nvim_open_win(ui.lightbox_buf, false, ui.win_configs.lightbox)
end

---@param operation string: one of (add|edit|copy)
function CandelaUi.set_prompt_window(operation)
    ui.win_configs.prompt.win = ui.patterns_win
    vim.fn.prompt_setprompt(ui.prompt_buf, " > ")

    if operation == "add" then
        ui.win_configs.prompt.title = " Add Regex "
        vim.fn.prompt_setcallback(ui.prompt_buf, function(regex)
            -- TODO: add(input) function to add new pattern
            -- TODO: update_window function
            CandelaPatternList.add(regex)
            print(vim.inspect(CandelaPatternList.get()))
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    elseif operation == "edit" then
        ui.win_configs.prompt.title = " Edit Regex "
        -- TODO: curr_pattern = Candela.get_curr_pattern() to get currently selected pattern at the the time of edit
        -- TODO: append curr_pattern.regex to ui.prompt.buf lines
        vim.fn.prompt_setcallback(ui.prompt_buf, function(input)
            -- TODO: edit(curr_pattern, input) function to edit existing pattern's regex
            -- TODO: update_window function
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    elseif operation == "copy" then
        ui.win_configs.prompt.title = " New Regex From Existing "
        -- TODO: curr_pattern = Candela.get_curr_pattern() to get currently selected pattern at the the time of edit
        -- TODO: append curr_pattern.regex to ui.prompt.buf lines
        vim.fn.prompt_setcallback(ui.prompt_buf, function(input)
            -- TODO: add(input) function to edit existing pattern's regex
            -- TODO: update_window function
            vim.api.nvim_cmd({ cmd = "q" }, {})
        end)
    else
        vim.notify(string.format("Candela: invalid operation %s: must be one of (add|edit|copy)", operation))
    end
end

---@param operation string: one of (add|edit|copy)
function CandelaUi.display_prompt_window(operation)
    if not CandelaUi.is_open() then
        CandelaUi.open_windows(false)
    end
    CandelaUi.set_prompt_window(operation)
    ui.prompt_win = vim.api.nvim_open_win(ui.prompt_buf, true, ui.win_configs.prompt)
end

-- Check if the UI is open
function CandelaUi.is_open()
    return ui.regex_win and vim.api.nvim_win_is_valid(ui.regex_win)
end

-- Close all open windows
function CandelaUi.close_windows()
    if ui.patterns_win and vim.api.nvim_win_is_valid(ui.patterns_win) then
        vim.api.nvim_win_close(ui.patterns_win, true)
        ui.patterns_win = nil
    end

    if ui.colors_win and vim.api.nvim_win_is_valid(ui.colors_win) then
        vim.api.nvim_win_close(ui.colors_win, true)
        ui.colors_win = nil
    end

    if ui.regex_win and vim.api.nvim_win_is_valid(ui.regex_win) then
        vim.api.nvim_win_close(ui.regex_win, true)
        ui.regex_win = nil
    end

    if ui.highlight_win and vim.api.nvim_win_is_valid(ui.highlight_win) then
        vim.api.nvim_win_close(ui.highlight_win, true)
        ui.highlight_win = nil
    end

    if ui.lightbox_win and vim.api.nvim_win_is_valid(ui.lightbox_win) then
        vim.api.nvim_win_close(ui.lightbox_win, true)
        ui.lightbox_win = nil
    end
end

-- Close prompt window
function CandelaUi.close_prompt_window_and_buffer()
    if ui.prompt_win and vim.api.nvim_win_is_valid(ui.prompt_win) then
        vim.api.nvim_win_close(ui.prompt_win, true)
        vim.api.nvim_buf_delete(ui.prompt_buf, { force = true })
        ui.prompt_win = nil
        ui.prompt_buf = nil
    end
    CandelaUi.ensure_buffers()
end

-- Toggle Patterns window
function CandelaUi.toggle_patterns()
    if CandelaUi.is_open() then
        CandelaUi.close_windows()
    else
        CandelaUi.open_windows(true)
    end
end

return CandelaUi
