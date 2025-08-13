-- Module for initializing and manipulating Candela buffers/windows

---@class CandelaWindow
---@field buf number?
---@field win number?
---@field config vim.api.keyset.win_config
---@field attach_to fun(self: CandelaWindow, parent_window: CandelaWindow)
---@field ensure_buffer fun(self: CandelaWindow)
---@field is_open fun(self: CandelaWindow): boolean
---@field open_window fun(self: CandelaWindow, enter: boolean)
---@field hide_window fun(self: CandelaWindow)
---@field close_window fun(self: CandelaWindow)

local M = {}

---@param opts table<string, string|number|boolean>: search api-win_config in vim docs for valid keys/values
---@return CandelaWindow
function M.new(opts)
    local instance = {
        buf = nil,
        win = nil,
        config = vim.tbl_extend("force", {}, opts or {})
    }

    setmetatable(instance, { __index = M })
    return instance
end

---@param self CandelaWindow
---@param parent_window CandelaWindow
function M:attach_to(parent_window)
    if not parent_window:is_open() then
        vim.notify(
            string.format(
                "Cannot attach base window (win=%s, buf=%s) to parent window (win=%s, buf=%s) because it is not open",
                self.win, self.buf, parent_window.win, parent_window.buf),
            vim.log.levels.ERROR)
        return
    end

    self.config.win = parent_window.win
end

-- Ensure buffer exists and is valid
function M:ensure_buffer()
    if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
        self.buf = vim.api.nvim_create_buf(false, true)
    end
end

-- Check if the window is open
---@param self CandelaWindow
---@return boolean
function M:is_open()
    return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

-- Open windows based on config
---@param self CandelaWindow
---@param enter boolean?: defaults to false if not provided
function M:open_window(enter)
    if self:is_open() then
        return
    end

    self:ensure_buffer()
    enter = enter or false
    self.win = vim.api.nvim_open_win(self.buf, enter, self.config)
end

-- Hide window
---@param self CandelaWindow
function M:hide_window()
    if not self:is_open() then
        return
    end

    vim.api.nvim_win_hide(self.win)
end

-- Close window
---@param self CandelaWindow
function M:close_window()
    if not self:is_open() then
        return
    end

    vim.api.nvim_win_close(self.win, true)
    self.win = nil
end

return M
