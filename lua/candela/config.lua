--# selene: allow(bad_string_escape)

local M = {}

M.version = { major = 2, minor = 0, patch = 0, pre = "alpha.2" }
M.options = nil

M.defaults = {
    window = {
        width = 0.5,
        min_height = 5,
        max_height = 30,
        margin = 16,
    },
    engine = {
        command = nil,
        args = {},
    },
    matching = {
        auto_refresh = false,
        case = "system",
        hl_eol = false,
    },
    lightbox = {
        view = "system-vsplit",
        fold_style = "nvim",
        fillchar = "-",
        custom_foldtext = nil,
    },
    icons = vim.g.have_nerd_font and {
        candela = "\u{f05e2}", -- 󰗢
        color = "\u{e22b}", -- 
        regex = "\u{f069}", -- 
        highlight = {
            header = "\u{ea61}", -- 
            toggle_on = "\u{f1a25}", -- 󱨥
            toggle_off = "\u{f1a26}", -- 󱨦
        },
        lightbox = {
            header = "\u{e68f}", -- 
            toggle_on = "\u{f1a25}", -- 󱨥
            toggle_off = "\u{f1a26}", -- 󱨦
        },
    } or {
        candela = "\u{1F56F}", -- 🕯
        color = "\u{1F3A8}", -- 🎨
        regex = "\u{2728}", -- ✨
        highlight = {
            header = "\u{1F4A1}", -- 💡
            toggle_on = "\u{25C9}", -- ◉
            toggle_off = "\u{25CB}", -- ○
        },
        lightbox = {
            header = "\u{1F50D}", -- 🔍
            toggle_on = "\u{25C9}", -- ◉
            toggle_off = "\u{25CB}", -- ○
        },
    },
    palette = {
        use = "replace",
        cycle = "constant",
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
    syntax_highlighting = {
        enabled = true,
        file_types = { ".log", "text" },
    },
}

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
        local name = next(engine)
        local version = vim.fn.system(name .. " --version"):match(pattern)
        if version then
            table.insert(available, { [name] = { engine[name], version } })
        end
    end

    return available
end

local function detect_engine(available)
    for _, engine in ipairs(available) do
        if engine[next(engine)] then
            return next(engine)
        end
    end
    vim.notify(
        "[Candela] no regex search tool found... how do you not at least have grep? Aborting.",
        vim.log.levels.ERROR
    )
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
            vim.notify("[Candela] grep does not support smart-case, using case-sensitive", vim.log.levels.WARN)
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

function M.rebuild_args()
    if M.options then
        M.options.engine.args = build_search_args(M.options.engine.command, M.options.matching.case)
    end
end

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})

    if not M.options.engine.command then
        M.options.engine.command = detect_engine(M.get_engine_versions())
    end
    if not M.options.engine.command then
        M.options = nil
        return nil
    end

    vim.defer_fn(function()
        M.options.engine.args = build_search_args(M.options.engine.command, M.options.matching.case)
    end, 0)

    local augroup = require("candela").augroup

    vim.api.nvim_create_autocmd("OptionSet", {
        group = augroup,
        pattern = { "ignorecase", "smartcase" },
        desc = "Update case-sensitivity globals when user changes system options",
        callback = function()
            if M.options.matching.case == "system" then
                M.rebuild_args()
                require("candela.locator").set_candela_case()
            end
        end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = augroup,
        desc = "Refresh Candela when color scheme changes",
        callback = function()
            require("candela.patterns").regen_colors()
        end,
    })

    if M.options.syntax_highlighting.enabled then
        require("candela.syntax").enable(M.options.syntax_highlighting)
    end

    return M.options
end

return M
