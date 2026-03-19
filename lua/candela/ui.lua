local M = {}

M.buf = nil
M.win = nil
M.winconfig = nil
M.ns = vim.api.nvim_create_namespace("candela.ui")
M.on_write = nil

local initialized = false

local function ensure_init()
    if initialized then
        return
    end
    initialized = true

    local augroup = require("candela").augroup

    M.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(M.buf, "candela://patterns")
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = M.buf })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = M.buf })

    -- Setup initial window configuration
    local w = math.min(math.floor(vim.o.columns * 0.5), vim.o.columns - 16)
    local line_count = vim.api.nvim_buf_line_count(M.buf)
    local h = math.max(line_count, 5)
    h = math.min(h, 30)
    M.winconfig = {
        relative = "editor",
        width = w,
        height = h,
        col = math.floor((vim.o.columns - w) / 2),
        row = math.floor((vim.o.lines - h) / 2),
        border = "rounded",
        title = " Candela ",
        title_pos = "center",
    }

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        group = augroup,
        buffer = M.buf,
        callback = function()
            if M.on_write then
                M.on_write()
            end
            vim.api.nvim_set_option_value("modified", false, { buf = M.buf })
        end,
    })

    vim.api.nvim_buf_set_keymap(M.buf, "n", "<ESC>", "", {
        noremap = true,
        silent = true,
        callback = function()
            M.close()
        end,
    })
end

function M.is_open()
    return M.win ~= nil and vim.api.nvim_win_is_valid(M.win)
end

function M.open()
    ensure_init()
    if M.is_open() then
        return
    end

    M.win = vim.api.nvim_open_win(M.buf, true, M.winconfig)

    vim.api.nvim_set_option_value("wrap", false, { win = M.win })
    vim.api.nvim_set_option_value("number", false, { win = M.win })
    vim.api.nvim_set_option_value("signcolumn", "no", { win = M.win })
end

function M.close()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_close(M.win, true)
        M.win = nil
    end
end

function M.toggle()
    if M.is_open() then
        M.close()
    else
        M.open()
    end
end

--- Get current buffer lines (skipping only truly empty lines).
---@return string[]
function M.get_lines()
    ensure_init()
    local result = {}
    for _, line in ipairs(vim.api.nvim_buf_get_lines(M.buf, 0, -1, false)) do
        if line ~= "" then
            table.insert(result, line)
        end
    end
    return result
end

--- Overwrite buffer with given lines.
---@param lines string[]
function M.render(lines)
    ensure_init()
    vim.api.nvim_set_option_value("modifiable", true, { buf = M.buf })
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modified", false, { buf = M.buf })
end

function M.set_keymap(mode, lhs, callback, desc)
    ensure_init()
    vim.api.nvim_buf_set_keymap(M.buf, mode, lhs, "", {
        noremap = true,
        silent = true,
        desc = desc,
        callback = callback,
    })
end

return M
