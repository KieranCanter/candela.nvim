<div align="center">

# Candela

#### regex highlighter. designed for efficient log analysis.

</div>

---

Inspired by the [Log
Analysis](https://marketplace.visualstudio.com/items?itemName=XinyaYang0506.log-analysis) VSCode
extension. I couldn't find any plugins for tracking and highlighting lines based on multiple regexes
so I made this.

https://github.com/user-attachments/assets/064e7a87-c728-4a63-a9a6-c76a6cebe935

* [requirements](#requirements)
* [installation](#installation)
* [config](#config)
* [keymaps](#keymaps)
* [commands](#commands)
* [api](#api)
* [features](#features)
* [acknowledgements](#acknowledgements)

## requirements:

* regex search tool ([ripgrep](https://github.com/BurntSushi/ripgrep),
[ag](https://github.com/ggreer/the_silver_searcher), [ugrep](https://github.com/Genivia/ugrep),
[ack](https://beyondgrep.com/install/), grep)

that's it.

## installation

You probably know how to use your preferred package manager. The GitHub repo
is `KieranCanter/candela.nvim`. The `lazy.nvim` snippet is:

```Lua
    {
        "KieranCanter/candela.nvim",
        opts = {},
    }
```

## config

See ["candela-config-options" in
`doc/candela.txt`](https://github.com/KieranCanter/candela.nvim/blob/main/doc/candela.txt#L187) for
more info on what each option is used for and valid values. I will leave you with the defaults here:

```Lua
local defaults = {
    window = {
        width = 0.5,
        min_height = 5,
        max_height = 30,
        margin = 16,
        min_count_width = 4,
        toggle_width = 6,
        prompt_offset = "overlap",
    },
    engine = {
        command = nil,
        args = {},
    },
    matching = {
        auto_refresh = false,
        delete_confirmation = true,
        clear_confirmation = true,
        case = "system",
        hl_eol = false,
    },
    lightbox = {
        view = "system-vsplit",
        fold_style = "nvim",
        fillchar = "-",
        custom_foldtext = nil,
    },
    icons = vim.g.have_nerd_font
            and {
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
            }
        or {
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
```

## keymaps

Candela only includes pre-set literal keymaps for UI interaction that are attached to the UI window
as to not clobber existing keymaps you may have set. These can be seen in the help menu with the
user command `:Candela help` or by pressing `?` with the UI open.

You are not left helpless though, as there are pre-set `<Plug>` keymaps provided that you may hook
into your own key combination.

| **`<Plug>`**            | Action                             |
| ----------------------- | ---------------------------------- |
| `<Plug>CandelaUI`       | Toggle UI window                   |
| `<Plug>CandelaAdd`      | Add a pattern in UI                |
| `<Plug>CandelaRefresh`  | Refresh patterns in current buffer |
| `<Plug>CandelaClear`    | Clear all patterns                 |
| `<Plug>CandelaMatchAll` | Vim match all patterns             |
| `<Plug>CandelaFindAll`  | Send all patterns to location list |
| `<Plug>CandelaLightbox` | Toggle lightbox window             |
| `<Plug>CandelaHelp`     | Open UI keymaps menu               |

As an example, I set my keymaps as such:

```Lua
local candela_keymaps = {
    {
        lhs = "<leader>cds",
        rhs = "<Plug>CandelaUI",
        desc = "[Candela] toggle UI window",
    },
    {
        lhs = "<leader>cda",
        rhs = "<Plug>CandelaAdd",
        desc = "[Candela] add pattern in UI",
    },
    {
        lhs = "<leader>cdR",
        rhs = "<Plug>CandelaRefresh",
        desc = "[Candela] refresh patterns in current buffer",
    },
    {
        lhs = "<leader>cdD",
        rhs = "<Plug>CandelaClear",
        desc = "[Candela] clear all patterns",
    },
    {
        lhs = "<leader>cdM",
        rhs = "<Plug>CandelaMatchAll",
        desc = "[Candela] vim match all patterns",
    },
    {
        lhs = "<leader>cdF",
        rhs = "<Plug>CandelaFindAll",
        desc = "[Candela] find all patterns and send to location list",
    },
    {
        lhs = "<leader>cdL",
        rhs = "<Plug>CandelaLightbox",
        desc = "[Candela] toggle lightbox window",
    },
    {
        lhs = "<leader>cd?",
        rhs = "<Plug>CandelaHelp",
        desc = "[Candela] open help menu",
    },
}

for _, keymap in ipairs(candela_keymaps) do
    vim.api.nvim_set_keymap("n", keymap.lhs, keymap.rhs, { desc = keymap.desc })
end
```

## commands

See ["candela-commands" in
`doc/candela.txt`](https://github.com/KieranCanter/candela.nvim/blob/main/doc/candela.txt#L349) for
more details on each command.


| **User Command**                                                                        |
|-----------------------------------------------------------------------------------------|
| `:Candela add [regex: string] [color: string] [highlight: boolean] [lightbox: boolean]` |
| `:Candela edit <index: integer \| regex: string> [new_regex: string]`                   |
| `:Candela copy <index: integer \| regex: string> [new_regex: string]`                   |
| `:Candela delete <index: integer> [indices: integer]...`                                |
| `:Candela clear`                                                                        |
| `:Candela change_color <index: integer \| regex: string> [new_color: string]`           |
| `:Candela toggle_highlight <index: integer \| regex: string>`                           |
| `:Candela toggle_lightbox <index: integer \| regex: string>`                            |
| `:Candela match <regex: string> [more_regex: string]...`                                |
| `:Candela match_all`                                                                    |
| `:Candela find <regex: string> [more_regex: string]...`                                 |
| `:Candela find_all`                                                                     |
| `:Candela lightbox`                                                                     |
| `:Candela import <path/to/import_file.lua>`                                             |
| `:Candela export <path/to/export_file.lua>`                                             |
| `:Candela help`                                                                         |
| `:Candela health`                                                                       |

## api

See ["candela-api" in
`doc/candela.txt`](https://github.com/KieranCanter/candela.nvim/blob/main/doc/candela.txt#L438) for
more details on each API function. The following definitions will assume you have brought Candela
into scope with `local candela = require("candela")`.

#### `candela.ui.<function>`

```Lua
candela.ui.show_patterns()
candela.ui.hide_patterns()
candela.ui.hide_prompt()
candela.ui.toggle()
candela.ui.toggle_select_pattern({index_or_regex})
candela.ui.locate()
candela.ui.add()
candela.ui.edit()
candela.ui.copy()
candela.ui.delete({ask})
candela.ui.clear({ask})
candela.ui.refresh({force?}, {keep_base_buffer?})
candela.ui.change_color()
candela.ui.toggle_highlight()
candela.ui.toggle_lightbox()
candela.ui.locate({all}, {command})
candela.ui.import()
candela.ui.export()
candela.ui.help()
```

#### `candela.patterns.<function>`

```Lua
candela.patterns.add({regex}, {color?}, {highlight?}, {lightbox?})
candela.patterns.edit({index_or_regex}, {new_regex})
candela.patterns.delete({index_or_regex})
candela.patterns.clear()
candela.patterns.change_color({index_or_regex}, {new_color})
candela.patterns.toggle_highlight({index_or_regex})
candela.patterns.toggle_lightbox({index_or_regex})
```

## features

* multi-regex management
* rapid cycling through matches
* support for multiple different regex engines
* customizable colors including palette (color set) and swatches (conveniently define a color with a
simple string)
* "Lightbox"
* saving/loading patterns
* syntax highlighting

### lightbox

The "Lightbox" is an integral feature of Candela that allows you to dissect the lines you care about
into their own window, with none of the noise cluttering your view. Any new pattern you create will
have the lightbox toggled on by default unless you override it.

When you open the lightbox window, all lines containing patterns that have the lightbox toggle set
to "on" will appear in a new window split or tab, depending on your user configuration (defaults to
split using your Neovim's `splitright` setting), but only those lines. All unmatched lines will be
folded, leaving you with a stripped down view containing only what you're looking for.

In addition, the highlight toggle is still completely functional within the lightbox window. Setting
a pattern's highlight toggle to "off" will remove the highlight from the matched line, but it won't
remove it from the lightbox window. This can be useful if you want the matched line to still be
displayed as contextual information but don't want it to have the same emphasis or importance that
highlighted lines have.

Keep in mind, the lightbox window is only that, a window. It reuses the same base buffer that is
currently being searched/highlighted, so any changes made to the original will result in the
lightbox as well.

Note: the foldtext can also be customized to your liking.

### import/export

Candela provides a convenient way to import and export patterns should you want to reuse a list of
commonly used patterns or don't want to have to re-enter a long list when exiting and opening
Neovim.

The UI API provides convenience functions for opening the import/export prompt window when the UI is
already open, but this would best be used for creating your own UI keymap.

In most other scenarios where you want to immediately import or export patterns on the fly, you'd
probably prefer to use the user commands `:Candela import` and `:Candela export`. This is useful if
you don't want to have to open the UI to select your file. The autocomplete will populate with file
paths from your current working directory.

Most likely the most practical use would be to add a line to your config that automatically imports
a list of patterns with the user command so you can immediately refresh on your desired buffer, or
even set your own keymaps by directly calling these user commands, but Candela does include a
`<Plug>` mapping for this use-case.

### syntax highlighting

Candela includes default syntax highlighting for common log formats. The specifics can be viewed in
the `lua/candela/syntax.lua` file and will effectively match many different tokens including dates
and times of many different formats, system info (host, facility, process), log levels/severity,
primitive types (integers, booleans, floats, etc.), strings, and entities like URLs, internet
addresses, file paths, hashes, etc.

Syntax highlighting can be disabled in your user config and you may specify file types/extensions to
activate syntax highlighting on.

## acknowledgements

These projects were extremely useful resources that helped me during the
development of Candela:

* [grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim)
* [snacks.nvim](https://github.com/folke/snacks.nvim/tree/main)
* [harpoon2](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)
* [log-highlight.nvim](https://github.com/fei6409/log-highlight.nvim)
