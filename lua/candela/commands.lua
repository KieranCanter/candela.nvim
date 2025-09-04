-- Module for defining user commands
local CandelaUi = require("candela.ui")
local CandelaLightbox = require("candela.lightbox")
local CandelaIo = require("candela.io")

local M = {}

function M.setup(opts)
    M.commands = {
        add = function()
            CandelaUi.show_patterns()
            CandelaUi.add()
        end,
        edit = function()
            CandelaUi.edit()
        end,
        copy = function()
            CandelaUi.copy()
        end,
        delete = function()
            local ask = opts.matching.delete_confirmation
            CandelaUi.delete(ask)
        end,
        clear = function()
            local ask = opts.matching.clear_confirmation
            CandelaUi.clear(ask)
        end,
        refresh = function()
            CandelaUi.refresh()
        end,
        change_color = function()
            CandelaUi.change_color()
        end,
        toggle_highlight = function()
            CandelaUi.toggle_highlight()
        end,
        toggle_lightbox = function()
            CandelaUi.toggle_lightbox()
        end,
        match = function()
            CandelaUi.match(false)
        end,
        match_all = function()
            CandelaUi.match(true)
        end,
        find = function()
            CandelaUi.find()
            vim.api.nvim_cmd({ cmd = "lnext" }, {})
            vim.api.nvim_cmd({ cmd = "lopen" }, {})
        end,
        find_all = function()
            CandelaUi.find_selected(true)
            vim.api.nvim_cmd({ cmd = "lnext" }, {})
            vim.api.nvim_cmd({ cmd = "lopen" }, {})
        end,
        lightbox = function()
            CandelaUi.hide_patterns()
            CandelaLightbox.toggle()
        end,
        import = function(args)
            if #args ~= 1 then
                vim.notify(
                    "[Candela] invalid number of arguments, `import` command must have one argument"
                        .. "\nUsage: `Candela import <path/to/import_file.lua>`",
                    vim.log.levels.ERROR
                )
                return
            end

            local path = args[1]
            CandelaIo.import_patterns(path)
        end,
        export = function(args)
            if #args > 1 then
                vim.notify(
                    "[Candela] invalid number of arguments, `export` command must have zero or one argument"
                        .. "\nUsage: `Candela export [path/to/export_file.lua]`",
                    vim.log.levels.ERROR
                )
                return
            end

            local path = args[1]
            CandelaIo.export_patterns(path)
        end,
        help = function()
            vim.notify("[Candela] help subcommand not implemented yet", vim.log.levels.WARN)
            CandelaUi.help()
        end,
        health = function()
            vim.cmd.checkhealth("candela")
        end,
    }
end

---@param args table<string, any>
function M.dispatch(args)
    local subcommand = args[1]
    table.remove(args, 1)

    if not subcommand or subcommand == "" then
        CandelaUi.toggle()
    elseif M.commands[subcommand] ~= nil then
        M.commands[subcommand](args)
    else
        vim.notify('Candela: unsupported command "' .. subcommand .. '"', vim.log.levels.ERROR)
    end
end

return M
