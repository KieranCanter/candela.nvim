-- Module for defining user configuration

--[[
-- Config ideas:
-- * palette customization
-- * file types to include (default to .txt, .log...?)
--]]

---@class CandelaConfig
---@field defaults table<string, any>
---@field options table<string, any>
local M = {}
M.version = {}

M.defaults = {
    -- Use log syntax highlighting
    window = {
        width = math.floor(vim.o.columns * 0.25), -- integer: width of the patterns window
        height = 7, -- integer: initial height (number of patterns) of the patterns window
        prompt = "overlap", -- "overlap" | "border": position of prompt window in relation to patterns window
    },
    engine = { -- automatically generated, will be overridden if manually set
        ["available"] = {},
        ["selected"] = {},
        ["args"] = {},
    },
    syntax_highlighting = true, -- true | false: Candela-styled logs -- TODO: implement
    auto_refresh = false, -- true | false: automatically refresh pattern matching/highlighting on buffer change
    delete_confirmation = true, -- true | false: require user confirmation upon deleting a pattern
    clear_confirmation = true, -- true | false: require user confirmation upon clearing all patterns
    case = "sensitive", -- "sensitive" | "ignore" | "smart" | "system": case-sensitive option for searching
    lightbox = {
        display = "tab", -- "tab" | "split-right" | "split-left" | "split-up" | "split-down": lightbox display mode
        non_matched = "fold", -- "fold" | "remove": place unmatched lines in folds or completely remove them
    },
}

---@return table<table>
local function get_engine_versions()
    local pattern = "%a+.*%d+%.%d+%.+%d+"
    local engines = { -- TODO: implement other engines
        "rg",
        "hgrep",
        "ag",
        "ugrep",
        "ack",
        "grep",
    }
    local available = {}

    for _, engine in ipairs(engines) do
        local version = vim.fn.system(engine .. " --version"):match(pattern)
        if version ~= nil then
            table.insert(available, { [engine] = version })
        end
    end
    return available
end

---@param opts table
---@return string|nil
local function get_default_engine(opts)
    for _, engine in ipairs(opts.engine.available) do
        if engine[next(engine)] ~= nil then
            return next(engine)
        end
    end

    vim.notify("No regex search tool found... how do you not at least have grep?", vim.log.levels.ERROR)
    return nil
end

---@param opts table
---@return string[]
local function get_default_args(opts)
    local args = {}
    local selected = opts.engine.selected

    if opts.case ~= "sensitive" and opts.case ~= "ignore" and opts.case ~= "smart" and opts.case ~= "system" then
        vim.notify(
            string.format(
                "`%s` is not a valid option value for `case`, using `sensitive` as default."
                    .. ' Valid values: "sensitive", "ignore", "smart", or "system".',
                opts.case
            ),
            vim.log.levels.WARN
        )
        opts.case = "sensitive"
    end

    if selected == "rg" then
        args = { "--line-number", "--color=never" }
        if opts.case == "ignore" or (opts.case == "system" and vim.api.nvim_get_option_value("ignorecase", {})) then
            table.insert(args, "--ignore-case")
        elseif opts.case == "smart" or (opts.case == "system" and vim.api.nvim_get_option_value("smartcase", {})) then
            table.insert(args, "--smart-case")
        else
            table.insert(args, "--case-sensitive")
        end
    elseif selected == "hgrep" then
        args = {}
    elseif selected == "ag" then
        args = {}
    elseif selected == "ugrep" then
        args = {}
    elseif selected == "ack" then
        args = {}
    elseif selected == "grep" then
        args = { "--line-number", "--color=never" }
        if opts.case == "ignore" or (opts.case == "system" and vim.api.nvim_get_option_value("ignorecase", {})) then
            table.insert(args, "--ignore-case")
        elseif opts.case == "smart" or (opts.case == "system" and vim.api.nvim_get_option_value("smartcase", {})) then
            vim.notify(
                "grep does not support smart-case. Consider installing a faster regex search engine or modifying"
                    .. "`case` in your user config to turn smart-case off. Proceeding with the case-sensitive flag.",
                vim.log.levels.WARN
            )
        else
            table.insert(args, "--no-ignore-case")
        end
    else
        vim.notify("No default args for search tool found", vim.log.levels.ERROR)
        args = {}
    end

    return args
