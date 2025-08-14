-- Module for defining user configuration

-- add user config for closing lightbox when source buffer/window is closed

---@class CandelaConfig
---@field defaults table<string, any>
---@field options table<string, any>
---@field version { major: integer, minor: integer, patch: integer }

local M = {}
M.version = {}

M.defaults = {
    -- Candela-styled logs
    syntax_highlighting = true, -- true | false  TODO: implement
    -- Use unicode symbols in UI, set to nil to disable
    icons = {
        candela = "\u{1F56F}", -- patterns window title 🕯
        color = "\u{1F3A8}", -- color column header 🎨
        regex = "\u{1F300}", -- regex column header 🌀
        highlight = {
            header = "\u{1F4A1}", -- highlight column header 💡
            toggle_on = "\u{25C9}", -- highlight toggle on ◉
            toggle_off = "\u{25CB}", -- highlight toggle off ○
        },
        lightbox = {
            header = "\u{1F50D}", -- lightbox column header 🔍
            toggle_on = "\u{25C9}", -- lightbox toggle on ◉
            toggle_off = "\u{25CB}", -- lightbox toggle off ○
        },
    },
    -- Use log syntax highlighting
    window = {
        -- initial width of the patterns window
        width = math.floor(vim.o.columns * 0.5), -- integer
        -- minimum height (number of patterns) of the patterns window (initial height)
        min_height = 5, -- unsigned integer
        -- maximum height (number of patterns) of the patterns window
        --max_height = 30, -- unsigned integer
        max_height = 5, -- unsigned integer
        -- margin space between window and Neovim bounds when Neovim is too small to fit the window
        margin = 16, -- unsigned integer
        -- position of prompt window in relation to patterns window
        prompt_offset = "overlap", -- "overlap" | "border"
    },
    engine = {
        -- regex search engine to use; defaults to first found tool out of the list in order
        command = nil, -- "rg" | "ag" | "ugrep" | "ack" | "grep"
        -- extra args to pass to search engine; refer to your tool's manual
        -- every regex search will be run with a flag to include line numbers and set color off
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
        case = "system", -- "sensitive" | "ignore" | "smart" | "system"
        -- highlight entire line (end of line) or end of text
        hl_eol = false, -- true | false
    },
    lightbox = {
        -- how you want the lightbox window to break out
        view = "system-vsplit", -- "tab" | "system-split" | "system-vsplit" | "split-left" | "split-right" | "split-above" | "split-below"
        -- style to format the foldtext
        fold_style = "count", -- "fillchar" | "count" | "preview" | "detailed" | "nvim"
        -- fillchar for the foldtext
        fillchar = "-",
        -- custom foldtext function, if not nil and a valid function, will override fold_style
        custom_foldtext = nil, -- function()
    },
    -- file types to load Candela for  TODO: implement
    file_types = {
        ".log",
        ".txt",
    },
    palette = {
        -- replace default color palette or add to it
        use = "replace", -- "replace" | "prepend" | "append"  TODO: implement
        -- replace default color palette or add to it
        cycle = "constant", -- "constant" | "random"  TODO: implement
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
    local engines = {
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
---@return string?
local function get_default_engine(available)
    for _, engine in ipairs(available) do
        if engine[next(engine)] ~= nil then
            return next(engine)
        end
    end

    vim.notify("[Candela] no regex search tool found... how do you not at least have grep?", vim.log.levels.ERROR)
    vim.notify("[Candela] will not be loaded", vim.log.levels.ERROR)
    return nil
end

local function build_search_args(command, case_option)
    local args_map = {
        rg = { "--line-number", "--color=never" },
        ag = { "--numbers", "--nocolor" },
        ugrep = { "--line-number", "--color=never" },
        ack = { "--with-filename", "--nocolor" },
        grep = { "--line-number", "--color=never" },
    }

    local args = vim.deepcopy(args_map[command] or {})
    vim.list_extend(args, M.options.engine.args)

    local smartcase = vim.api.nvim_get_option_value("smartcase", {})
    local ignorecase = vim.api.nvim_get_option_value("ignorecase", {})

    if case_option == "ignore" or (case_option == "system" and ignorecase) then
        table.insert(args, "--ignore-case")
    elseif case_option == "smart" or (case_option == "system" and ignorecase and smartcase) then
        if command == "grep" then
            vim.notify(
                "grep does not support smart-case. Consider installing a faster regex search engine or modifying"
                .. "`case` in your user config to turn smart-case off. Proceeding with the case-sensitive args.",
                vim.log.levels.WARN
            )
        else
            table.insert(args, "--smart-case")
        end
    else
        if command == "rg" or command == "ag" then
            table.insert(args, "--case-sensitive")
        elseif command == "ack" then
            table.insert(args, "--no-ignore-case")
        end
    end

    return args
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

    args = build_search_args(command, opts.matching.case)
    return args
end

---@return CandelaConfig?
function M.setup(opts)
    M.version["major"] = 1
    M.version["minor"] = 0
    M.version["patch"] = 0

    M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
    local available = M.get_engine_versions()
    if M.options.engine.command == nil then
        M.options.engine.command = get_default_engine(available)
    end
    if M.options.engine.command == nil then
        return nil
    end
    M.options.engine.args = get_default_args(M.options)

    local candela_augroup = vim.api.nvim_create_augroup("Candela", { clear = true })
    vim.api.nvim_create_autocmd("OptionSet", {
        group = candela_augroup,
        pattern = { "ignorecase", "smartcase" },
        desc = "Update case-sensitivity globals when user changes system options",
        callback = function()
            if M.options.matching.case == "system" then
                M.options.engine.args = build_search_args(M.options.engine.command, M.options.matching.case)
                require("candela.finder").set_candela_case()
                require("candela.ui").set_system_case_changed()
            end
        end,
    })

    return M.options
end

-- TODO: move mappings to mappings.lua file
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
            CandelaUi.match_selected()
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
            CandelaUi.find_selected()
            vim.api.nvim_cmd({ cmd = "lnext" }, {})
            vim.api.nvim_cmd({ cmd = "lopen" }, {})
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "L", "", {
        noremap = true,
        silent = true,
        desc = "Candela open/close lightbox",
        callback = function()
            CandelaCommands.commands.lightbox()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "i", "", {
        noremap = true,
        silent = true,
        desc = "Import patterns from file",
        callback = function()
            CandelaUi.import()
        end,
    })
    vim.api.nvim_buf_set_keymap(buffer, "n", "e", "", {
        noremap = true,
        silent = true,
        desc = "Export patterns to file",
        callback = function()
            CandelaUi.export()
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
    vim.api.nvim_buf_set_keymap(buffer, "n", "<TAB>", "", {
        noremap = true,
        silent = true,
        desc = "Candela: selected current pattern",
        callback = function()
            CandelaUi.toggle_select_pattern()
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
