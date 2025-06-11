---@class CandelaOpts
---@field color string
---@field highlight boolean
---@field lightbox boolean

---@class CandelaPattern
---@field regex string
---@field opts table<CandelaOpts>

---@class CandelaUi
---@field patterns table<CandelaPattern>
---@field pat_buf integer
---@field pat_win integer|nil
---@field add_buf integer
---@field add_win integer|nil
---@field rm_buf integer
---@field rm_win integer|nil

local M = {}
local ns_candela_highlighting = vim.api.nvim_create_namespace("candela_highlighting")

function M.setup(opts)
    vim.api.nvim_create_user_command("Candela", function(opts)
        local args = opts.fargs
        local subcommand = args[1]
        local tail = vim.list_slice(args, 2)

        if subcommand == "" or subcommand == nil then
            require("candela").show()
        elseif subcommand == "add" then
            for _,regex in ipairs(tail) do
                require("candela").add(regex)
            end
        elseif subcommand == "remove" then
            for _,regex in ipairs(tail) do
                require("candela").remove(regex)
            end
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
        table.insert(
            lines,
            string.format(
                " %s /%s/ | h %s | l %s |",
                opts["color"],
                pat,
                opts["highlight"],
                opts["lightbox"]
            )
        )
    end

    return lines
end

function _get_size(map)
    local size = 0
    for _ in pairs(map) do
        size = size + 1
    end
    return size
end

function _draw_window(bufnr)
    if bufnr == vim.api.nvim_get_current_buf() then
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_hide(win)
    end

    local lines = _list_patterns()
    local title = " Patterns "

    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    local width = (math.floor(win_width * 0.35) < 40) and 40 or math.floor(win_width * 0.35)
    local height = math.max(_get_size(M.patterns), 4)
    local row = math.floor(win_height * 0.5 - (height * 0.5))
    local col = math.floor(win_width * 0.5 - (width * 0.5))

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

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
    win = _draw_window(M.pat_buf)

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

    M.highlight(M.base_buf, regex)
    _draw_window(M.pat_buf)

    vim.notify("Candela: added pattern: " .. regex)
end

function M.remove(regex)
    if M.patterns[regex] == nil then
        vim.notify("Candela: pattern doesn't exist")
        return
    end

    if regex == "" or regex == nil then
        vim.notify("Candela: no pattern entered")
        return
    end

    M.patterns[regex] = nil

    _draw_window(M.pat_buf)

    vim.notify("Candela: removed pattern: " .. regex)
end

function M.clear()
    M.patterns = {}

    _draw_window(M.pat_buf)

    vim.notify("Candela: cleared all patterns")
end

return M
