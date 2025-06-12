--[[
--  Candela regex highlighter
--
--  * List of patterns
--    * Add pattern
--    * Remove pattern
--    * Show patterns
--    * Clear patterns
--  * Pattern
--    * Change color
--    * Toggle highlighting
--    * Toggle pattern showing up in lightbox
--]]

---@class CandelaPattern
---@field regex string
---@field color string
---@field highlight boolean
---@field lightbox boolean

---@class CandelaUi
---@field patterns CandelaPattern[]
---@field floats vim.api.keyset.win_config[]

local CandelaUi = {}

local M = {}
local ns_candela_highlighting = vim.api.nvim_create_namespace("candela_highlighting")

function M.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(opts)
        local args = opts.fargs
        local subcommand = args[1]
        local tail = table.concat(vim.list_slice(args, 2), " ")

        if subcommand == "" or subcommand == nil then
            require("candela").show()
        elseif subcommand == "add" then
            require("candela").add(tail)
        elseif subcommand == "remove" then
            require("candela").remove(tail)
        elseif subcommand == "clear" then
            require("candela").clear()
        else
            vim.notify("Candela: unsupported command: " .. subcommand, vim.log.levels.ERROR)
        end
    end, {
        nargs = "*",
        desc = "Regex highlighter",
        complete = function(_, line)
            local completions = { "add", "clear", "remove" }
            local split = vim.split(line, " ")
            if #split == 2 then
                return vim.tbl_filter(function(c)
                    return vim.startswith(c, split[2])
                end, completions)
            end
            return {}
        end,
    })
    M.base_buf = vim.api.nvim_get_current_buf()
    M.patterns = {}
    M.floats = {}

    M.pat_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.pat_buf].bufhidden = "hide"
    vim.bo[M.pat_buf].buflisted = false
    vim.bo[M.pat_buf].buftype = "nofile"
    vim.bo[M.pat_buf].modifiable = true

    vim.api.nvim_buf_set_keymap(
        M.pat_buf,
        "n",
        "q",
        "<cmd>hide<CR>",
        { noremap = true, silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        M.pat_buf,
        "n",
        "<Esc>",
        "<cmd>hide<CR>",
        { noremap = true, silent = true }
    )

    print("Candela loaded")
end

function _list_patterns()
    local lines = {}
    for pat, opts in pairs(M.patterns) do
        table.insert(lines, pat.regex)
    end

    return lines
end

function M:create_window_configurations()
    local win_width = vim.o.columns
    local win_height = vim.o.lines

    local float_width = math.floor(win_width * 0.50)

    local pattern_color_width = 9
    local pattern_ops_width = 5
    local pattern_regex_width = float_width - pattern_color_width - (pattern_ops_width * 2) - 2
    local pattern_height = math.max(#M.patterns, 9)
    local operation_height = 1

    local total_width = float_width + 6

    -- Account for 2 border spaces worth of padding
    local horz_center = math.floor((win_width - total_width - 2) / 2)
    local vert_center = math.floor((win_height - pattern_height - operation_height - 2) / 2)

    return {
        patterns = {
            relative = "editor",
            width = total_width,
            height = pattern_height,
            style = "minimal",
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
            title = " L ",
            title_pos = "center",
            border = "solid",
            col = pattern_color_width + pattern_ops_width + pattern_regex_width + 6,
            row = 0,
            zindex = 10,
        },
        operation = {
            relative = "win",
            width = total_width,
            height = operation_height,
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

local _foreach_float = function(callback)
    for name, float in pairs(M.floats) do
        callback(name, float)
    end
end

function M:create_float(config, enter)
    if enter == nil then
        enter = false
    end

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, enter or false, config)

    return { buf = buf, win = win }
end

function M.close_all_windows()
    _foreach_float(function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
    end)
end

function M.show()
    M.close_all_windows()

    local windows = M:create_window_configurations()

    M.floats.patterns = M:create_float(windows.patterns)

    windows.colors.win = M.floats.patterns.win
    M.floats.colors = M:create_float(windows.colors)
    windows.regex.win = M.floats.patterns.win
    M.floats.regex = M:create_float(windows.regex)
    windows.highlight.win = M.floats.patterns.win
    M.floats.highlight = M:create_float(windows.highlight)
    windows.lightbox.win = M.floats.patterns.win
    M.floats.lightbox = M:create_float(windows.lightbox)

    windows.operation.win = M.floats.patterns.win
    M.floats.operation = M:create_float(windows.operation, true)
    vim.bo[M.floats.operation.buf].buftype = "prompt"
    vim.bo[M.floats.operation.buf].swapfile = false
    vim.bo[M.floats.operation.buf].bufhidden = "wipe"
    vim.fn.prompt_setcallback(M.floats.operation.buf, M.add_and_show)
    vim.fn.prompt_setprompt(M.floats.operation.buf, " > ")

    if #M.patterns > 0 then
        for i, pattern in ipairs(M.patterns) do
            vim.api.nvim_buf_set_lines(M.floats.colors.buf, i, i, false, { pattern.color })
            vim.api.nvim_buf_set_lines(M.floats.regex.buf, i, i, false, { "/" .. pattern.regex .. "/" })
            vim.api.nvim_buf_set_lines(M.floats.highlight.buf, i, i, false, { tostring(pattern.highlight) })
            vim.api.nvim_buf_set_lines(M.floats.lightbox.buf, i, i, false, { tostring(pattern.lightbox) })
        end
    end

    vim.keymap.set("n", "q", function()
        M.close_all_windows()
    end)
    vim.keymap.set("n", "<esc>", function()
        M.close_all_windows()
    end)

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = M.floats.operation.buf,
        callback = function()
            M.close_all_windows()
        end,
    })

    vim.api.nvim_create_autocmd("VimResized", {
        group = vim.api.nvim_create_augroup("candela-resized", {}),
        callback = function()
            if not vim.api.nvim_win_is_valid(M.floats.regex.win) or M.floats.regex.win == nil then
                return
            end

            local updated = M:create_window_configurations()
            _foreach_float(function(name, _)
                vim.api.nvim_win_set_config(M.floats[name].win, updated[name])
            end)
        end,
    })

    vim.notify("Candela: show patterns")
end

function M.highlight(bufnr, regex)
    -- FIX: temporarily hardcoding highlight group
    vim.api.nvim_set_hl(bufnr, "candela_hl_1", {
        fg = "#FF7777",
        bg = "#AA0000",
        bold = true,
    })
    -- TODO: implement highlight
end

function M.add_and_show(regex)
    M.add(regex)
    M.show()
end

function M.add(regex)
    if regex == "" or regex == nil then
        vim.notify("Candela: no pattern entered")
        return
    end

    if #M.patterns > 0 then
        for i, pattern in ipairs(M.patterns) do
            if pattern.regex == regex then
                vim.notify("Candela: pattern /" .. regex .. "/ already exists")
                return
            end
        end
    end

    new_pattern = {
        regex = regex,
        color = "#FF0000",
        highlight = true,
        lightbox = true,
    }
    table.insert(M.patterns, new_pattern)

    vim.notify("Candela: added pattern: /" .. regex .. "/")
end

function M.remove(regex)
    if regex == "" or regex == nil then
        vim.notify("Candela: no pattern entered")
        return
    end

    for i, pattern in ipairs(M.patterns) do
        if pattern.regex == regex then
            table.remove(M.patterns, i)
            vim.notify("Candela: removed /" .. regex .. "/")
            _draw_window(M.pat_buf)
        end
    end

    vim.notify("Candela: pattern doesn't exist")
end

function M.clear()
    M.patterns = {}

    vim.notify("Candela: cleared all patterns")
end

return M
