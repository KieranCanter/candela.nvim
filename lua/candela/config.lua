-- Module for defining user configuration

---@class CandelaConfig
---@field defaults table<string, any>
---@field options table<string, any>
local M = {}
M.version = {}

M.defaults = {
    -- Candela-styled logs
    syntax_highlighting = true, -- true | false -- TODO: implement
    -- Use log syntax highlighting
    window = {
        -- width of the patterns window
        width = math.floor(vim.o.columns * 0.25), -- integer
        -- initial height (number of patterns) of the patterns window
        height = 7, -- integer
        -- position of prompt window in relation to patterns window
        prompt_layout = "overlap", -- "overlap" | "border"
    },
    engine = {
        -- regex search engine to use; defaults to first found tool out of the list in order
        command = {}, -- "rg" | "ag" | "ugrep" | "ack" | "grep"
        -- args to pass to search engine; refer to your tool's manual
        args = {},
    },
    matching = {
        -- automatically refresh pattern matching/highlighting on buffer change
        auto_refresh = false, -- true | false
        -- require user confirmation upon deleting a pattern
        delete_confirmation = true, -- true | false
        -- require user confirmation upon clearing all patterns
        clear_confirmation = true, -- true | false
        -- case-sensitive option for searching
        case = "sensitive", -- "sensitive" | "ignore" | "smart" | "system"
        -- highlight entire line (end of line) or end of text
        hl_eol = false, -- true | false
    },
    lightbox = {
        -- lightbox view mode
        view = "tab", -- "tab" | "split-left" | "split-right" | "split-above" | "split-below"
        -- place non-matched lines in folds or completely remove them
        hide_method = "remove", -- "fold" | "remove"
        -- trim beginning/ending whitespace from lightbox-highlighted lines
        trim_space = false, -- false | true
        -- highlight entire line (end of line) or end of text
        hl_eol = true, -- true | false
    },
    -- file types to load Candela for
    file_types = { -- TODO: implement
        ".log",
        ".txt",
    },
    palette = {
        -- replace default color palette or add to it
        use = "replace", -- "replace" | "prepend" | "append" -- TODO: implement
        -- list of colors to use for dark/light mode
        colors = {
            dark = {
                "#003f5c", -- deep blue
                "#2f4b7c", -- indigo
                "#665191", -- muted purple
                "#a05195", -- plum
                "#d45087", -- rose
                "#f95d6a", -- coral red
                "#ff7c43", -- burnt orange
                "#ffa600", -- gold
                "#b59f3b", -- olive yellow
                "#5f7e0e", -- moss green
                "#2f9e44", -- forest green
                "#228c99", -- teal
                "#1c7ed6", -- azure
                "#4263eb", -- strong blue
                "#5c5f66", -- soft gray
                "#7c4dff", -- electric purple,
            },
            light = {
                "#3c8fcf", -- muted blue
                "#61afef", -- sky blue
                "#88c0d0", -- nord light blue
                "#81a1c1", -- nord steel
                "#56b6c2", -- teal
                "#98c379", -- green
                "#c3e88d", -- pastel green
                "#e5c07b", -- soft yellow
                "#fab387", -- peach
                "#f78c6c", -- orange
                "#e06c75", -- red
                "#ff6ac1", -- pink
                "#c678dd", -- purple
                "#bb9af7", -- violet
                "#7dcfff", -- light aqua
                "#9aedfe", -- icy cyan,
            },
        },
    },
}

---@return table<table>
function M.get_engine_versions()
    local pattern = "%d+%.%d+%.*%d*"
    local engines = { -- TODO: implement other engines
        { rg = "ripgrep" },
        { ag = "ag" },
        { ugrep = "ugrep" },
        { ack = "ack" },
        { grep = "grep" },
    }
    local available = {}

    for _, engine in ipairs(engines) do
        local version = vim.fn.system(next(engine) .. " --version"):match(pattern)
        if version ~= nil then
            table.insert(available, { [next(engine)] = { engine[next(engine)], version } })
        end
    end
    return available
end

