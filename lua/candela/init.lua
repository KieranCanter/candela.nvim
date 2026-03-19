local M = {}

M.augroup = vim.api.nvim_create_augroup("Candela", { clear = false })

local initialized = false
local D = vim.log.levels.DEBUG

local function ensure_init()
    if initialized then
        return true
    end

    local config = require("candela.config")
    if not config.options then
        config.setup({})
    end
    if not config.options then
        return false
    end

    if vim.g.candela_debug then
        vim.notify("[Candela] initialized, engine=" .. (config.options.engine.command or "nil"), D)
    end

    -- Setup /candela data directory if it doesn't exist (typically in ~/.local/share/nvim/candela)
    require("candela.io").ensure_data_dir()

    -- Wire UI on_write: compare buffer lines vs M.patterns
    local ui = require("candela.ui")
    ui.on_write = function()
        local patterns = require("candela.patterns")
        local hl = require("candela.highlighter")
        local buffer_lines = ui.get_lines()

        -- Build set of what's in the buffer
        local in_buffer = {}
        for _, regex in ipairs(buffer_lines) do
            in_buffer[regex] = true
        end

        -- Delete: in patterns but not in buffer
        for regex, _ in pairs(patterns.patterns) do
            if not in_buffer[regex] then
                hl.remove(regex)
                patterns.delete(regex)
            end
        end

        -- Add: in buffer but not in patterns
        for _, regex in ipairs(buffer_lines) do
            if not patterns.get(regex) then
                if patterns.add(regex) then
                    hl.highlight(regex)
                end
            end
        end

        hl.refresh_ui()
    end

    -- Buffer keymaps for data actions on the UI buffer
    ui.set_keymap("n", "<C-h>", function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local regex = require("candela.patterns").resolve(row)
        if not regex then
            return
        end
        local toggle = require("candela.patterns").toggle_highlight(regex)
        if toggle ~= nil then
            require("candela.highlighter").toggle_highlights(regex, toggle)
            require("candela.highlighter").refresh_ui()
        end
    end, "[Candela] toggle highlight")

    ui.set_keymap("n", "<C-l>", function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local regex = require("candela.patterns").resolve(row)
        if not regex then
            return
        end
        require("candela.patterns").toggle_lightbox(regex)
        require("candela.lightbox").update_folds()
        require("candela.highlighter").refresh_ui()
    end, "[Candela] toggle lightbox")

    ui.set_keymap("n", "<C-c>", function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local regex = require("candela.patterns").resolve(row)
        if not regex then
            return
        end
        local color = vim.fn.input({ prompt = "New color (name or #hex): " })
        if color == "" then
            return
        end
        local p = require("candela.patterns").change_color(regex, color)
        if p then
            require("candela.highlighter").update_color(regex)
            require("candela.highlighter").refresh_ui()
        end
    end, "[Candela] change color")

    ui.set_keymap("n", "<C-r>", function()
        require("candela.highlighter").refresh()
        require("candela.highlighter").refresh_ui()
    end, "[Candela] refresh")

    -- Set base_buf to current buffer at init time
    local cur = vim.api.nvim_get_current_buf()
    local cur_bt = vim.api.nvim_get_option_value("buftype", { buf = cur })
    local cur_name = vim.api.nvim_buf_get_name(cur)
    if cur_bt == "" and cur_name ~= "" then
        require("candela.highlighter").base_buf = cur
    end

    -- Track base buffer on BufEnter
    vim.api.nvim_create_autocmd("BufEnter", {
        group = M.augroup,
        callback = function(args)
            local bufnr = args.buf
            local bt = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
            local name = vim.api.nvim_buf_get_name(bufnr)
            local listed = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })
            if bt ~= "" or name == "" or not listed then
                return
            end

            require("candela.highlighter").base_buf = bufnr
            if vim.g.candela_debug then
                vim.notify("[Candela] base_buf set to " .. name, D)
            end

            if require("candela.config").options.matching.auto_refresh then
                require("candela.highlighter").refresh()
                require("candela.highlighter").refresh_ui()
            end
        end,
    })

    initialized = true
    return true
end

--- Trigger lazy initialization. Safe to call multiple times.
---@return boolean success
function M.ensure_init()
    return ensure_init()
end

--- Optional. Call to override defaults before first use.
---@param opts? table user config overrides
function M.setup(opts)
    require("candela.config").setup(opts or {})
end

---@param args table vim command args from nvim_create_user_command
function M.cmd(args)
    if not ensure_init() then
        return
    end
    require("candela.commands").dispatch(args)
end

---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
function M.complete(arglead, cmdline, cursorpos)
    if not ensure_init() then
        return {}
    end
    return require("candela.commands").complete(arglead, cmdline, cursorpos)
end

return M
