local CandelaPatternList = require("candela.pattern_list")
local CandelaHighlighter = require("candela.highlighter")
local CandelaConfig = require("candela.config")

M = {}

---@enum operations
Operations = {
    ADD = 1,
    EDIT = 2,
    COPY = 3,
    CHANGE_COLOR = 4,
}

---@param args table: { regex, color?, highlight?, lightbox? }
function M.add(args)
    local CandelaUi = require("candela.ui")

    local regex, color, highlight, lightbox = unpack(args)
    local new_id, new_pattern = CandelaPatternList.add_pattern(regex, color, highlight, lightbox)
    if new_id == nil or new_pattern == nil then
        vim.notify(
            string.format(
                "[Candela] error when adding new pattern, got: id=%s, pattern=%s",
                new_id,
                vim.inspect(new_pattern)
            ),
            vim.log.levels.ERROR
        )
        return
    end

    local base_buf = CandelaUi.base_buf and CandelaUi.base_buf or vim.api.nvim_get_current_buf()
    local cmd = CandelaConfig.options.engine.command --[[@as string]]
    local cmd_args = CandelaConfig.options.engine.args
    local count = CandelaHighlighter.highlight_matches(base_buf, new_id, new_pattern, cmd, cmd_args)
    if count == -1 then
        CandelaPatternList.delete_pattern(#CandelaPatternList.order)
        return
    end

    new_pattern.count = count

    CandelaUi.update_ui_lines()
end

return M
