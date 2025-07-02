-- Module for defining user configuration

--[[
-- Config ideas:
-- * window sizing
-- * syntax highlighting
-- * fold vs remove unlightboxed lines
-- * ignore-case/smart-case default to user's neovim setting, allow override
--]]

---@class CandelaConfig
---@field defaults table<string, any>
---@field options table<string, any>
local CandelaConfig = {}

CandelaConfig.defaults = {
    -- Use log syntax highlighting
    height = 7,
    syntax_highlighting = true,
}

CandelaConfig.options = {}

---@return CandelaConfig
function CandelaConfig.setup(opts)
    CandelaConfig.options = vim.tbl_deep_extend("force", vim.deepcopy(CandelaConfig.defaults), opts or {})
    return CandelaConfig.options
end

function CandelaConfig.set_keymaps()
    -- NOTE: Only for dev purposes
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
end

function CandelaConfig.set_patterns_keymaps(buffer)
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
        "r",
        [[:Candela remove<CR>]],
        {
            noremap = true,
            silent = true,
            desc = "Remove Candela pattern"
        }
    )
    vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "dd",
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
end

function CandelaConfig.set_prompt_keymaps(buffer)
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

return CandelaConfig
