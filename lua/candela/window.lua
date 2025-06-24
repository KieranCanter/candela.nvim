-- Module for initializing and manipulating Candela buffers/windows

---@class CandelaWindow
---@field buf number|nil
---@field win number|nil
---@field config vim.api.keyset.win_config

local CandelaWindow = {}

---@param opts table<string, string|number|boolean>: search api-win_config in vim docs for valid keys/values
---@return CandelaWindow
function CandelaWindow.new(opts)
    local instance = {
        buf = nil,
        win = nil,
        config = vim.tbl_extend("force", {}, opts or {})
    }

    setmetatable(instance, { __index = CandelaWindow })
    return instance
end

---@param key string
---@param val string|number
function CandelaWindow:change_config(key, val)
    if not self or not self.config then
        vim.notify(string.format("Invalid window (win=%s, buf=%s) passed to change_config", self.win, self.buf)
            , vim.log.levels.ERROR)
        return
    end
    self.config[key] = val
end

---@param parent_window CandelaWindow
function CandelaWindow:attach_to(parent_window)
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
function CandelaWindow:ensure_buffer()
    if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
        self.buf = vim.api.nvim_create_buf(false, true)
    end
end

-- Open windows based on config
---@param enter boolean=false
function CandelaWindow:open_window(enter)
    if self:is_open() then
        return
    end

    self:ensure_buffer()
    enter = enter or false
    self.win = vim.api.nvim_open_win(self.buf, enter, self.config)
end

-- Check if the window is open
---@return boolean
function CandelaWindow:is_open()
    return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

-- Close window
function CandelaWindow:close_window()
    if not self:is_open() then
        return
    end

    vim.api.nvim_win_close(self.win, true)
    self.win = nil
end

-- Toggle window
---@param enter boolean=false
function CandelaWindow:toggle(enter)
    if self:is_open() then
        self:close_window()
    else
        enter = enter or false
        self:open_window(enter)
    end
end

return CandelaWindow
