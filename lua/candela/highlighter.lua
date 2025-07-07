-- module to control the highlighting of matches

CandelaHighlighter = {}

-- TODO: create default color palette

---@param color string
---@param ns integer
---@param hl_group string
function CandelaHighlighter.register_highlight(color, ns, hl_group)
    vim.api.nvim_set_hl_ns(ns)
    -- TODO: figure out foreground color situation
    local fg = "#101010"
    if fg == nil then
        return
    end

    vim.api.nvim_set_hl(0, hl_group, {
        --fg = fg,
        bg = color,
        force = true,
    })
end

---@param regex string
---@return string
local function hash_regex(regex)
    local hash = vim.fn.sha256(regex):sub(1, 8)
    return "CandelaHl_" .. hash
end

---@param pattern CandelaPattern
---@param engine fun(regex: string, filepath: string): number[]
---@return number
function CandelaHighlighter.highlight_matches(bufnr, pattern, engine)
    local ns = vim.api.nvim_create_namespace("CandelaNs_" .. pattern.regex)
    local hl_group = hash_regex(pattern.regex)
    CandelaHighlighter.register_highlight(pattern.color, ns, hl_group)

    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        vim.notify("Candela: cannot search file with no file name", vim.log.levels.ERROR)
        return 0
    end

    local matches = engine(pattern.regex, filepath)
    local count = 0
    for row, line in pairs(matches) do
        vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, 0, {
            end_col = string.len(line),
            hl_group = hl_group,
            hl_eol = true,
            priority = 100,
        })
        count = count + 1
    end

    return count
end

function CandelaHighlighter.remove_highlight(bufnr, regex)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. regex]
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

function CandelaHighlighter.clear_highlights(bufnr)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. regex]
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

function CandelaHighlighter.change_highlight_color(bufnr, regex, new_color)
    local ns = vim.api.nvim_get_namespaces()["CandelaNs_" .. regex]
    local hl_group = "CandelaHl_" .. regex
    CandelaHighlighter.register_highlight(new_color, ns, hl_group)
end

return CandelaHighlighter
