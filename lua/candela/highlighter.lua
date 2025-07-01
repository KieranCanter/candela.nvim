-- module to control the highlighting of matches

CandelaHighlighter = {}

-- TODO: create default color palette
-- TODO: create namespace per pattern

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

---@param bufnr number
---@param pattern CandelaPattern
--[[---@param engine fun(regex: string, filepath: string): number[]--]]
function CandelaHighlighter.highlight_matches(bufnr, pattern--[[, engine--]])
    local ns = vim.api.nvim_create_namespace("candela_" .. pattern.regex)
    local hl_group = "CandelaHl" .. string.sub(pattern.color, 2)
    CandelaHighlighter.register_highlight(pattern, ns, hl_group)

    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row+1, false)[1]
    local hl_id = vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
        hl_group = hl_group,
        hl_eol = true,
        end_col = string.len(line),
    })

    --[[
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath == "" then
        return
    end

    local matching_lines = engine(pattern.regex, filepath)
    for lnum, ranges in pairs(matching_lines) do
        for _, range in ipairs(ranges) do
            vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, range.start, {
                end_col = range.end_,
                hl_group = "CandelaHl_" .. pattern.color,
                hl_eol = true,
                priority = 100,
            })
        end
    end
    --]]
end

return CandelaHighlighter
