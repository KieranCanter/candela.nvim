-- Module for defining user commands
local M = {}

local function string2bool(val)
    if val ~= nil then
        val = val:lower()
        return val == "true" or val == "1" or val == "yes" or val == "on"
    end
    return nil
end

---@return table<string>
local function complete_patterns()
    local regexes = {}
    for _, pattern in pairs(require("candela.pattern_list").patterns) do
        local regex = pattern.regex
        local words = {}
        for word in regex:gmatch("(%S+)") do
            table.insert(words, word)
        end
        regex = table.concat(words, "\\ ")
        table.insert(regexes, regex)
    end
    return regexes
end

function M.setup()
    local CandelaUi = require("candela.ui")
    local CandelaPatternList = require("candela.pattern_list")

    M.commands = {
        add = {
            ---@param subargs table<string, string?, string?, string?>: regex, color?, highlight?, lightbox?
            impl = function(subargs)
                if #subargs > 4 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela add <regex: string> [color: string] [highlight: boolean] [lightbox: boolean]",
                        vim.log.levels.ERROR
                    )
                    return
                elseif #subargs == 0 then
                    CandelaUi.add()
                else
                    subargs[3] = string2bool(subargs[3])
                    subargs[4] = string2bool(subargs[4])
                    CandelaPatternList.add(unpack(subargs))
                end
            end,
        },
        edit = {
            ---@param subargs table<string, string>: index_or_regex, new_regex
            impl = function(subargs)
                if #subargs == 1 then
                    if tonumber(subargs[1]) ~= nil then
                        subargs[1] = tonumber(subargs[1])
                    end
                    CandelaUi.show_patterns()
                    CandelaUi.edit(subargs[1])
                elseif #subargs == 2 then
                    if tonumber(subargs[1]) ~= nil then
                        subargs[1] = tonumber(subargs[1])
                    end
                    CandelaPatternList.edit(unpack(subargs))
                else
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela edit <index: integer | regex: string> <new_regex: string>",
                        vim.log.levels.ERROR
                    )
                    return
                end
            end,
            complete = function(subarg_lead)
                local regexes = complete_patterns()
                return vim.iter(regexes)
                    :filter(function(regex)
                        return regex:find(subarg_lead) ~= nil
                    end)
                    :totable()
            end,
        },
        copy = {
            ---@param subargs table<string, string>: index_or_regex, new_regex
            impl = function(subargs)
                if #subargs == 1 then
                    if tonumber(subargs[1]) ~= nil then
                        subargs[1] = tonumber(subargs[1])
                    end
                    CandelaUi.show_patterns()
                    CandelaUi.copy(subargs[1])
                elseif #subargs == 2 then
                    local pattern = nil
                    if tonumber(subargs[1]) ~= nil then
                        subargs[1] = tonumber(subargs[1])
                        _, pattern = CandelaPatternList.get_id_and_pattern_by_index(subargs[1])
                    else
                        _, pattern = CandelaPatternList.get_id_and_pattern_by_regex(subargs[1])
                    end
                    if pattern == nil then
                        return
                    end
                    CandelaPatternList.add(subargs[2], pattern.color, pattern.highlight, pattern.lightbox)
                else
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela copy <index: integer | regex: string> <new_regex: string>",
                        vim.log.levels.ERROR
                    )
                    return
                end
            end,
            complete = function(subarg_lead)
                local regexes = complete_patterns()
                return vim.iter(regexes)
                    :filter(function(regex)
                        return regex:find(subarg_lead) ~= nil
                    end)
                    :totable()
            end,
        },
        delete = {
            ---@param subargs table<string, ...>: index, indices...
            impl = function(subargs)
                if #subargs == 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela delete <index: integer> [indices: integer]...",
                        vim.log.levels.ERROR
                    )
                    return
                end

                local to_delete = {}
                for _, index in ipairs(subargs) do
                    if tonumber(index) ~= nil then
                        table.insert(to_delete, tonumber(index))
                    else
                        vim.notify(
                            "[Candela] invalid argument(s).\n"
                                .. "Usage:\n"
                                .. "   Candela delete <index: integer> [more_indices: integer]...",
                            vim.log.levels.ERROR
                        )
                        return
                    end
                end
                table.sort(to_delete, function(a, b)
                    return a > b
                end)
                for _, index in ipairs(to_delete) do
                    CandelaPatternList.delete(index)
                end
            end,
            complete = function()
                local indices = {}
                for i, _ in pairs(require("candela.pattern_list").order) do
                    table.insert(indices, tostring(i))
                end
                return vim.iter(indices):totable()
            end,
        },
        clear = {
            ---@param subargs table|nil: empty table or nil
            impl = function(subargs)
                if subargs ~= nil and #subargs > 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n" .. "Usage:\n" .. "   Candela clear",
                        vim.log.levels.ERROR
                    )
                    return
                end
                CandelaPatternList.clear()
            end,
        },
        refresh = {
            ---@param subargs table|nil: empty table or nil
            impl = function(subargs)
                if subargs ~= nil and #subargs > 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n" .. "Usage:\n" .. "   Candela refresh",
                        vim.log.levels.ERROR
                    )
                    return
                end
                CandelaUi.refresh(true)
            end,
        },
        change_color = {
            ---@param subargs table<string, string>: index_or_regex, new_color
            impl = function(subargs)
                if #subargs == 1 then
                    if tonumber(subargs[1]) ~= nil then
                        subargs[1] = tonumber(subargs[1])
                    end
                    CandelaUi.show_patterns()
                    CandelaUi.change_color(subargs[1])
                elseif #subargs == 2 then
                    if tonumber(subargs[1]) ~= nil then
                        subargs[1] = tonumber(subargs[1])
                    end
                    CandelaPatternList.change_color(unpack(subargs))
                else
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela change_color <index: integer | regex: string> <new_color: string>",
                        vim.log.levels.ERROR
                    )
                    return
                end
            end,
            complete = function(subarg_lead)
                local regexes = complete_patterns()
                return vim.iter(regexes)
                    :filter(function(regex)
                        return regex:find(subarg_lead) ~= nil
                    end)
                    :totable()
            end,
        },
        toggle_highlight = {
            ---@param subargs table<string>: index_or_regex
            impl = function(subargs)
                if #subargs ~= 1 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela toggle_highlight <index: integer | regex: string>",
                        vim.log.levels.ERROR
                    )
                    return
                end

                if tonumber(subargs[1]) ~= nil then
                    subargs[1] = tonumber(subargs[1])
                end
                CandelaPatternList.toggle_highlight(subargs[1])
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
        toggle_lightbox = {
            ---@param subargs table<string>: index_or_regex
            impl = function(subargs)
                if #subargs ~= 1 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela toggle_lightbox <index: integer | regex: string>",
                        vim.log.levels.ERROR
                    )
                    return
                end

                if tonumber(subargs[1]) ~= nil then
                    subargs[1] = tonumber(subargs[1])
                end
                CandelaPatternList.toggle_lightbox(subargs[1])
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
        match = {
            ---@param subargs table<string, ...>: regexes to match
            impl = function(subargs)
                if #subargs == 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela match <regex: string> [more_regex: string]...",
                        vim.log.levels.ERROR
                    )
                    return
                end
                if #require("candela.pattern_list").order == 0 then
                    vim.notify("[Candela] no existing patterns", vim.log.levels.WARN)
                    return
                end
                require("candela.finder").match(subargs)
            end,
            complete = function()
                local regexes = complete_patterns()
                return vim.iter(regexes):totable()
            end,
        },
        match_all = {
            ---@param subargs table|nil: empty table or nil
            impl = function(subargs)
                if subargs ~= nil and #subargs > 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n" .. "Usage:\n" .. "   Candela match_all",
                        vim.log.levels.ERROR
                    )
                    return
                end
                if #require("candela.pattern_list").order == 0 then
                    vim.notify("[Candela] no existing patterns", vim.log.levels.WARN)
                    return
                end
                require("candela.finder").match({})
            end,
        },
        find = {
            ---@param subargs table<string, ...>: regexes to find
            impl = function(subargs)
                if #subargs == 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela find <regex: string> [more_regex: string]...",
                        vim.log.levels.ERROR
                    )
                    return
                end
                if #require("candela.pattern_list").order == 0 then
                    vim.notify("[Candela] no existing patterns", vim.log.levels.WARN)
                    return
                end

                local success = require("candela.finder").find(subargs)
                if success then
                    vim.api.nvim_cmd({ cmd = "lopen" }, {})
                end
            end,
            complete = function()
                local regexes = complete_patterns()
                return vim.iter(regexes):totable()
            end,
        },
        find_all = {
            ---@param subargs table|nil: empty table or nil
            impl = function(subargs)
                if subargs ~= nil and #subargs > 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n" .. "Usage:\n" .. "   Candela find_all",
                        vim.log.levels.ERROR
                    )
                    return
                end
                if #require("candela.pattern_list").order == 0 then
                    vim.notify("[Candela] no existing patterns", vim.log.levels.WARN)
                    return
                end

                local success = require("candela.finder").find({})
                if success then
                    vim.api.nvim_cmd({ cmd = "lopen" }, {})
                end
            end,
        },
        lightbox = {
            ---@param subargs table|nil: empty table or nil
            impl = function(subargs)
                if subargs ~= nil and #subargs > 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n" .. "Usage:\n" .. "   Candela lightbox",
                        vim.log.levels.ERROR
                    )
                    return
                end
                CandelaUi.hide_patterns()
                require("candela.lightbox").toggle()
            end,
        },
        import = {
            ---@param subargs table<string>: import file
            impl = function(subargs)
                if #subargs ~= 1 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela import <path/to/import_file.lua>",
                        vim.log.levels.ERROR
                    )
                    return
                end

                local path = subargs[1]
                require("candela.io").import(path)
            end,
            complete = function(sub_arglead)
                return vim.fn.getcompletion(sub_arglead, "file")
            end,
        },
        export = {
            ---@param subargs table<string>: export file
            impl = function(subargs)
                if #subargs > 1 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n"
                            .. "Usage:\n"
                            .. "   Candela export <path/to/export_file.lua>",
                        vim.log.levels.ERROR
                    )
                    return
                end

                local path = subargs[1]
                require("candela.io").export(path)
            end,
            complete = function(sub_arglead)
                return vim.fn.getcompletion(sub_arglead, "file")
            end,
        },
        help = {
            ---@param subargs table|nil: empty table or nil
            impl = function(subargs)
                if subargs ~= nil and #subargs > 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n" .. "Usage:\n" .. "   Candela help",
                        vim.log.levels.ERROR
                    )
                    return
                end
                CandelaUi.help()
            end,
        },
        health = {
            ---@param subargs table|nil: empty table or nil
            impl = function(subargs)
                if subargs ~= nil and #subargs > 0 then
                    vim.notify(
                        "[Candela] invalid number of arguments.\n" .. "Usage:\n" .. "   Candela health",
                        vim.log.levels.ERROR
                    )
                    return
                end
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
