local M = {
    patterns = {},
    bufnr = vim.api.nvim_create_buf(false, true),
    hl_ns = vim.api.nvim_create_namespace("candela"),
}

function M.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(opts)
        local args = opts.fargs
        local subcommand = args[1]
        local tail = vim.fn.join(vim.list_slice(args, 2), " ")

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

    vim.api.nvim_buf_set_keymap(
        M.bufnr,
        "n",
        "q",
        "<cmd>hide<CR>",
        { noremap = true, silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        M.bufnr,
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
        table.insert(
            lines,
            string.format(
                " %s /%s/ | h %s | l: %s |",
                opts["color"],
                pat,
                opts["highlight"],
                opts["lightbox"]
            )
        )
    end

    return lines
end

function _draw_window(bufnr)
    if bufnr == vim.api.nvim_get_current_buf() then
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_hide(win)
    end

    local lines = _list_patterns()
    local title = " Patterns: "

    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    local width = (math.floor(win_width * 0.35) < 40) and 40 or math.floor(win_width * 0.35)
    local height = table.getn(M.patterns) + 2
    local row = math.floor(win_height * 0.5 - (height * 0.5))
    local col = math.floor(win_width * 0.5 - (width * 0.5))

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].bufhidden = "hide"
    vim.bo[bufnr].modifiable = true

    local win = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "single",
        title = title,
        title_pos = "center",
    })

    return win
end

function M.show()
    win = _draw_window(M.bufnr)

    vim.notify("Candela: show patterns")
end

function M.highlight_patterns(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    vim.api.nvim_buf_clear_namespace(bufnr, M.hl_ns, 0, -1)

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for i, line in ipairs(lines) do
        for pat, opts in pairs(M.patterns) do
            if line:match(pat) then
                vim.api.nvim_buf_add_highlight(bufnr, M.hl_ns, opts.color, i - 1, 0, -1)
                break
            end
        end
    end
end

function M.add(regex)
    if M.patterns[regex] ~= nil then
        vim.notify("Candela: pattern already exists")
        return
    end

    if regex == "" or regex == nil then
        vim.notify("Candela: no pattern entered")
        return
    end

    M.patterns[regex] = {
        color = "#FF0000",
        highlight = true,
        lightbox = true,
    }

    local curr_bufnr = vim.api.nvim_get_current_buf()
    if curr_bufnr == M.bufnr then
        _draw_window(M.bufnr)
    end

    -- M.highlight_patterns(bufnr)

    vim.notify("Candela: added pattern: " .. regex)
end

function M.remove(regex)
    M.patterns[regex] = nil
    vim.notify("Candela: removed pattern: " .. regex)
end

function M.clear()
    M.patterns = {}
    vim.notify("Candela: cleared all patterns")
end

return M
