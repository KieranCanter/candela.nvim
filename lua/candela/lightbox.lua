local CandelaWindow = require("candela.window")
local CandelaHighlighter = require("candela.highlighter")

local M = {}

local function verify_opts(opts)
    local defaults = require("candela.config").defaults

    if
        opts.lightbox.view ~= "tab"
        and opts.lightbox.view ~= "split-left"
        and opts.lightbox.view ~= "split-right"
        and opts.lightbox.view ~= "split-above"
        and opts.lightbox.view ~= "split-below"
    then
        vim.notify(
            string.format(
                '"%s" is not a valid option value for `lightbox.view`, using "%s" as default.'
                    .. ' Valid values: "tab", "split-left", "split-right", "split-above", "split-below".',
                opts.lightbox.view,
                defaults.lightbox.view
            ),
            vim.log.levels.WARN
        )
        opts.lightbox.view = defaults.lightbox.view
    end

    if opts.lightbox.non_matched ~= "fold" and opts.lightbox.non_matched ~= "remove" then
        vim.notify(
            string.format(
                '"%s" is not a valid option value for `lightbox.non_matched`, using "%s" as default.'
                    .. ' Valid values: "fold", "remove".',
                opts.lightbox.non_matched,
                defaults.lightbox.non_matched
            ),
            vim.log.levels.WARN
        )
        opts.lightbox.non_matched = defaults.lightbox.non_matched
    end

    if type(opts.lightbox.trim_space) ~= "boolean" then
        vim.notify(
            string.format(
                '"%s" is not a valid option value for `lightbox.trim_space`, using "%s" as default.'
                    .. ' Valid values: true, false.',
                opts.lightbox.trim_space,
                defaults.lightbox.trim_space
            ),
            vim.log.levels.WARN
        )
        opts.lightbox.trim_space = defaults.lightbox.trim_space
    end
end

local function init_tab()
    vim.notify("init_tab() not implemented yet", vim.log.levels.WARN)
end

---@param view_mode string: "left" | "right" | "above" | "below"
local function init_split(view_mode)
    local window = CandelaWindow.new({
        win = 0,
        split = view_mode,
    })
    window.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("swapfile", false, { buf = window.buf })
    vim.api.nvim_set_option_value("filetype", "lightbox.candela", { buf = window.buf })
    M.window = window
end

function M.setup(opts)
    verify_opts(opts)
    M.opts = {}
    M.opts.view = opts.lightbox.view
    M.opts.non_matched = opts.lightbox.non_matched
    M.opts.trim_space = opts.lightbox.trim_space

    local view_mode = M.opts.view:match("split%-(%a+)")
    if view_mode == nil then
        init_tab()
    else
        init_split(view_mode)
    end

    return M
end

local function write_lightbox_with_fold(base_buf)
    vim.notify("write_lightbox_with_fold() not implemented yet", vim.log.levels.WARN)
end

local function write_lightbox_with_remove(base_buf)
    local old_lines = vim.api.nvim_buf_get_lines(base_buf, 0, -1, false)
    local match_cache = CandelaHighlighter.get_flattened_match_cache()

    for i, match in ipairs(match_cache) do
        local curr = ""
        if M.opts.trim_space == true then
            curr = string.match(old_lines[match.lineno], "%s*(%a.*%a)%s*")
        else
            curr = old_lines[match.lineno]
        end
        vim.api.nvim_buf_set_lines(M.window.buf, i-1, i, false, { curr })
        vim.api.nvim_buf_set_extmark(M.window.buf, match.ns, i-1, 0, {
            end_col = string.len(curr),
            line_hl_group = match.hl_group,
            priority = 100,
        })
    end
end

function M.display()
    local base_buf = require("candela.ui").base_buf
    if base_buf == nil then
        return
    end

    if M.opts.non_matched == "fold" then
        write_lightbox_with_fold()
    else
        write_lightbox_with_remove(base_buf)
    end

    M.window:open_window(true)
end

function M.toggle(view, non_matched)
    if M.window:is_open() then
        M.window:close_window()
    else
        M.display(view, non_matched)
    end
end

return M
