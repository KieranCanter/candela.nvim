local CandelaUi = require("candela.ui")
local CandelaCommands = require("candela.commands")

local M = {}
M.help = { buf = nil, win = nil, config = nil }

local CANDELA_AUGROUP = require("candela.init").CANDELA_AUGROUP

---@param keymap_info table
local function build_help_buf(keymap_info)
    M.help.buf = vim.api.nvim_create_buf(false, true)
    if not M.help.buf then
        return
    end

    local lines = {}
    local widest = 0
    for _, keymap in ipairs(keymap_info) do
        local desc = keymap.desc:gsub("%[Candela%]%s*", "")
        desc = desc:sub(1, 1):upper() .. desc:sub(2)
        -- selene: allow(bad_string_escape)
        local line = string.format("%-5s \u{25b8} %s", keymap.lhs, desc)
        table.insert(lines, line)
        widest = math.max(widest, line:len()) -- track longest line for width
    end

    vim.api.nvim_buf_set_lines(M.help.buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.help.buf })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = M.help.buf })

    M.help.config = {
        relative = "editor",
        height = #lines,
        width = widest,
        row = (vim.o.lines - #lines + 2) / 2 - 1,
        col = (vim.o.columns - widest + 2) / 2,
        style = "minimal",
        border = "rounded",
        title = " Candela UI Keymaps ",
        title_pos = "center",
    }

    -- Set highlighting
    local ns = vim.api.nvim_create_namespace("CandelaHelp")
    for i = 0, #lines - 1 do
        -- Set highlight color
        vim.api.nvim_buf_set_extmark(M.help.buf, ns, i, 0, {
            end_row = i,
            end_col = 5,
            hl_group = "Title",
        })
        vim.api.nvim_buf_set_extmark(M.help.buf, ns, i, 6, {
            end_row = i,
            end_col = 7,
            hl_group = "Comment",
        })
        vim.api.nvim_buf_set_extmark(M.help.buf, ns, i, 8, {
            end_row = i,
            end_col = M.help.config.width,
            hl_group = "Special",
            strict = false,
        })
    end

    vim.api.nvim_buf_set_keymap(M.help.buf, "n", "q", "", {
        noremap = true,
        silent = true,
        desc = "[Candela] close help menu",
        callback = function()
            if vim.api.nvim_win_is_valid(M.help.win) then
                vim.api.nvim_win_close(M.help.win, true)
            end
        end,
    })
    vim.api.nvim_buf_set_keymap(M.help.buf, "n", "<ESC>", "", {
        noremap = true,
        silent = true,
        desc = "[Candela] close help menu",
        callback = function()
            if vim.api.nvim_win_is_valid(M.help.win) then
                vim.api.nvim_win_close(M.help.win, true)
            end
        end,
    })
    vim.api.nvim_create_autocmd("WinLeave", {
        group = CANDELA_AUGROUP,
        buffer = M.help.buf,
        callback = function()
            vim.api.nvim_win_close(M.help.win, true)
        end,
    })
end

function M.set_patterns_keymaps()
    local regex_buf = CandelaUi.windows.regex.buf --[[@as integer]]

    local keymap_info = {
        {
            lhs = "q",
            desc = "[Candela] close UI",
            callback = function()
                CandelaUi.hide_patterns()
            end,
        },
        {
            lhs = "<ESC>",
            desc = "[Candela] close UI",
            callback = function()
                CandelaUi.hide_patterns()
            end,
        },
        {
            lhs = "a",
            desc = "[Candela] add pattern",
            callback = function()
                CandelaUi.add()
            end,
        },
        {
            lhs = "e",
            desc = "[Candela] edit pattern",
            callback = function()
                CandelaUi.edit()
            end,
        },
        {
            lhs = "c",
            desc = "[Candela] copy pattern",
            callback = function()
                CandelaUi.copy()
            end,
        },
        {
            lhs = "d",
            desc = "[Candela] delete pattern",
            callback = function()
                CandelaUi.delete(require("candela.config").options.matching.delete_confirmation)
            end,
        },
        {
            lhs = "D",
            desc = "[Candela] clear all patterns",
            callback = function()
                CandelaUi.clear(require("candela.config").options.matching.delete_confirmation)
            end,
        },
        {
            lhs = "C",
            desc = "[Candela] change pattern color",
            callback = function()
                CandelaUi.change_color()
            end,
        },
        {
            lhs = "h",
            desc = "[Candela] toggle pattern highlight",
            callback = function()
                CandelaUi.toggle_highlight()
            end,
        },
        {
            lhs = "l",
            desc = "[Candela] toggle pattern lightbox",
            callback = function()
                CandelaUi.toggle_lightbox()
            end,
        },
        {
            lhs = "R",
            desc = "[Candela] refresh patterns for current buffer",
            callback = function()
                CandelaUi.refresh(true)
            end,
        },
        {
            lhs = "<TAB>",
            desc = "[Candela] toggle selection of pattern",
            callback = function()
                CandelaUi.toggle_select_pattern()
            end,
        },
        {
            lhs = "m",
            desc = "[Candela] vim match selected patterns",
            callback = function()
                CandelaUi.locate(false, "match")
            end,
        },
        {
            lhs = "M",
            desc = "[Candela] vim match all patterns",
            callback = function()
                CandelaUi.locate(true, "match")
            end,
        },
        {
            lhs = "f",
            desc = "[Candela] find selected patterns and send to location list",
            callback = function()
                CandelaUi.locate(false, "find")
            end,
        },
        {
            lhs = "F",
            desc = "[Candela] find all patterns and send to location list",
            callback = function()
                CandelaUi.locate(true, "find")
            end,
        },
        {
            lhs = "L",
            desc = "[Candela] toggle lightbox",
            callback = function()
                CandelaCommands.commands.lightbox.impl()
            end,
        },
        {
            lhs = "I",
            desc = "[Candela] import patterns from file",
            callback = function()
                CandelaUi.import()
            end,
        },
        {
            lhs = "E",
            desc = "[Candela] export patterns to file",
            callback = function()
                CandelaUi.export()
            end,
        },
        {
            lhs = "?",
            desc = "[Candela] open help menu",
            callback = function()
                CandelaCommands.commands.help.impl()
            end,
        },
    }

    for _, keymap in ipairs(keymap_info) do
        vim.api.nvim_buf_set_keymap(regex_buf, "n", keymap.lhs, "", {
            noremap = true,
            silent = true,
            desc = keymap.desc,
            callback = keymap.callback,
        })
    end

    build_help_buf(keymap_info)

    local user_keymaps = {
        {
            lhs = "<Plug>CandelaUI",
            desc = "[Candela] toggle UI window",
            callback = function()
                CandelaUi.toggle()
            end,
        },
        {
            lhs = "<Plug>CandelaAdd",
            desc = "[Candela] add pattern in UI",
            callback = function()
                CandelaUi.add()
            end,
        },
        {
            lhs = "<Plug>CandelaRefresh",
            desc = "[Candela] refresh patterns in current buffer",
            callback = function()
                CandelaCommands.commands.refresh.impl()
            end,
        },
        {
            lhs = "<Plug>CandelaClear",
            desc = "[Candela] clear all patterns",
            callback = function()
                CandelaCommands.commands.clear.impl()
            end,
        },
        {
            lhs = "<Plug>CandelaMatchAll",
            desc = "[Candela] vim match all patterns",
            callback = function()
                CandelaCommands.commands.match_all.impl()
            end,
        },
        {
            lhs = "<Plug>CandelaFindAll",
            desc = "[Candela] find all patterns and send to location list",
            callback = function()
                CandelaCommands.commands.find_all.impl()
            end,
        },
        {
            lhs = "<Plug>CandelaLightbox",
            desc = "[Candela] toggle lightbox window",
            callback = function()
                CandelaCommands.commands.lightbox.impl()
            end,
        },
        {
            lhs = "<Plug>CandelaHelp",
            desc = "[Candela] open UI keymaps menu",
            callback = function()
                CandelaCommands.commands.help.impl()
            end,
        },
    }

    for _, keymap in ipairs(user_keymaps) do
        vim.api.nvim_set_keymap("n", keymap.lhs, "", {
            noremap = true,
            silent = true,
            desc = keymap.desc,
            callback = keymap.callback,
        })
    end
end

function M.set_prompt_keymaps()
    local prompt_buf = CandelaUi.windows.prompt.buf --[[@as integer]]

    local keymap_info = {
        {
            mode = "n",
            lhs = "q",
            rhs = "",
            desc = "[Candela] close prompt",
            callback = function()
                CandelaUi.hide_prompt()
            end,
        },
        {
            mode = "n",
            lhs = "<ESC>",
            rhs = "",
            desc = "[Candela] close prompt",
            callback = function()
                CandelaUi.hide_prompt()
            end,
        },
        { -- Keymaps to ensure completions consistently show up in prompt buffer
            mode = "i",
            lhs = "<C-n>",
            rhs = "<C-x><C-u>",
        },
        {
            mode = "i",
            lhs = "<C-p>",
            rhs = "<C-x><C-u>",
        },
    }

    -- Build help menu buffer

    for _, keymap in ipairs(keymap_info) do
        vim.api.nvim_buf_set_keymap(prompt_buf, keymap.mode, keymap.lhs, keymap.rhs, {
            noremap = true,
            silent = true,
            desc = keymap.desc,
            callback = keymap.callback,
        })
    end
end

local function yank_unfolded()
    -- Get start/end of visual selection
    local start_pos = vim.api.nvim_buf_get_mark(0, "<")[1]
    local end_pos = vim.api.nvim_buf_get_mark(0, ">")[1]

    -- Collect unfolded lines
    local unfolded_lines = {}
    for lnum = start_pos, end_pos do
        if vim.fn.foldclosed(lnum) == -1 then
            table.insert(unfolded_lines, vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1])
        end
    end

    if #unfolded_lines == 0 then
        vim.notify("No unfolded lines in selection", vim.log.levels.WARN)
        return
    end

    vim.fn.setreg('"', table.concat(unfolded_lines, "\n"))
    vim.notify("Yanked " .. #unfolded_lines .. " unfolded lines", vim.log.levels.INFO)
end

vim.api.nvim_set_keymap("v", "<leader>YU", "", {
    noremap = true,
    silent = true,
    desc = "Yank unfolded lines to register",
    callback = function()
        yank_unfolded()
    end,
})

return M
