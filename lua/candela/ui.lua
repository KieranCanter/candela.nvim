local M = {}

M.buf = nil
M.win = nil
M.winconfig = nil
M.ns = vim.api.nvim_create_namespace("candela.ui")
M.on_write = nil

M.help_buf = nil
M.help_win = nil

---@type table<integer, integer>: row (1-index) -> extmark id
M.select_extmark_ids = {}

---@class Candela.Ui.Column
---@field width integer display width of the column
---@field header string title text for the window border

---@class Candela.Ui.ColumnInfo
---@field regex Candela.Ui.Column
---@field count Candela.Ui.Column
---@field color Candela.Ui.Column
---@field highlight Candela.Ui.Column
---@field lightbox Candela.Ui.Column
M.columns = nil

---@class Candela.Ui.Entry
---@field regex string
---@field color string
---@field count string
---@field highlight string
---@field lightbox string
---@field hl_group string

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

    require("candela").set_ui_keymaps(M.buf)
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

    -- Left/right fill for each column header (handles odd remainders)
    local function header_fills(col)
        local total = col.width - vim.fn.strdisplaywidth(col.header) - header_padding
        local left = math.floor(total / 2)
        return left, total - left
    end

    local color_left, color_right = header_fills(M.columns.color)
    local hl_left, hl_right = header_fills(M.columns.highlight)
    local lb_left, lb_right = header_fills(M.columns.lightbox)

    local count_str = M.columns.count.header
    local color_str = " " .. M.columns.color.header .. " " .. string.rep(" ", color_right)
    local hl_str = string.rep(" ", hl_left) .. " " .. M.columns.highlight.header .. " " .. string.rep(" ", hl_right)
    local lb_str = string.rep(" ", lb_left) .. " " .. M.columns.lightbox.header .. " "

    M.winconfig.title = {
        { string.rep(border_char, textoff), "FloatBorder" },
        { " " .. M.columns.regex.header .. " ", "Winbar" },
        { string.rep(border_char, regex_fill), "FloatBorder" },
        { count_str, "FloatBorder" },
        { string.rep(border_char, color_left), "FloatBorder" },
        { color_str, "Winbar" },
        { string.rep(" ", column_padding), "FloatBorder" },
        { hl_str, "Winbar" },
        { string.rep(" ", column_padding), "FloatBorder" },
        { lb_str, "Winbar" },
        { string.rep(border_char, lb_right), "FloatBorder" },
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
---@param entries Candela.Ui.Entry[]
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
    M.columns.count.width = 3
    for _, e in ipairs(entries) do
        M.columns.count.width = math.max(M.columns.count.width, #tostring(e.count) + 2)
    end
    M.columns.count.header = string.rep("─", M.columns.count.width)

    -- Apply decorations per line
    M.select_extmark_ids = {}
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
                { count_dec, "Comment" }, -- count
                { color_dec, e.hl_group }, -- color
                { " ", "Normal" },
                { hl_dec, hl_hlgroup }, -- highlight
                { " ", "Normal" },
                { lb_dec, lb_hlgroup }, -- lightbox
            },
            virt_text_pos = "right_align",
            invalidate = true,
        })

        -- Selection placeholder (empty, updated by toggle_selection)
        M.select_extmark_ids[i] = vim.api.nvim_buf_set_extmark(M.buf, M.ns, row, 0, {
            virt_text = {},
            virt_text_pos = "inline",
            right_gravity = false,
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

    -- Resize window
    local h = recalculate_height()
    M.resize(nil, h)
end

--- Render selection icons for all rows.
--- If selected_set is empty, clears all selection extmarks.
---@param selected_set table<string, boolean>
function M.render_selection(selected_set)
    if vim.tbl_isempty(selected_set) then
        M.clear_selection()
        return
    end
    local lines = vim.api.nvim_buf_get_lines(M.buf, 0, -1, false)
    for i, line in ipairs(lines) do
        M.toggle_selection(i, selected_set[line] or false)
    end
end

--- Update selection icon on a single row via stored extmark ID.
---@param row integer 1-indexed line number
---@param selected boolean
function M.toggle_selection(row, selected)
    local id = M.select_extmark_ids[row]
    if not id then
        return
    end
    local icons = require("candela.config").options.icons.selection
    local icon = selected and icons.toggle_on or icons.toggle_off
    icon = center(icon, vim.fn.strdisplaywidth(icon) + 2)
    local hl = selected and "Winbar" or "Comment"
    vim.api.nvim_buf_set_extmark(M.buf, M.ns, row - 1, 0, {
        id = id,
        virt_text = { { icon, hl } },
        virt_text_pos = "inline",
        right_gravity = false,
        invalidate = true,
    })
end

--- Clear all selection icons back to empty.
function M.clear_selection()
    for row, id in pairs(M.select_extmark_ids) do
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, row - 1, 0, {
            id = id,
            virt_text = {},
            virt_text_pos = "inline",
            right_gravity = false,
            invalidate = true,
        })
    end
end

local function ensure_help_buf()
    if M.help_buf and vim.api.nvim_buf_is_valid(M.help_buf) then
        return
    end

    local keymaps = {
        { "<ESC>, <C-C>", "Close UI" },
        { "<M-c>", "Change color" },
        { "<C-H>", "Toggle highlight" },
        { "<C-L>", "Toggle lightbox" },
        { "<M-l>", "Open lightbox" },
        { "<C-R>", "Refresh" },
        { "<C-I>", "Import patterns" },
        { "<C-E>", "Export patterns" },
        { "<Tab>", "Select and next" },
        { "<S-Tab>", "Select and prev" },
        { "<C-A>", "Select all" },
        { "<C-/>", "Vim match" },
        { "<C-Q>", "Send to location list" },
        { "g?", "Toggle help" },
    }

    local keymap_length = 12
    local fmt_string = vim.fn.printf("  %%-%ds  %%s", keymap_length)
    local lines = {}
    for _, km in ipairs(keymaps) do
        table.insert(lines, string.format(fmt_string, km[1], km[2]))
    end

    M.help_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(M.help_buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.help_buf })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = M.help_buf })

    local ns = vim.api.nvim_create_namespace("candela.help")
    for i = 0, #lines - 1 do
        vim.api.nvim_buf_set_extmark(M.help_buf, ns, i, 2, {
            end_col = keymap_length + 2,
            hl_group = "CursorLineNr",
        })
        vim.api.nvim_buf_set_extmark(M.help_buf, ns, i, keymap_length + 2, {
            end_col = #lines[i + 1],
            hl_group = "Title",
        })
    end

    local function close_help()
        if M.help_win and vim.api.nvim_win_is_valid(M.help_win) then
            vim.api.nvim_win_close(M.help_win, true)
            M.help_win = nil
        end
    end
    for _, key in ipairs({ "<ESC>", "<C-C>", "g?" }) do
        vim.api.nvim_buf_set_keymap(M.help_buf, "n", key, "", {
            noremap = true,
            silent = true,
            callback = close_help,
        })
    end
end

function M.help()
    if M.help_win and vim.api.nvim_win_is_valid(M.help_win) then
        vim.api.nvim_win_close(M.help_win, true)
        M.help_win = nil
        return
    end

    ensure_help_buf()

    local lines = vim.api.nvim_buf_get_lines(M.help_buf, 0, -1, false)
    local widest = 0
    for _, line in ipairs(lines) do
        widest = math.max(widest, vim.fn.strdisplaywidth(line))
    end

    local w = widest + 2
    local h = #lines
    M.help_win = vim.api.nvim_open_win(M.help_buf, true, {
        relative = "editor",
        width = w,
        height = h,
        col = math.floor((vim.o.columns - w) / 2),
        row = math.floor((vim.o.lines - h) / 2),
        style = "minimal",
        border = "rounded",
        title = { { " Candela Keymaps ", "Winbar" } },
        title_pos = "center",
    })
end

return M
