<div align="center">

# Candela

<img alt="Candela Logo" height="200" src="/assets/candela-logo.png" />

#### regex highlighter. designed for efficient log analysis.

</div>

---

Inspired by the [Log
Analysis](https://marketplace.visualstudio.com/items?itemName=XinyaYang0506.log-analysis) VSCode
extension. I couldn't find any plugins for tracking and highlighting lines based on multiple regexes
so I made this.

[candela-demo.webm](https://github.com/user-attachments/assets/e2b1a8e5-bf25-4e76-9672-647ab8ef2fdc)

* [requirements](#requirements)
* [installation](#installation)
* [config](#config)
* [keymaps](#keymaps)
* [commands](#commands)
* [api](#api)
* [features](#features)
* [acknowledgements](#acknowledgements)

## requirements

* Neovim >= 0.10
* regex search tool ([ripgrep](https://github.com/BurntSushi/ripgrep),
[ag](https://github.com/ggreer/the_silver_searcher), [ugrep](https://github.com/Genivia/ugrep),
[ack](https://beyondgrep.com/install/), [grep](https://www.gnu.org/software/grep/) <-- you should at least have this one)

that's it.

## installation

You probably know how to use your preferred package manager. The GitHub repo
is `KieranCanter/candela.nvim`.  No `setup()` required e.g. with `lazy.nvim`:

```lua
{ "KieranCanter/candela.nvim" }
```

Or with config changes:

```lua
{
    "KieranCanter/candela.nvim",
    opts = {...},
}
```

## config

All options are optional. Candela works out of the box with sensible defaults. For lua_ls
autocomplete in your config, add `---@type Candela.Config` above your `opts` table. See
"candela-configuration" in
[`doc/candela.txt`](https://github.com/KieranCanter/candela.nvim/blob/main/doc/candela.txt) for
more info on these options.

```lua
---@type Candela.Config
opts = {
    window = {
        width = 0.5,          -- fraction of screen width
        min_height = 5,       -- starting/minimum height in buffer lines
        max_height = 30,      -- max height in buffer lines
        margin = 16,          -- margin between Candela UI and Neovim UI
    },
    engine = {
        command = nil,         -- auto-detected: rg > ag > ugrep > ack > grep
        args = {},             -- args passed to regex command
    },
    matching = {
        auto_refresh = false,  -- refresh highlights on buffer switch
        case = "system",       -- "system" | "sensitive" | "ignore" | "smart"
        hl_eol = false,        -- highlight entire line vs matched text only
    },
    lightbox = {
        default_view = "system-vsplit",  -- default split for UI keymap
        fold_style = "nvim",             -- "nvim" | "fillchar" | "count" | "preview" | "detailed"
        fillchar = "-",                  -- foldtext fillchar (see "fold" in `:h fillchars`)
        custom_foldtext = nil,           -- function used to define foldtext (`:h 'foldtext'`)
    },
    icons = {
        nerd_font = false,     -- set true for default nerd font icons
        ...,
    },
    palette = {
        use = "replace",       -- "replace" | "prepend" | "append"
        cycle = "constant",    -- "constant" | "random"
        colors = { dark = { ... }, light = { ... } }, -- available colors (hex codes)
        swatches = { dark = { ... }, light = { ... } }, -- named color shortcuts
    },
    syntax_highlighting = {
        enabled = true,                  -- enable built-in log syntax highlighting
        file_types = { ".log", "text" }, -- file types to enabled syntax highlighting for
    },
}
```

<details>
<summary>Default icons (<code>nerd_font == true</code>)</summary>

```lua
icons = {
    candela = "\u{f05e2}", -- 󰗢
    regex = "\u{f069}", -- 
    color = "\u{e22b}", -- 
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
    selection = {
        toggle_on = "\u{ea71}", -- 
        toggle_off = "\u{eabc}", -- 
    },
}
```

</details>

<details>
<summary>Default icons (<code>nerd_font == false</code>)</summary>

```lua
icons = {
    candela = "\u{1F56F}", -- 🕯
    regex = "\u{2728}", -- ✨
    color = "\u{1F3A8}", -- 🎨
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
    selection = {
        toggle_on = "\u{25C9}", -- ◉
        toggle_off = "\u{25CB}", -- ○
    },
}
```

</details>

<details>
<summary>Default palette colors and swatches</summary>

```lua
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
}
```

</details>

## keymaps

Candela only includes pre-set literal keymaps for UI interaction that are attached to the UI window
buffer so as to not clobber existing keymaps you may have set. These can be seen in the help menu
with the user command `:Candela help` or by pressing `g?` with the UI open.

### UI buffer keymaps

| Key | Action |
|-----|--------|
| `<ESC>`, `<C-C>` | Close UI |
| `g?` | Toggle help menu |
| `<C-H>` | Toggle highlight on pattern |
| `<C-L>` | Toggle lightbox on pattern |
| `<M-l>` | Open lightbox window |
| `<M-c>` | Change pattern color (with autocomplete) |
| `<C-R>` | Refresh highlights |
| `<C-I>` | Import patterns from file |
| `<C-E>` | Export patterns to file |
| `<Tab>` | Select pattern and move down |
| `<S-Tab>` | Select pattern and move up |
| `<C-A>` | Select all / deselect all |
| `<C-N>` | Vim match (selected or current) |
| `<C-Q>` | Send to location list (selected or current) |
| `:w` | Write buffer changes to pattern list |

### `<Plug>` keymaps

You are not left helpless though, as there are pre-set `<Plug>` keymaps provided that you may hook
into your own key combination.

| `<Plug>` | Action |
|----------|--------|
| `<Plug>CandelaUi` | Toggle UI window |
| `<Plug>CandelaRefresh` | Refresh patterns in current buffer |
| `<Plug>CandelaClear` | Clear all patterns |
| `<Plug>CandelaLightbox` | Toggle lightbox window |
| `<Plug>CandelaHelp` | Open help menu |

As an example, I set my keymaps as such:

```lua
vim.keymap.set("n", "<leader>cds", "<Plug>CandelaUi")
vim.keymap.set("n", "<leader>cdr", "<Plug>CandelaRefresh")
vim.keymap.set("n", "<leader>cdd", "<Plug>CandelaClear")
vim.keymap.set("n", "<leader>cdl", "<Plug>CandelaLightbox")
vim.keymap.set("n", "<leader>cdh", "<Plug>CandelaHelp")
```

## commands
See "candela-commands" in
[`doc/candela.txt`](https://github.com/KieranCanter/candela.nvim/blob/main/doc/candela.txt) for
more details on each command.

<details>
<summary>Command List</summary>

| Command | Description |
|---------|-------------|
| `:Candela add [regex-or-index] [color] [highlight] [lightbox]` | Add a pattern |
| `:Candela edit <regex-or-index> <new_regex>` | Edit a pattern's regex |
| `:Candela copy <regex-or-index> <new_regex>` | Copy a pattern with a new regex |
| `:Candela delete <regex-or-index> [more...]` | Delete patterns |
| `:Candela clear` | Clear all patterns |
| `:Candela change_color <regex-or-index> <color>` | Change a pattern's color |
| `:Candela toggle_highlight <regex-or-index>` | Toggle highlight on a pattern |
| `:Candela toggle_lightbox <regex-or-index>` | Toggle lightbox on a pattern |
| `:Candela vimmatch [regex-or-index] [more...]` | Set vim search register and jump |
| `:Candela loclist [regex-or-index] [more...]` | Populate location list |
| `:Candela lightbox [view]` | Toggle lightbox (view: split-right, tab, etc.) |
| `:Candela import <path>` | Import patterns from a .lua file |
| `:Candela export [path]` | Export patterns to a .lua file |
| `:Candela help` | Open help menu |
| `:Candela health` | Run health check |

</details>

## api

See "candela-api" in
[`doc/candela.txt`](https://github.com/KieranCanter/candela.nvim/blob/main/doc/candela.txt) for
more details on each API function.

<details>
<summary><code>patterns</code></summary>

```lua
local patterns = require("candela.patterns")
patterns.add({regex}, {color?}, {highlight?}, {lightbox?})
patterns.edit({old_regex}, {new_regex})
patterns.delete({regex})
patterns.clear()
patterns.get({regex})
patterns.count()
patterns.resolve({index_or_regex})
patterns.change_color({regex}, {new_color})
patterns.toggle_highlight({regex})
patterns.toggle_lightbox({regex})
patterns.regen_colors()
patterns.add_to_selected({regex})
patterns.remove_from_selected({regex})
patterns.add_all_to_selected()
patterns.clear_selected()
patterns.get_selected()
```
</details>

<details>
<summary><code>ui</code></summary>

```lua
local ui = require("candela.ui")
ui.open()
ui.close()
ui.toggle()
ui.resize({width?}, {height?})
ui.render({entries})
ui.get_lines()
ui.render_selection({selected_set})
ui.toggle_selection({row}, {selected})
ui.clear_selection()
ui.help()
```
</details>

<details>
<summary><code>highlighter</code></summary>

```lua
local highlighter = require("candela.highlighter")
highlighter.highlight({regex})
highlighter.remove({regex})
highlighter.remove_all()
highlighter.toggle_highlights({regex}, {toggle})
highlighter.update_color({regex})
highlighter.refresh()
highlighter.refresh_ui()
```

</details>

<details>
<summary><code>lightbox</code></summary>

```lua
local lightbox = require("candela.lightbox")
lightbox.open({view})
lightbox.close()
lightbox.toggle({view?})
lightbox.toggle_pattern({regex})
lightbox.refresh()
lightbox.update_folds()
```

</details>

<details>
<summary><code>locator</code></summary>

```lua
local locator = require("candela.locator")
locator.vimmatch({regexes})
locator.loclist({regexes})
```

</details>

<details>
<summary><code>io</code></summary>

```lua
local cdio = require("candela.io")
cdio.import({path})
cdio.export({path?})
cdio.clear()
```

</details>

## features

* **buffer-direct editing**: edit regexes directly in the UI buffer, `:w` to apply
* **multi-regex management**: add, edit, delete, copy patterns
* **pattern selection**: select patterns with `<Tab>` for aggregate searches
* **multiple regex engines**: ripgrep, ag, ugrep, ack, grep
* **customizable colors**: palette cycling and named swatches
* **lightbox**: fold-based view showing only matched lines
* **import/export**: save and load pattern lists
* **syntax highlighting**: built-in highlighting for common log formats
* **nerd font defaults**: configurable icons with nerd font and non-nerd font default options

### lightbox

The "Lightbox" is an integral feature of Candela that allows you to dissect the lines you care about
into their own window, with none of the noise cluttering your view.

Open it with `<M-l>` from the UI or `:Candela lightbox [view]`.

View options: `split-left`, `split-right`, `split-above`, `split-below`, `system-split`,
`system-vsplit`, `tab`. If `view` is empty, your config's `default_view` is used (defaults to
`system-vsplit`)

When you open the lightbox window, all lines containing patterns that have the lightbox toggle set
to "on" will appear in a new window split or tab, but only those lines. All unmatched lines will be
folded, leaving you with a stripped down view containing only what you're looking for. Even the
foldtext can be a bit noisy, so you can also configure the foldtext used to reduce clutter and
further isolate the logs you care about.

The highlight toggle is still completely functional within the lightbox window. Setting a pattern's
highlight toggle to "off" will remove the highlight from the matched line, but it won't remove it
from the lightbox window. This can be useful if you want the matched line to still be displayed as
contextual information but don't want it to have the same emphasis or importance that highlighted
lines have.

Keep in mind, the lightbox window is only that, a window. It reuses the same base buffer that is
currently being searched/highlighted, so any changes made to the original will result in the
lightbox as well.

### import/export

Candela provides a convenient way to import and export patterns should you want to reuse a list of
commonly used patterns or don't want to have to re-enter a long list when exiting and opening
Neovim. These patterns exist in the form of a `.lua` file that returns a list of
[`Candela.Pattern`](https://github.com/KieranCanter/candela.nvim/blob/main/lua/candela/pattern.lua#L1-L6)
data structures.

```lua
---@class Candela.Pattern
---@field regex string
---@field color string
---@field highlight boolean
---@field lightbox boolean
---@field count integer
```

Use `<C-I>` and `<C-E>` from the UI for quick access with file path autocomplete, or use the user
commands `:Candela import` and `:Candela export` directly.

<details>
<summary>Example Pattern File</summary>

```lua
-- my-saved-patterns.lua
return {
    {
        "my.*regex",
        "#FFFF00",
        true,
        true,
    },
    {
        "search for (this|that)?",
        "#676767",
        false,
        true,
    },
}
```

</details>

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