---@param available table
---@return table|nil
local function get_default_engine(available)
    for _, engine in ipairs(available) do
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
    local command = opts.engine.command

    if
        opts.matching.case ~= "sensitive"
        and opts.matching.case ~= "ignore"
        and opts.matching.case ~= "smart"
        and opts.matching.case ~= "system"
    then
        vim.notify(
            string.format(
                '"%s" is not a valid option value for `case`, using "sensitive" as default.'
                    .. ' Valid values: "sensitive", "ignore", "smart", "system".',
                opts.matching.case
            ),
            vim.log.levels.WARN
        )
        opts.matching.case = M.defaults.case
    end

    if command == "rg" then
        args = { "--line-number", "--color=never" }
        if
            opts.matching.case == "ignore"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("ignorecase", {}))
        then
            table.insert(args, "--ignore-case")
        elseif
            opts.matching.case == "smart"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("smartcase", {}))
        then
            table.insert(args, "--smart-case")
        else
            table.insert(args, "--case-sensitive")
        end
    elseif command == "ag" then
        args = { "--numbers", "--nocolor" }
        if
            opts.matching.case == "ignore"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("ignorecase", {}))
        then
            table.insert(args, "--ignore-case")
        elseif
            opts.matching.case == "smart"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("smartcase", {}))
        then
            table.insert(args, "--smart-case")
        else
            table.insert(args, "--case-sensitive")
        end
    elseif command == "ugrep" then
        args = { "--line-number", "--color=never" }
        if
            opts.matching.case == "ignore"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("ignorecase", {}))
        then
            table.insert(args, "--ignore-case")
        elseif
            opts.matching.case == "smart"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("smartcase", {}))
        then
            table.insert(args, "--smart-case")
        end
    elseif command == "ack" then
        args = { "--with-filename", "--nocolor" }
        if
            opts.matching.case == "ignore"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("ignorecase", {}))
        then
            table.insert(args, "--ignore-case")
        elseif
            opts.matching.case == "smart"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("smartcase", {}))
        then
            table.insert(args, "--smart-case")
        else
            table.insert(args, "--no-ignore-case")
        end
    elseif command == "grep" then
        args = { "--line-number", "--color=never" }
        if
            opts.matching.case == "ignore"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("ignorecase", {}))
        then
            table.insert(args, "--ignore-case")
        elseif
            opts.matching.case == "smart"
            or (opts.matching.case == "system" and vim.api.nvim_get_option_value("smartcase", {}))
        then
            vim.notify(
                "grep does not support smart-case. Consider installing a faster regex search engine or modifying"
                    .. "`case` in your user config to turn smart-case off. Proceeding with the case-sensitive flag.",
                vim.log.levels.WARN
            )
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
    local available = M.get_engine_versions()
    M.options.engine.command = get_default_engine(available)
    M.options.engine.command = "grep"
    M.options.engine.args = get_default_args(M.options)
    return M.options
end

-- TODO: move mappings to mappings.lua file and change to callbacks instead of rhs strings
function M.set_keymaps()
    -- NOTE: Only for dev purposes, leave for user to create
    local CandelaUi = require("candela.ui")
    local CandelaCommands = require("candela.commands")

    vim.api.nvim_set_keymap("n", "<leader>cds", "", {
        noremap = true,
        silent = true,
        desc = "Candela: toggle patterns window",
        callback = function()
            CandelaUi.toggle()
        end,
    })
    vim.api.nvim_set_keymap("n", "<leader>cda", "", {
        noremap = true,
        silent = true,
        desc = "Candela: add pattern",
        callback = function()
            CandelaCommands.commands.add()
        end,
    })
    vim.api.nvim_set_keymap("n", "<leader>cdr", "", {
        noremap = true,
        silent = true,
        desc = "Candela: refresh patterns",
        callback = function()
            CandelaCommands.commands.refresh()
        end,
    })
    vim.api.nvim_set_keymap("n", "<leader>cdD", "", {
        noremap = true,
        silent = true,
        desc = "Candela: clear patterns",
        callback = function()
            CandelaCommands.commands.clear()
        end,
    })
    vim.api.nvim_set_keymap("n", "<leader>cdM", "", {
        noremap = true,
        silent = true,
        desc = "Candela: match all",
        callback = function()
            CandelaCommands.commands.match_all()
        end,
    })
    vim.api.nvim_set_keymap("n", "<leader>cdF", "", {
        noremap = true,
        silent = true,
        desc = "Candela: find all",
        callback = function()
            CandelaCommands.commands.find_all()
        end,
    })
    vim.api.nvim_set_keymap("n", "<leader>cdL", "", {
        noremap = true,
        silent = true,
        desc = "Candela: lightbox",
        callback = function()
            CandelaCommands.commands.lightbox()
        end,
    })
    vim.api.nvim_set_keymap("n", "<M-k>", "[l", {})
    vim.api.nvim_set_keymap("n", "<M-j>", "]l", {})
    vim.api.nvim_set_keymap("n", "<M-h>", "[q", {})
    vim.api.nvim_set_keymap("n", "<M-l>", "]q", {})