end

---@return CandelaConfig
function M.setup(opts)
    M.version["major"] = 1
    M.version["minor"] = 0
    M.version["patch"] = 0

    M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
    M.options.engine.available = get_engine_versions()
    M.options.engine.selected = get_default_engine(M.options)
    M.options.engine.args = get_default_args(M.options)
    return M.options
end

-- TODO: move mappings to mappings.lua file and change to callbacks instead of rhs strings
function M.set_keymaps()
    -- NOTE: Only for dev purposes, leave for user to create
    vim.api.nvim_set_keymap("n", "<leader>cds", [[:Candela<CR>]], {
        noremap = true,
        silent = true,
        desc = "Toggle Candela patterns window",
    })
    vim.api.nvim_set_keymap("n", "<leader>cda", [[:Candela add<CR>]], {
        noremap = true,
        silent = true,
        desc = "Add Candela pattern",
    })
    vim.api.nvim_set_keymap("n", "<M-k>", "[l", {})
    vim.api.nvim_set_keymap("n", "<M-j>", "]l", {})
end

function M.set_patterns_keymaps(buffer)
    vim.api.nvim_buf_set_keymap(buffer, "n", "q", [[:Candela<CR>]], {
        noremap = true,
        silent = true,
        desc = "Close Candela",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "<ESC>", [[:Candela<CR>]], {
        noremap = true,
        silent = true,
        desc = "Close Candela",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "a", [[:Candela add<CR>]], {
        noremap = true,
        silent = true,
        desc = "Add Candela pattern",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "e", [[:Candela edit<CR>]], {
        noremap = true,
        silent = true,
        desc = "Edit Candela pattern",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "c", [[:Candela copy<CR>]], {
        noremap = true,
        silent = true,
        desc = "Copy Candela pattern",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "d", [[:Candela delete<CR>]], {
        noremap = true,
        silent = true,
        desc = "Delete Candela pattern",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "D", [[:Candela clear<CR>]], {
        noremap = true,
        silent = true,
        desc = "Clear all Candela patterns",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "C", [[:Candela change_color<CR>]], {
        noremap = true,
        silent = true,
        desc = "Change Candela pattern color",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "h", [[:Candela toggle_highlight<CR>]], {
        noremap = true,
        silent = true,
        desc = "Toggle Candela pattern highlight",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "l", [[:Candela toggle_lightbox<CR>]], {
        noremap = true,
        silent = true,
        desc = "Toggle Candela pattern lightbox",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "r", [[:Candela refresh<CR>]], {
        noremap = true,
        silent = true,
        desc = "Refresh patterns for current buffer",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "m", [[:Candela match<CR>]], {
        noremap = true,
        silent = true,
        desc = "Candela match pattern in buffer",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "M", [[:Candela match_all<CR>]], {
        noremap = true,
        silent = true,
        desc = "Candela match pattern in buffer",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "f", [[:Candela find<CR>]], {
        noremap = true,
        silent = true,
        desc = "Candela find pattern in buffer",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "F", [[:Candela find_all<CR>]], {
        noremap = true,
        silent = true,
        desc = "Candela find all patterns in buffer",
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "?", [[:Candela help<CR>]], {
        noremap = true,
        silent = true,
        desc = "Display Candela keymaps",
    })
end

function M.set_prompt_keymaps(buffer)
    vim.api.nvim_buf_set_keymap(buffer, "n", "q", "", {
        noremap = true,
        silent = true,
        desc = "Close Prompt",
        callback = function()
            require("candela.ui").hide_prompt()
        end
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "<ESC>", "", {
        noremap = true,
        silent = true,
        desc = "Close Prompt",
        callback = function()
            require("candela.ui").hide_prompt()
        end
    })
end

return M
