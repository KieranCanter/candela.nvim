local M = {}

M.buf = nil
M.win = nil
M.winconfig = nil
M.ns = vim.api.nvim_create_namespace("candela.ui")
M.on_write = nil

---@class Column
---@field width integer display width of the column
---@field header string title text for the window border

---@class ColumnInfo
---@field regex Column
---@field count Column
---@field color Column
---@field highlight Column
---@field lightbox Column
M.columns = nil

local INITIALIZED = false
local USER_RELATIVENUMBER = vim.o.relativenumber

local function is_open()
    return M.win ~= nil and vim.api.nvim_win_is_valid(M.win)
end

local function recalculate_width()
    local opts = require("candela.config").options.window
    return math.min(math.floor(vim.o.columns * opts.width), vim.o.columns - opts.margin)
end

local function recalculate_height()
    local opts = require("candela.config").options.window
    local line_count = M.buf and vim.api.nvim_buf_is_valid(M.buf) and vim.api.nvim_buf_line_count(M.buf) or 0
    local margin_height = vim.o.lines - opts.margin
    local height = line_count
    if margin_height > opts.min_height then
        height = math.max(line_count, opts.min_height)
        height = math.min(height, opts.max_height, margin_height)
    else
        height = opts.min_height
    end
    return height
end

local function ensure_init()
    if INITIALIZED then
        return
    end
    INITIALIZED = true

    local augroup = require("candela").augroup

    M.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(M.buf, "candela://patterns")

    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = M.buf })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = M.buf })
    -- Disable indentations options, we don't want accidental indention if the user defines a regex that happens to be
    -- an identifier like `else`
    vim.api.nvim_set_option_value("indentexpr", "", { buf = M.buf })
    vim.api.nvim_set_option_value("smartindent", false, { buf = M.buf })
    vim.api.nvim_set_option_value("autoindent", false, { buf = M.buf })
    vim.api.nvim_set_option_value("formatoptions", "", { buf = M.buf })

    local icons = require("candela.config").options.icons
    local regex_header = icons.regex .. " Regex"
    local count_width = 3
    M.columns = {
        regex = { width = vim.fn.strdisplaywidth(regex_header) + 2, header = regex_header }, -- add 2 for padding
        count = { width = count_width, header = string.rep("─", count_width) },
        color = { width = 11, header = icons.color .. " Color" },
        highlight = { width = 7, header = icons.highlight.header .. " HL" },
        lightbox = { width = 7, header = icons.lightbox.header .. " LB" },
    }

    local w = recalculate_width()
    local h = recalculate_height()
    M.winconfig = {
        relative = "editor",
        width = w,
        height = h,
        style = "minimal",
        col = math.floor((vim.o.columns - w) / 2),
        row = math.floor((vim.o.lines - h) / 2),
        border = "rounded",
        footer = { { " " .. icons.candela .. " Candela ", "Winbar" } },
        footer_pos = "center",
    }

    -- Invoke regex on-write
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

    vim.api.nvim_create_autocmd("VimResized", {
        group = augroup,
        callback = function()
            M.resize(recalculate_width(), recalculate_height())
        end,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = augroup,
        buffer = M.buf,
        callback = function()
            if not is_open() then
                return
            end
            local height = recalculate_height()
            if height ~= M.winconfig.height then
                M.resize(nil, height)
            end
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

local function set_window_options()
    vim.api.nvim_set_option_value("wrap", false, { win = M.win })
    vim.api.nvim_set_option_value("signcolumn", "no", { win = M.win })
    vim.api.nvim_set_option_value("number", true, { win = M.win })
    vim.api.nvim_set_option_value("relativenumber", USER_RELATIVENUMBER or false, { win = M.win })
    vim.api.nvim_set_option_value("cursorline", true, { win = M.win })
end

local function center(str, width, fillchar)
    fillchar = fillchar or " "
    local pad = width - vim.fn.strdisplaywidth(str)
    local left = math.floor(pad / 2)
    return string.rep(fillchar, left) .. str .. string.rep(fillchar, pad - left)
end

local function build_title()
    if not M.columns then
        return
    end
    local border_char = "─"
    local textoff = 3

    local meta_width = textoff + 2 -- add 2 for padding between color, hl, and lb columns
    for _, col in pairs(M.columns) do
        meta_width = meta_width + col.width
    end
    local regex_fill = math.max(M.winconfig.width - meta_width, 0)

    -- Create fill chars for spacing
    -- * header_padding accounts for the combined padding on the left and right side
    -- * column_padding accounts for the padding in between columns (i.e. between color, hl, and lb columns)
    local header_padding = 2
    local column_padding = 1

    -- These represent the padding for one side of each column header
    local color_fill_one_side = (
        M.columns.color.width
        - vim.fn.strdisplaywidth(M.columns.color.header)
        - header_padding
    ) / 2
    local hl_fill_one_side = (
        M.columns.highlight.width
        - vim.fn.strdisplaywidth(M.columns.highlight.header)
        - header_padding
    ) / 2
    local lb_fill_one_side = (
        M.columns.lightbox.width
        - vim.fn.strdisplaywidth(M.columns.lightbox.header)
        - header_padding
    ) / 2

    M.winconfig.title = {
        { string.rep(border_char, textoff), "FloatBorder" },
        { " " .. M.columns.regex.header .. " ", "Winbar" },
        { string.rep(border_char, regex_fill), "FloatBorder" },
        { M.columns.count.header, "FloatBorder" },
        { string.rep(border_char, color_fill_one_side), "FloatBorder" },
        { " " .. M.columns.color.header .. " ", "Winbar" },
        { string.rep(" ", color_fill_one_side + hl_fill_one_side + column_padding), "FloatBorder" },
        { " " .. M.columns.highlight.header .. " ", "Winbar" },
        { string.rep(" ", hl_fill_one_side + lb_fill_one_side + column_padding), "FloatBorder" },
        { " " .. M.columns.lightbox.header .. " ", "Winbar" },
        { string.rep(border_char, lb_fill_one_side), "FloatBorder" },
    }
end

---@param width? integer
---@param height? integer
function M.resize(width, height)
    M.winconfig.width = width or M.winconfig.width
    M.winconfig.height = height or M.winconfig.height
    M.winconfig.col = math.floor((vim.o.columns - M.winconfig.width) / 2)
    M.winconfig.row = math.floor((vim.o.lines - M.winconfig.height) / 2)
    build_title()
    if is_open() then
        vim.api.nvim_win_set_config(M.win, M.winconfig)
        set_window_options()
    end
end

function M.open()
    ensure_init()
    if is_open() then
        return
    end

    -- Capture user's setting before opening (style=minimal will reset it)
    USER_RELATIVENUMBER = vim.o.relativenumber

    require("candela.highlighter").refresh_ui()

    M.win = vim.api.nvim_open_win(M.buf, true, M.winconfig)
    set_window_options()
end

function M.close()
    if M.win and vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_close(M.win, true)
        M.win = nil
    end
end

function M.toggle()
    if is_open() then
        M.close()
    else
        M.open()
    end
end

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

--- Render pattern entries: builds buffer lines, decorations, title from data.
---@param entries {regex: string, color: string, count: integer, highlight: boolean, lightbox: boolean, hl_group: string}[]
function M.render(entries)
    ensure_init()
    local icons = require("candela.config").options.icons

    -- Build buffer lines
    local lines = {}
    for _, e in ipairs(entries) do
        table.insert(lines, e.regex)
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = M.buf })
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modified", false, { buf = M.buf })

    vim.api.nvim_buf_clear_namespace(M.buf, M.ns, 0, -1)

    -- Dynamic count width
    for _, e in ipairs(entries) do
        M.columns.count.width = math.max(M.columns.count.width, #tostring(e.count) + 2)
        M.columns.count.header = string.rep("─", M.columns.count.width)
    end

    -- Apply decorations per line
    for i, e in ipairs(entries) do
        local row = i - 1
        local hl_icon = e.highlight and icons.highlight.toggle_on or icons.highlight.toggle_off
        local lb_icon = e.lightbox and icons.lightbox.toggle_on or icons.lightbox.toggle_off
        local hl_hlgroup = e.highlight and e.hl_group or "Normal"
        local lb_hlgroup = e.lightbox and e.hl_group or "Normal"

        local count_dec = string.format(" %" .. M.columns.count.width - 2 .. "d ", e.count)
        local color_dec = center(e.color, M.columns.color.width)
        local hl_dec = center(hl_icon, M.columns.highlight.width)
        local lb_dec = center(lb_icon, M.columns.lightbox.width)

        -- Right-aligned: count, color, toggles
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, row, 0, {
            virt_text = {
                { count_dec, "Comment" }, -- Count
                { color_dec, e.hl_group }, -- Color
                { " ", "Normal" },
                { hl_dec, hl_hlgroup }, -- Highlight
                { " ", "Normal" },
                { lb_dec, lb_hlgroup }, -- Lightbox
            },
            virt_text_pos = "right_align",
            invalidate = true,
        })

        -- Inline /regex/ slashes
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, row, 0, {
            virt_text = { { "/", "Comment" } },
            virt_text_pos = "inline",
            right_gravity = false,
            invalidate = true,
        })
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, row, #lines[i], {
            virt_text = { { "/", "Comment" } },
            virt_text_pos = "inline",
            invalidate = true,
        })
    end

    build_title()

    -- Resize window
    local h = recalculate_height()
    M.resize(nil, h)
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
