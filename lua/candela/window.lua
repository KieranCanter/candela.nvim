-- Module for initializing and manipulating Candela buffers/windows

---@class CandelaWindow
---@field buf number|nil
---@field win number|nil
---@field config vim.api.keyset.win_config

local CandelaWindow = {}

---@param opts table<string, string|number>: search api-win_config in vim docs for valid keys/values
---@return CandelaWindow
function CandelaWindow.new(opts)
    local instance = {
        buf = nil,
        win = nil,
        config = vim.tbl_extend("force", {}, opts or {})
    }

    return instance
end

---@param window CandelaWindow
---@param key string
---@param val string|number
function CandelaWindow.change_config(window, key, val)
    if not window or not window.config then
        vim.notify(string.format("Invalid window (win=%s, buf=%s) passed to change_config", window.win, window.buf)
            , vim.log.levels.ERROR)
        return
    end
    window.config[key] = val
end

---@param base_window CandelaWindow
---@param parent_window CandelaWindow
function CandelaWindow.attach_win(base_window, parent_window)
    if not CandelaWindow.is_open(parent_window) then
        vim.notify(
            string.format(
                "Cannot attach base window (win=%s, buf=%s) to parent window (win=%s, buf=%s) because it is not open",
                base_window.win, base_window.buf, parent_window.win, parent_window.buf),
            vim.log.levels.ERROR)
        return
    end

    base_window.config.win = parent_window.win
end

-- Ensure buffer exists and is valid
---@param window CandelaWindow
function CandelaWindow.ensure_buffer(window)
    if not window.buf or not vim.api.nvim_buf_is_valid(window.buf) then
        window.buf = vim.api.nvim_create_buf(false, true)
    end
end

-- Open windows based on config
---@param window CandelaWindow
---@param enter boolean=false
function CandelaWindow.open_window(window, enter)
    if CandelaWindow.is_open(window) then
        return
    end

    CandelaWindow.ensure_buffer(window)
    enter = enter or false
    window.win = vim.api.nvim_open_win(window.buf, enter, window.config)
end

-- Check if the window is open
---@param window CandelaWindow
---@return boolean
function CandelaWindow.is_open(window)
    return window.win ~= nil and vim.api.nvim_win_is_valid(window.win)
end

-- Close window
---@param window CandelaWindow
---@param close_buf boolean=false
function CandelaWindow.close_window(window, close_buf)
    if not CandelaWindow.is_open(window) then
        return
    end

    vim.api.nvim_win_close(window.win, true)
    window.win = nil

    close_buf = close_buf or false
    if close_buf then
        vim.api.nvim_buf_delete(window.buf, { force = true })
        window.buf = nil
    end
end

-- Toggle window
---@param window CandelaWindow
---@param enter boolean=false
---@param close_buf boolean=false
function CandelaWindow.toggle(window, enter, close_buf)
    if CandelaWindow.is_open(window) then
        close_buf = close_buf or false
        CandelaWindow.close_window(window, close_buf)
    else
        enter = enter or false
        CandelaWindow.open_window(window, enter)
    end
end

return CandelaWindow
