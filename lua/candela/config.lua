---@class CandelaConfig
---@field defaults table<string, any>
---@field options table<string, any>
---@field version { major: integer, minor: integer, patch: integer }

local M = {}
M.version = {}

M.defaults = {
    -- Candela syntax highlight
    syntax_highlighting = {  -- TODO: implement
        enabled = true, -- true | false
        -- file type extensions to activate syntax highlighting for
        file_types = { "log", "txt" }, -- string
    },
    -- Use icons in UI, set to nil to disable
    icons = vim.g.have_nerd_font -- Uses nerd font icons if nerd font is installed
            and {
                candela = "\u{f05e2}", -- patterns window title 󰗢
                color = "\u{e22b}", -- color header 
                regex = "\u{f069}", -- regex header 
                highlight = {
                    header = "\u{ea61}", -- highlight header 
                    toggle_on = "\u{f1a25}", -- highlight toggle on 󱨥
                    toggle_off = "\u{f1a26}", -- highlight toggle off 󱨦
                },
                lightbox = {
                    header = "\u{e68f}", -- lightbox header 
                    toggle_on = "\u{f1a25}", -- highlight toggle on 󱨥
                    toggle_off = "\u{f1a26}", -- highlight toggle off 󱨦
                },
            }
        or { -- If no nerd font, uses unicode emojis
            candela = "\u{1F56F}", -- patterns window title 🕯
            color = "\u{1F3A8}", -- color header 🎨
            regex = "\u{2728}", -- regex header ✨
            highlight = {
                header = "\u{1F4A1}", -- highlight header 💡
                toggle_on = "\u{25C9}", -- highlight toggle on ◉
                toggle_off = "\u{25CB}", -- highlight toggle off ○
            },
            lightbox = {
                header = "\u{1F50D}", -- lightbox header 🔍
                toggle_on = "\u{25C9}", -- highlight toggle on ◉
                toggle_off = "\u{25CB}", -- highlight toggle off ○
            },
        },
    window = {
        -- initial width of the patterns window as percentage of Neovim window width
        width = 0.5, -- number
        -- minimum height (number of patterns) of the patterns window (initial height)
        min_height = 5, -- unsigned integer
        -- maximum height (number of patterns) of the patterns window
        max_height = 30, -- unsigned integer
        -- margin space between window and Neovim bounds when Neovim is too small to fit the window
        margin = 16, -- unsigned integer
        -- minimum width to allocate to the "count" column
        min_count_width = 4, -- unsigned integer
        -- width of the toggle columns
        toggle_width = 5, -- unsigned integer
        -- position of prompt window in relation to patterns window
        prompt_offset = "overlap", -- "overlap" | "border"
    },
    engine = {
        -- regex search engine to use; defaults to first found tool out of the list in order
        command = nil, -- "rg" | "ag" | "ugrep" | "ack" | "grep"
        -- extra args to pass to search engine; refer to your tool's manual
        -- every regex search will be run with a flag to include line numbers and set color off
        args = {}, -- defaults to flags that display line numbers and remove color (flags depend on tool above)
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
    -- file types to load Candela for TODO: implement
    file_types = {
        ".log",
        ".txt",
    },
    palette = {
        -- replace default color palette or add to it
        use = "replace", -- "replace" | "prepend" | "append"
        -- replace default color palette or add to it
        cycle = "constant", -- "constant" | "random"
        -- list of colors to use for dark/light mode
        colors = {
            dark = {
                "#9D4564", -- DARK MAUVE
                "#A1464C", -- LIGHT MAROON
                "#9E4D21", -- SIENNA
                "#935800", -- MUD
                "#7F6400", -- MUSTARD
                "#6C6C00", -- MOSS
                "#4C7522", -- LEAF GREEN
                "#257A3F", -- JEWEL GREEN
                "#007C6A", -- AQUAMARINE
                "#007690", -- OCEAN
                "#3368AB", -- MUTED BLUE
                "#565FAC", -- DUSKY BLUE
                "#7156A3", -- DARK LAVENDER
                "#805098", -- EGGPLANT
                "#94487C", -- ROUGE
            },
            light = {
                "#F08FAE", -- PINK SHERBET
                "#F49093", -- SEA PINK
                "#F0986D", -- TANGERINE
                "#E2A25D", -- DESERT
                "#CBAE5E", -- GOLD
                "#B6B75F", -- OLIVE
                "#94C16F", -- PISTACHIO
                "#75C787", -- MANTIS
                "#65C5B1", -- NEPTUNE
                "#64BFDB", -- BLUISH CYAN
                "#7CB4FD", -- CRYSTAL BLUE
                "#9DAAFE", -- PERIWINKLE
                "#BBA0F3", -- LILAC
                "#CD9AE7", -- BABY PURPLE
                "#E592C8", -- LIGHT ORCHID
            },
        },
        swatches = {
            dark = {
                GRAY = "#676767",
                RED = "#A1454F",
                BLUE = "#016DA6",
                YELLOW = "#7B6600",
                GREEN = "#2A793C",
                ORANGE = "#9A510B",
                PURPLE = "#7055A3",
            },
            light = {
                GRAY = "#B1B1B1",
                RED = "#F59282",
                BLUE = "#3BC3E5",
                YELLOW = "#C6B14D",
                GREEN = "#82C57C",
                ORANGE = "#EC9C60",
                PURPLE = "#AAA5FB",
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

    if case_option == "smart" or (case_option == "system" and ignorecase and smartcase) then
        if command == "grep" then
            vim.notify(
                "grep does not support smart-case. Consider installing a faster regex search engine or modifying"
                    .. "`case` in your user config to turn smart-case off. Proceeding with the case-sensitive args.",
                vim.log.levels.WARN
            )
        else
            table.insert(args, "--smart-case")
        end
    elseif case_option == "ignore" or (case_option == "system" and ignorecase) then
        table.insert(args, "--ignore-case")
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
    if M.options.engine.command == nil then -- if engine command is still nil, no engine found
        return nil
    end
    vim.defer_fn(function() -- defer to get proper neovim user options
        M.options.engine.args = get_default_args(M.options)
    end, 0)

    vim.api.nvim_create_autocmd("OptionSet", {
        group = require("candela.init").CANDELA_AUGROUP,
        pattern = { "ignorecase", "smartcase" },
        desc = "Update case-sensitivity globals when user changes system options",
        callback = function()
            if M.options.matching.case == "system" then
                M.options.engine.args = {}
                M.options.engine.args = build_search_args(M.options.engine.command, M.options.matching.case)
                require("candela.finder").set_candela_case()
            end
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = require("candela.init").CANDELA_AUGROUP,
        desc = "Refresh Candela when color scheme changes",
        callback = function()
            require("candela.pattern_list").setup(M.options)
            require("candela.ui").regen_colors()
        end,
    })

    return M.options
end

return M
