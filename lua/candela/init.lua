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
--  * Syntax highlighting option true or false
--  * Lightbox
--    * separate buffer/window for only "lightbox" true patterns
--]]

local CandelaUi = require("candela.ui")
local CandelaPatternList = require("candela.pattern_list")
local CandelaConfig = require("candela.config")
local CandelaCommands = require("candela.commands")

---@class Candela
---@field ui CandelaUi
---@field patterns CandelaPattern[]

local Candela = {}

---@return Candela
function Candela:new()
    -- TODO: self.config = Config.get_default_config(),
    -- TODO: self.commands = CandelaCommands.setup(),
    self.ui = CandelaUi:setup()
    self.patterns = {}

    return self
end

function Candela.setup(opts)
    local candela = Candela:new()
    vim.api.nvim_create_user_command("Candela", function()
        candela.ui:toggle()
    end, {})
end

--[[
local ns_candela_highlighting = vim.api.nvim_create_namespace("candela_highlighting")

local _foreach_float = function(callback)
    for name, float in pairs(M.floats) do
        callback(name, float)
    end
end

function M.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(opts)
        local args = opts.fargs
        local subcommand = args[1]
        local tail = table.concat(vim.list_slice(args, 2), " ")

        if subcommand == "" or subcommand == nil then
            require("candela").show_all_windows()
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
    M.patterns = {}
    M.floats = {}

    local win_configs = M:create_window_configurations()

    -- Window to hold colors, regex, highlight, and lightbox cols
    -- M.floats.patterns = M:create_float(win_configs.patterns)

    win_configs.colors.win = M.floats.patterns.win
    -- M.floats.colors = M:create_float(win_configs.colors) -- Colors column
    win_configs.regex.win = M.floats.patterns.win
    -- M.floats.regex = M:create_float(win_configs.regex) -- Regex column
    win_configs.highlight.win = M.floats.patterns.win
    -- M.floats.highlight = M:create_float(win_configs.highlight) -- Highlight column
    win_configs.lightbox.win = M.floats.patterns.win
    -- M.floats.lightbox = M:create_float(win_configs.lightbox) -- Lightbox column

    win_configs.operation.win = M.floats.patterns.win
    -- M.floats.operation = M:create_float(win_configs.operation) -- "Add Regex" prompt
    vim.bo[M.floats.operation.buf].buftype = "prompt"
    vim.bo[M.floats.operation.buf].swapfile = false
    vim.bo[M.floats.operation.buf].bufhidden = "wipe"
    vim.fn.prompt_setcallback(M.floats.operation.buf, function(input)
        M.add(input)
        M.update()
    end)
    vim.fn.prompt_setprompt(M.floats.operation.buf, " > ")
    vim.cmd("startinsert")

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

    print("Candela loaded")
end

function M:create_window_configurations()
    local win_width = vim.o.columns
    local win_height = vim.o.lines

    local float_width = math.floor(win_width * 0.50)

    local pattern_color_width = 9
    local pattern_ops_width = 5
    local pattern_regex_width = float_width - pattern_color_width - (pattern_ops_width * 2) - 2
    local pattern_height = math.max(#M.patterns + 3, 9)
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

function M.show_all_windows()
    _foreach_float(function(_, float)
        local enter = false
        if float == M.floats.operation then
            enter = true
        end
        pcall(vim.api.nvim_open_win, float.buf, enter, vim.api.nvim_win_get_config(float.win))
    end)
end

function M._set_pattern_lines()
    if #M.patterns > 0 then
        for i, pattern in ipairs(M.patterns) do
            vim.api.nvim_buf_set_lines(M.floats.colors.buf, i, i, false, { pattern.color })
            vim.api.nvim_buf_set_lines(
                M.floats.regex.buf,
                i,
                i,
                false,
                { string.format("%d. /%s/", i, pattern.regex) }
            )
            vim.api.nvim_buf_set_lines(
                M.floats.highlight.buf,
                i,
                i,
                false,
                { tostring(pattern.highlight) }
            )
            vim.api.nvim_buf_set_lines(
                M.floats.lightbox.buf,
                i,
                i,
                false,
                { tostring(pattern.lightbox) }
            )
        end
    end
end

function M.update()
    M.close_all_windows()


    M.show_all_windows()
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

function M.add(regex)
    if regex == "" or regex == nil then
        vim.notify("Candela: no pattern entered")
        return
    end

    if #M.patterns > 0 then
        for i, pattern in ipairs(M.patterns) do
            if pattern.regex == regex then
                vim.notify(
                    string.format("Candela: pattern %d: /%s/ already exists", i, pattern.regex)
                )
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

    if M.floats.patterns then
        M.show_all_windows()
    end

    vim.notify(string.format("Candela: added pattern: /%s/", regex))
end

---@param item string|number?
function M.remove(item)
    if tonumber(item) then
        item = tonumber(item)
    end

    if type(item) == "string" then
        if item == "" then
            vim.notify("Candela: no pattern or index entered")
            return
        end

        for i, pattern in ipairs(M.patterns) do
            if pattern.regex == item then
                table.remove(M.patterns, i)
                vim.notify(string.format("Candela: removed pattern %d: /%s/", i, pattern.regex))
                break
            end
        end
        vim.notify("Candela: pattern doesn't exist")
    end

    if type(item) == "number" then
        if item < 1 or item > #M.patterns or item % 1 ~= 0 then
            vim.notify(
                string.format(
                    "Candela: invalid index, enter an integer between 1 and %d",
                    #M.patterns
                )
            )
            return
        end

        local rm_pat = M.patterns[item].regex
        table.remove(M.patterns, item)
        vim.notify(string.format("Candela: removed pattern %d: /%s/", item, rm_pat))
    end

    if M.floats.patterns then
        M.update()
    end
end

function M.clear()
    M.patterns = {}
    if M.floats.patterns then
        M.update()
    end
    vim.notify("Candela: cleared all patterns")
end
--]]
return Candela
