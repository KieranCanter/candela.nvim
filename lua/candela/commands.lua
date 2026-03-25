local M = {}

local function string2bool(val)
    if not val then
        return nil
    end
    val = val:lower()
    return val == "true" or val == "1" or val == "yes" or val == "on"
end

local function complete_patterns()
    local regexes = {}
    for regex, _ in pairs(require("candela.patterns").patterns) do
        table.insert(regexes, (regex:gsub("%s", "\\ ")))
    end
    return regexes
end

local function filter(items, lead)
    return vim.iter(items)
        :filter(function(v)
            return v:find(lead) ~= nil
        end)
        :totable()
end

local function resolve(val)
    return require("candela.patterns").resolve(val)
end

M.commands = {
    add = {
        impl = function(subargs)
            if #subargs == 0 or #subargs > 4 then
                vim.notify("[Candela] Usage: Candela add <regex> [color] [highlight] [lightbox]", vim.log.levels.ERROR)
                return
            end
            local regex = require("candela.patterns").add(
                subargs[1],
                subargs[2],
                string2bool(subargs[3]),
                string2bool(subargs[4])
            )
            if not regex then
                return
            end
            local hl = require("candela.highlighter")
            hl.highlight(regex)
            hl.refresh_ui()
        end,
    },
    edit = {
        impl = function(subargs)
            if #subargs ~= 2 then
                vim.notify("[Candela] Usage: Candela edit <index|regex> <new_regex>", vim.log.levels.ERROR)
                return
            end
            local regex = resolve(subargs[1])
            if not regex then
                return
            end
            local hl = require("candela.highlighter")
            hl.remove(regex)
            local new = require("candela.patterns").edit(regex, subargs[2])
            if new then
                hl.highlight(new)
                hl.refresh_ui()
            end
        end,
        complete = function(lead)
            return filter(complete_patterns(), lead)
        end,
    },
    copy = {
        impl = function(subargs)
            if #subargs ~= 2 then
                vim.notify("[Candela] Usage: Candela copy <index|regex> <new_regex>", vim.log.levels.ERROR)
                return
            end
            local src_regex = resolve(subargs[1])
            if not src_regex then
                return
            end
            local src = require("candela.patterns").get(src_regex)
            if not src then
                return
            end
            local new = require("candela.patterns").add(subargs[2], src.color, src.highlight, src.lightbox)
            if new then
                local hl = require("candela.highlighter")
                hl.highlight(new)
                hl.refresh_ui()
            end
        end,
        complete = function(lead)
            return filter(complete_patterns(), lead)
        end,
    },
    delete = {
        impl = function(subargs)
            if #subargs == 0 then
                vim.notify("[Candela] Usage: Candela delete <index|regex> [more...]", vim.log.levels.ERROR)
                return
            end
            local hl = require("candela.highlighter")
            for _, val in ipairs(subargs) do
                local regex = resolve(val)
                if regex then
                    hl.remove(regex)
                    require("candela.patterns").delete(regex)
                end
            end
            hl.refresh_ui()
        end,
        complete = function(lead)
            return filter(complete_patterns(), lead)
        end,
    },
    clear = {
        impl = function()
            local hl = require("candela.highlighter")
            hl.remove_all()
            require("candela.patterns").clear()
            hl.refresh_ui()
        end,
    },
    change_color = {
        impl = function(subargs)
            if #subargs ~= 2 then
                vim.notify("[Candela] Usage: Candela change_color <index|regex> <color>", vim.log.levels.ERROR)
                return
            end
            local regex = resolve(subargs[1])
            if not regex then
                return
            end
            local p = require("candela.patterns").change_color(regex, subargs[2])
            if p then
                local hl = require("candela.highlighter")
                hl.update_color(regex)
                hl.refresh_ui()
            end
        end,
        complete = function(lead)
            return filter(complete_patterns(), lead)
        end,
    },
    toggle_highlight = {
        impl = function(subargs)
            if #subargs ~= 1 then
                vim.notify("[Candela] Usage: Candela toggle_highlight <index|regex>", vim.log.levels.ERROR)
                return
            end
            local regex = resolve(subargs[1])
            if not regex then
                return
            end
            local toggle = require("candela.patterns").toggle_highlight(regex)
            if toggle ~= nil then
                require("candela.highlighter").toggle_highlights(regex, toggle)
                require("candela.highlighter").refresh_ui()
            end
        end,
        complete = function(lead)
            return filter(complete_patterns(), lead)
        end,
    },
    toggle_lightbox = {
        impl = function(subargs)
            if #subargs ~= 1 then
                vim.notify("[Candela] Usage: Candela toggle_lightbox <index|regex>", vim.log.levels.ERROR)
                return
            end
            local regex = resolve(subargs[1])
            if not regex then
                return
            end
            require("candela.patterns").toggle_lightbox(regex)
            require("candela.lightbox").update_folds()
            require("candela.highlighter").refresh_ui()
        end,
        complete = function(lead)
            return filter(complete_patterns(), lead)
        end,
    },
    vimmatch = {
        impl = function(subargs)
            if #subargs == 0 then
                vim.notify("[Candela] Usage: Candela match <regex> [more...]", vim.log.levels.ERROR)
                return
            end
            require("candela.locator").vimmatch(subargs)
        end,
        complete = function()
            return complete_patterns()
        end,
    },
    loclist = {
        impl = function(subargs)
            if #subargs == 0 then
                vim.notify("[Candela] Usage: Candela find <regex> [more...]", vim.log.levels.ERROR)
                return
            end
            if require("candela.locator").loclist(subargs) then
                vim.cmd("lopen")
            end
        end,
        complete = function()
            return complete_patterns()
        end,
    },
    lightbox = {
        impl = function(subargs)
            local view = subargs[1] or nil
            require("candela.lightbox").toggle(view)
        end,
        complete = function()
            return { "split-left", "split-right", "split-above", "split-below", "system-split", "system-vsplit", "tab" }
        end,
    },
    import = {
        impl = function(subargs)
            if #subargs ~= 1 then
                vim.notify("[Candela] Usage: Candela import <path>", vim.log.levels.ERROR)
                return
            end
            require("candela.io").import(subargs[1])
            require("candela.highlighter").refresh_ui()
        end,
        complete = function(lead)
            return vim.fn.getcompletion(lead, "file")
        end,
    },
    export = {
        impl = function(subargs)
            if #subargs > 1 then
                vim.notify("[Candela] Usage: Candela export [path]", vim.log.levels.ERROR)
                return
            end
            require("candela.io").export(subargs[1])
        end,
        complete = function(lead)
            return vim.fn.getcompletion(lead, "file")
        end,
    },
    help = {
        impl = function()
            require("candela.ui").help()
        end,
    },
    health = {
        impl = function()
            vim.cmd.checkhealth("candela")
        end,
    },
}

function M.dispatch(args)
    local fargs = args.fargs
    local key = fargs[1]
    if vim.g.candela_debug then
        vim.notify(
            string.format("[Candela] command: %s %s", key or "", table.concat(vim.list_slice(fargs, 2) or {}, " ")),
            vim.log.levels.DEBUG
        )
    end
    local subargs = #fargs > 1 and vim.list_slice(fargs, 2) or {}
    local cmd = M.commands[key]
    if not cmd then
        vim.notify("[Candela] unknown command: " .. (key or ""), vim.log.levels.ERROR)
        return
    end
    cmd.impl(subargs)
end

function M.complete(arglead, cmdline, _)
    local subcmd, sub_lead = cmdline:match("^['<,'>]*Candela[!]*%s(%S+)%s(.*)$")
    if subcmd and sub_lead and M.commands[subcmd] and M.commands[subcmd].complete then
        return M.commands[subcmd].complete(sub_lead)
    end
    if cmdline:match("^['<,'>]*Candela[!]*%s+%w*$") then
        return filter(vim.tbl_keys(M.commands), arglead)
    end
    return {}
end

return M
