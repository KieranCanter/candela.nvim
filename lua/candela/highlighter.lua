-- module to control the highlighting of matches

CandelaHighlighter = {}

-- TODO: create default color palette

---@param pattern CandelaPattern
---@param ns integer
---@param hl_group string
function CandelaHighlighter.register_highlight(pattern, ns, hl_group)
    vim.api.nvim_set_hl_ns(ns)
    -- TODO: figure out foreground color situation
    local fg = "#101010"
    if fg == nil then
        return
    end

    vim.api.nvim_set_hl(ns, hl_group, {
        --fg = fg,
        bg = pattern.color,
        force = true,
    })
end

---@param pattern CandelaPattern
---@param engine fun(regex: string, filepath: string): number[]
---@return number
function CandelaHighlighter.highlight_matches(bufnr, pattern, engine)
    local ns = vim.api.nvim_create_namespace("candela_" .. pattern.regex)
    local hl_group = "CandelaHl" .. string.sub(pattern.color, 2)
    CandelaHighlighter.register_highlight(pattern, ns, hl_group)

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

return CandelaHighlighter
