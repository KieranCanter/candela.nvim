-- Module for defining user commands
local M = {}

function M.setup(opts)
    local CandelaUi = require("candela.ui")

    M.commands = {
        add = {
            impl = function()
                CandelaUi.add()
            end,
        },
        edit = {
            impl = function()
                CandelaUi.edit()
            end,
        },
        copy = {
            impl = function()
                CandelaUi.copy()
            end,
        },
        delete = {
            impl = function()
                local ask = opts.matching.delete_confirmation
                CandelaUi.delete(ask)
            end,
        },
        clear = {
            impl = function()
                local ask = opts.matching.clear_confirmation
                CandelaUi.clear(ask)
            end,
        },
        refresh = {
            impl = function()
                CandelaUi.refresh(true)
            end,
        },
        change_color = {
            impl = function()
                CandelaUi.change_color()
            end,
        },
        toggle_highlight = {
            impl = function()
                CandelaUi.toggle_highlight()
            end,
        },
        toggle_lightbox = {
            impl = function()
                CandelaUi.toggle_lightbox()
            end,
        },
        match = {
            impl = function(subargs)
                require("candela.finder").match(subargs)
            end,
            complete = function(subarg_lead)
                local regexes = {}
                for _, pattern in pairs(require("candela.pattern_list").patterns) do
                    table.insert(regexes, pattern.regex)
                end
                return vim.iter(regexes)
                    :filter(function(regex)
                        return regex:find(subarg_lead) ~= nil
                    end)
                    :totable()
            end,
        },
        match_all = {
            impl = function()
                require("candela.finder").match({})
            end,
        },
        find = {
            impl = function(subargs)
                local success = require("candela.finder").find(subargs)
                if success then
                    vim.api.nvim_cmd({ cmd = "lnext", }, {})
                    vim.api.nvim_cmd({ cmd = "lopen", }, {})
                end
            end,
            complete = function(subarg_lead)
                local regexes = {}
                for _, pattern in pairs(require("candela.pattern_list").patterns) do
                    table.insert(regexes, pattern.regex)
                end
                return vim.iter(regexes)
                    :filter(function(regex)
                        return regex:find(subarg_lead) ~= nil
                    end)
                    :totable()
            end,
        },
        find_all = {
            impl = function()
                local success = require("candela.finder").find({})
                if success then
                    vim.api.nvim_cmd({ cmd = "lnext" }, {})
                    vim.api.nvim_cmd({ cmd = "lopen" }, {})
                end
            end,
        },
        lightbox = {
            impl = function()
                CandelaUi.hide_patterns()
                require("candela.lightbox").toggle()
            end,
        },
        import = {
            impl = function(subargs)
                if #subargs ~= 1 then
                    vim.notify(
                        "[Candela] invalid number of arguments, `import` command must have one argument"
                            .. "\nUsage: `Candela import <path/to/import_file.lua>`",
                        vim.log.levels.ERROR
                    )
                    return
                end

                local path = subargs[1]
                require("candela.io").import_patterns(path)
            end,
            complete = function(sub_arglead)
                return vim.fn.getcompletion(sub_arglead, "file")
            end,
        },
        export = {
            impl = function(subargs)
                if #subargs > 1 then
                    vim.notify(
                        "[Candela] invalid number of arguments, `export` command must have zero or one argument"
                            .. "\nUsage: `Candela export [path/to/export_file.lua]`",
                        vim.log.levels.ERROR
                    )
                    return
                end

                local path = subargs[1]
                require("candela.io").export_patterns(path)
            end,
            complete = function(sub_arglead)
                return vim.fn.getcompletion(sub_arglead, "file")
            end,
        },
        help = {
            impl = function()
                vim.notify("[Candela] help subcommand not implemented yet", vim.log.levels.WARN)
                CandelaUi.help()
            end,
        },
        health = {
            impl = function()
                vim.cmd.checkhealth("candela")
            end,
        },
    }
end

---@param args table<string, any>
function M.dispatch(args)
    local fargs = args.fargs
    local subcommand_key = fargs[1]
    local subargs = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local subcommand = M.commands[subcommand_key]
    if not subcommand then
        vim.notify("[Candela] unknown command: " .. subcommand_key, vim.log.levels.ERROR)
        return
    end
    -- Invoke the subcommand
    subcommand.impl(subargs, args)
end

return M