end

function M.set_patterns_keymaps(buffer)
    local CandelaUi = require("candela.ui")
    local CandelaCommands = require("candela.commands")
    vim.api.nvim_buf_set_keymap(buffer, "n", "q", "", {
        noremap = true,
        silent = true,
        desc = "Close Candela",
        callback = function()
            CandelaUi.hide_patterns()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "<ESC>", "", {
        noremap = true,
        silent = true,
        desc = "Close Candela",
        callback = function()
            CandelaUi.hide_patterns()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "a", "", {
        noremap = true,
        silent = true,
        desc = "Add Candela pattern",
        callback = function()
            CandelaCommands.commands.add()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "e", "", {
        noremap = true,
        silent = true,
        desc = "Edit Candela pattern",
        callback = function()
            CandelaCommands.commands.edit()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "c", "", {
        noremap = true,
        silent = true,
        desc = "Copy Candela pattern",
        callback = function()
            CandelaCommands.commands.copy()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "d", "", {
        noremap = true,
        silent = true,
        desc = "Delete Candela pattern",
        callback = function()
            CandelaCommands.commands.delete()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "D", "", {
        noremap = true,
        silent = true,
        desc = "Clear all Candela patterns",
        callback = function()
            CandelaCommands.commands.clear()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "C", "", {
        noremap = true,
        silent = true,
        desc = "Change Candela pattern color",
        callback = function()
            CandelaCommands.commands.change_color()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "h", "", {
        noremap = true,
        silent = true,
        desc = "Toggle Candela pattern highlight",
        callback = function()
            CandelaCommands.commands.toggle_highlight()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "l", "", {
        noremap = true,
        silent = true,
        desc = "Toggle Candela pattern lightbox",
        callback = function()
            CandelaCommands.commands.toggle_lightbox()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "r", "", {
        noremap = true,
        silent = true,
        desc = "Refresh patterns for current buffer",
        callback = function()
            CandelaCommands.commands.refresh()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "m", "", {
        noremap = true,
        silent = true,
        desc = "Candela match pattern in buffer",
        callback = function()
            CandelaCommands.commands.match()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "M", "", {
        noremap = true,
        silent = true,
        desc = "Candela match pattern in buffer",
        callback = function()
            CandelaCommands.commands.match_all()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "f", "", {
        noremap = true,
        silent = true,
        desc = "Candela find pattern in buffer",
        callback = function()
            CandelaCommands.commands.find()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "F", "", {
        noremap = true,
        silent = true,
        desc = "Candela find all patterns in buffer",
        callback = function()
            CandelaCommands.commands.find_all()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "L", "", {
        noremap = true,
        silent = true,
        desc = "Candela find all patterns in buffer",
        callback = function()
            CandelaCommands.commands.lightbox()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "?", "", {
        noremap = true,
        silent = true,
        desc = "Candela: display keymaps",
        callback = function()
            CandelaCommands.commands.help()
        end,
    })
end

function M.set_prompt_keymaps(buffer)
    local CandelaUi = require("candela.ui")
    vim.api.nvim_buf_set_keymap(buffer, "n", "q", "", {
        noremap = true,
        silent = true,
        desc = "Candela: close Prompt",
        callback = function()
            CandelaUi.hide_prompt()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "<ESC>", "", {
        noremap = true,
        silent = true,
        desc = "Candela: close Prompt",
        callback = function()
            CandelaUi.hide_prompt()
        end,
    })
end

return M
