local M = {}

M.augroup = vim.api.nvim_create_augroup("Candela", { clear = false })

local initialized = false
local D = vim.log.levels.DEBUG

function M.set_ui_keymaps(buf)
    local function map(lhs, desc, callback)
        vim.api.nvim_buf_set_keymap(buf, "n", lhs, "", {
            noremap = true,
            silent = true,
            callback = callback,
            desc = desc,
        })
    end

    -- Close UI
    map("<ESC>", "[Candela] close UI", function()
        require("candela.ui").close()
    end)

    -- Toggle Highlight
    map("<C-h>", "[Candela] toggle highlight", function()
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
    end)

    -- Toggle Lightbox
    map("<C-l>", "[Candela] toggle lightbox", function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local regex = require("candela.patterns").resolve(row)
        if not regex then
            return
        end
        require("candela.patterns").toggle_lightbox(regex)
        require("candela.lightbox").update_folds()
        require("candela.highlighter").refresh_ui()
    end)

    -- Change color
    map("<C-c>", "[Candela] change color", function()
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
    end)

    -- Refresh
    map("<C-r>", "[Candela] refresh", function()
        require("candela.highlighter").refresh()
        require("candela.highlighter").refresh_ui()
    end)

    -- Import
    map("<C-i>", "[Candela] import", function()
        vim.ui.input({ prompt = "Import patterns from file: ", completion = "file" }, function(path)
            if path then
                require("candela.io").import(path)
            end
        end)
    end)

    -- Export
    map("<C-e>", "[Candela] export", function()
        local cd_io = require("candela.io")
        local default_path = cd_io.data_dir .. "/" .. cd_io.default_export_filename
        vim.ui.input(
            { prompt = "Export patterns to file: ", default = default_path, completion = "file" },
            function(path)
                if path then
                    require("candela.io").export(path)
                end
            end
        )
    end)
end

--- Trigger lazy initialization. Safe to call multiple times.
---@return boolean success
function M.ensure_init()
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

--- Optional. Call to override defaults before first use.
---@param opts? table user config overrides
function M.setup(opts)
    require("candela.config").setup(opts or {})
end

---@param args table vim command args from nvim_create_user_command
function M.cmd(args)
    if not M.ensure_init() then
        return
    end
    require("candela.commands").dispatch(args)
end

---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
function M.complete(arglead, cmdline, cursorpos)
    if not M.ensure_init() then
        return {}
    end
    return require("candela.commands").complete(arglead, cmdline, cursorpos)
end

return M
