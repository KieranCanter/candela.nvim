-- Module for initializing and manipulating the Candela buffers/windows

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
---@field win_configs table<string, vim.api.keyset.win_config[]>

local CandelaUi = {}
CandelaUi.__index = CandelaUi

function CandelaUi:new()
    local ui = setmetatable({
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
    }, self)

    ui.win_configs = ui:create_window_configurations()
    return ui
end

function CandelaUi:create_window_configurations()
    local win_width = vim.o.columns
    local win_height = vim.o.lines

    local float_width = math.floor(win_width * 0.50) -- total window width before borders
    local pattern_color_width = 9 -- 7 space hex code, 1 space margin on each side
    local pattern_ops_width = 5 -- 1 space letter/symbol, 2 space margin on each side
    -- fill rest of width with regex window, minus 2 for border (1 space on each side)
    local pattern_regex_width = float_width - pattern_color_width - (pattern_ops_width * 2) - 2

    local pattern_height = 9 -- reasonable size to start patterns window
    local prompt_height = 1 -- 1 space height for prompt

    local total_width = float_width + 6 -- total window width after borders

    -- Account for 2 border spaces worth of padding to center window in center of base window
    local horz_center = math.floor((win_width - total_width - 2) / 2)
    local vert_center = math.floor((win_height - pattern_height - prompt_height - 2) / 2)

    return {
        patterns = {
            relative = "editor",
            width = total_width,
            height = pattern_height,
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
            height = pattern_height - 2,
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
            height = pattern_height - 2,
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
            height = pattern_height - 2,
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
            height = pattern_height - 2,
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
            title = " Add Regex ",
            title_pos = "left",
            border = "rounded",
            col = -1,
            row = pattern_height,
            zindex = 15,
        },
    }
end

-- Ensure buffers exist and are valid
function CandelaUi:ensure_buffers()
    if not self.patterns_buf or not vim.api.nvim_buf_is_valid(self.patterns_buf) then
        self.patterns_buf = vim.api.nvim_create_buf(false, true)
    end

    if not self.colors_buf or not vim.api.nvim_buf_is_valid(self.colors_buf ) then
        self.colors_buf = vim.api.nvim_create_buf(false, true)
    end

    if not self.regex_buf or not vim.api.nvim_buf_is_valid(self.regex_buf ) then
        self.regex_buf = vim.api.nvim_create_buf(false, true)
    end

    if not self.highlight_buf or not vim.api.nvim_buf_is_valid(self.highlight_buf ) then
        self.highlight_buf = vim.api.nvim_create_buf(false, true)
    end

    if not self.lightbox_buf or not vim.api.nvim_buf_is_valid(self.lightbox_buf ) then
        self.lightbox_buf = vim.api.nvim_create_buf(false, true)
    end

    if not self.prompt_buf or not vim.api.nvim_buf_is_valid(self.prompt_buf) then
        self.prompt_buf = vim.api.nvim_create_buf(false, true)
    end

end

-- Open windows based on config
function CandelaUi:open_windows()
    self:ensure_buffers()

    self.patterns_win = vim.api.nvim_open_win(self.patterns_buf, false, self.win_configs.patterns)

    self.win_configs.colors.win = self.patterns_win
    self.win_configs.regex.win = self.patterns_win
    self.win_configs.highlight.win = self.patterns_win
    self.win_configs.lightbox.win = self.patterns_win
    self.win_configs.prompt.win = self.patterns_win

    self.colors_win = vim.api.nvim_open_win(self.colors_buf, false, self.win_configs.colors)
    self.regex_win = vim.api.nvim_open_win(self.regex_buf, false, self.win_configs.regex)
    self.highlight_buf = vim.api.nvim_open_win(self.highlight_buf, false, self.win_configs.highlight)
    self.lightbox_buf = vim.api.nvim_open_win(self.lightbox_buf, false, self.win_configs.lightbox)
    self.prompt_win = vim.api.nvim_open_win(self.prompt_buf, true, self.win_configs.prompt)
end

-- Check if the UI is open
function CandelaUi:is_open()
    return self.prompt_win and vim.api.nvim_win_is_valid(self.prompt_win)
end

-- Close all open windows
function CandelaUi:close_windows()
    if self.patterns_win and vim.api.nvim_win_is_valid(self.patterns_win) then
        vim.api.nvim_win_close(self.patterns_win, true)
        self.patterns_win = nil
    end

    if self.colors_win and vim.api.nvim_win_is_valid(self.colors_win) then
        vim.api.nvim_win_close(self.colors_win , true)
        self.colors_win = nil
    end

    if self.regex_win and vim.api.nvim_win_is_valid(self.regex_win) then
        vim.api.nvim_win_close(self.regex_win , true)
        self.regex_win = nil
    end

    if self.highlight_win and vim.api.nvim_win_is_valid(self.highlight_win) then
        vim.api.nvim_win_close(self.highlight_win , true)
        self.highlight_win = nil
    end

    if self.lightbox_win and vim.api.nvim_win_is_valid(self.lightbox_win) then
        vim.api.nvim_win_close(self.lightbox_win, true)
        self.lightbox_win = nil
    end

    if self.prompt_win and vim.api.nvim_win_is_valid(self.prompt_win) then
        vim.api.nvim_win_close(self.prompt_win, true)
        self.prompt_win = nil
    end
end

-- Toggle UI
function CandelaUi:toggle()
    if self:is_open() then
        self:close_windows()
    else
        self:open_windows()
    end
end

return CandelaUi
