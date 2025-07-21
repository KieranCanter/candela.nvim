-- Module for defining user configuration

--[[
-- Config ideas:
-- * window sizing
-- * syntax highlighting
-- * fold vs remove unlightboxed lines
-- * ignore-case/smart-case default to user's neovim setting, allow override
-- * palette customization
-- * file types to include (default to .txt, .log...?)
-- * auto refresh when switching files or not
-- * search engine ripgrep, hypergrep, ag, ugrep, ack, gnu grep
-- * whether users want confirmation message on delete/clear to show or not
--]]

---@class CandelaConfig
---@field defaults table<string, any>
---@field options table<string, any>
local M = {}

M.defaults = {
    -- Use log syntax highlighting
    height = 7,
    syntax_highlighting = true,
    engine = {
        ["available"] = {},
        ["selected"] = {},
        ["args"] = {},
    }
}
M.options = {}
M.version = {}

---@return table<table>
local function get_engine_versions()
    local pattern = "%a+.*%d+%.%d+%.+%d+"
    local engines = {
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

---@return string|nil
local function get_default_engine()
    for _, engine in ipairs(M.defaults.engine.available) do
        if engine[next(engine)] ~= nil then
            return next(engine)
        end
    end

    vim.notify("No regex search tool found... how do you not at least have grep?", vim.log.levels.ERROR)
    return nil
end

---@return string[]
local function get_default_args()
    local selected = M.defaults.engine.selected

    if selected == "rg" then
        return {"--line-number", "--color=never"}
    elseif selected == "hgrep" then
        return {}
    elseif selected == "ag" then
        return {}
    elseif selected == "ugrep" then
        return {}
    elseif selected == "ack" then
        return {}
    elseif selected == "grep" then
        return {}
    else
        vim.notify("No default args for search tool found", vim.log.levels.ERROR)
        return {}
    end
end

---@return CandelaConfig
function M.setup(opts)
    M.version["major"] = 1
    M.version["minor"] = 0
    M.version["patch"] = 0

    M.defaults.engine.available = get_engine_versions()
    M.defaults.engine.selected = get_default_engine()
    M.defaults.engine.args = get_default_args()
    M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
    return M.options
end

-- TODO: move mappings to mappings.lua file
function M.set_keymaps()
    -- NOTE: Only for dev purposes, leave for user to create
    vim.api.nvim_set_keymap(
        "n",
        "<leader>cds",
        [[:Candela<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Toggle Candela patterns window",
        }
    )
    vim.api.nvim_set_keymap(
        "n",
        "<leader>cda",
        [[:Candela add<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Add Candela pattern"
        }
    )
    vim.api.nvim_set_keymap("n", "<M-k>", "[l", {})
    vim.api.nvim_set_keymap("n", "<M-j>", "]l", {})
end

function M.set_patterns_keymaps(buffer)
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "q",
        [[:Candela<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Close Candela",
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "<ESC>",
        [[:Candela<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Close Candela"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "a",
        [[:Candela add<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Add Candela pattern"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "e",
        [[:Candela edit<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Edit Candela pattern"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "c",
        [[:Candela copy<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Copy Candela pattern"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "d",
        [[:Candela delete<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Delete Candela pattern"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "D",
        [[:Candela clear<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Clear all Candela patterns"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "C",
        [[:Candela change_color<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Change Candela pattern color"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "h",
        [[:Candela toggle_highlight<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Toggle Candela pattern highlight"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "l",
        [[:Candela toggle_lightbox<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Toggle Candela pattern lightbox"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "r",
        [[:Candela refresh<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Refresh patterns for current buffer"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "<CR>",
        [[:Candela match<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Candela match pattern in buffer"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "f",
        [[:Candela find<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Candela find pattern in buffer"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "F",
        [[:Candela find_all<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Candela find all patterns in buffer"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "?",
        [[:Candela help<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Display Candela keymaps"
        }
    )
end

function M.set_prompt_keymaps(buffer)
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "q",
        [[:Candela<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Close Prompt",
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "<ESC>",
        [[:Candela<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Close Prompt"
        }
    )
end

return M
