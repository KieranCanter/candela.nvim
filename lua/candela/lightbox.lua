local CandelaWindow = require("candela.window")
local CandelaHighlighter = require("candela.highlighter")
local CandelaConfig = require("candela.config")

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
    M.view = opts.lightbox.view
    M.non_matched = opts.lightbox.non_matched

    local view_mode = M.view:match("split%-(%a+)")
    if view_mode == nil then
        init_tab()
    else
        init_split(view_mode)
    end

    return M
end

function M.update(ranges)
    --vim.api.nvim_buf_set_lines(M.window.buf, 0, -1, false, lines)
    --CandelaHighlighter.higlight_cache(M.window.buf)
    --local gaps = CandelaHighlighter.get_match_gaps(M.window.buf)
    --local new_lines = remove_gaps(lines, gaps)
    --vim.api.nvim_buf_set_lines(M.window.buf, 0, -1, false, new_lines)
end

function M.display(view, non_matched)
    local base_buf = require("candela.ui").base_buf
    if base_buf == nil then
        return
    end
    local old_lines = vim.api.nvim_buf_get_lines(base_buf, 0, -1, false)
    local linenums = CandelaHighlighter.get_flattened_match_cache()

    local new_lines = {}
    for _, lineno in ipairs(linenums) do
        table.insert(new_lines, old_lines[lineno])
    end

    vim.api.nvim_buf_set_lines(M.window.buf, 0, -1, false, new_lines)

    local cmd = CandelaConfig.options.engine.command
    local args = CandelaConfig.options.engine.args

    --M.update(ranges)
    M.window:open_window(true)
    -- FIX: THIS IS A MESS CAN'T GREP SCRATCH BUFFER CUZ NO FILE NAME FIGURE IT THE FUCK OUT
    for _, pattern in ipairs(require("candela.pattern_list").patterns) do
        CandelaHighlighter.highlight_matches(M.window.buf, pattern, cmd, args)
    end
end

function M.toggle(view, non_matched)
    if M.window:is_open() then
        M.window:close_window()
    else
        M.display(view, non_matched)
    end
end

return M
