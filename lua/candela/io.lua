local M = {}
local uv = vim.uv

local data_dir = vim.fn.stdpath("data") .. "/candela"
local default_filename = "patterns_export.lua"

function M.ensure_data_dir()
    if not uv.fs_stat(data_dir) then
        uv.fs_mkdir(data_dir, 448)
    end
end

local function unique_path(path)
    if path ~= data_dir .. "/" .. default_filename and not uv.fs_stat(path) then
        return path
    end
    local base, ext = path:match("^(.*)%.(.-)$")
    if not base then
        base, ext = path, ""
    end
    return string.format("%s_%s.%s", base, os.date("%d%m%Y_%H%M%S"), ext)
end

---@param path string must end in .lua
function M.import(path)
    if not path:match("%.lua$") then
        vim.notify(string.format("[Candela] import path must be .lua, got: %s", path), vim.log.levels.ERROR)
        return
    end

    local patterns = require("candela.patterns")

    if patterns.count() > 0 then
        local choice = vim.fn.confirm("[Candela] existing patterns found. Export first?", "&Yes\n&No\n&Cancel", 1)
        if choice == 1 then
            local export_path = vim.fn.input({ prompt = "[Candela] export path: ", completion = "file" })
            M.export(export_path)
        elseif choice == 3 then
            return
        end
        local highlighter = require("candela.highlighter")
        highlighter.remove_all()
        patterns.clear()
    end

    local ok, imported = pcall(dofile, path)
    if not ok then
        vim.notify(string.format("[Candela] failed to import from %s", path), vim.log.levels.ERROR)
        return
    end

    for _, p in ipairs(imported) do
        local regex = patterns.add(p.regex, p.color, p.highlight, p.lightbox)
        if regex then
            require("candela.highlighter").highlight(regex)
        end
    end
end

---@param path? string file path, defaults to stdpath("data")/candela/
function M.export(path)
    if not path or path == "" then
        M.ensure_data_dir()
        path = data_dir .. "/" .. default_filename
    end

    if not path:match("%.lua$") then
        vim.notify("[Candela] export path doesn't end in .lua — won't be importable", vim.log.levels.WARN)
    end

    if uv.fs_stat(path) then
        local choice = vim.fn.confirm("[Candela] file exists, overwrite?", "&Yes\n&No\n&Cancel", 1)
        if choice == 2 then
            path = unique_path(path)
        elseif choice == 3 then
            return
        end
    end

    local file, err = io.open(path, "w")
    if not file then
        vim.notify(string.format("[Candela] failed to write: %s", err), vim.log.levels.ERROR)
        return
    end

    local exported = {}
    for regex, p in pairs(require("candela.patterns").patterns) do
        table.insert(exported, {
            regex = regex,
            color = p.color,
            highlight = p.highlight,
            lightbox = p.lightbox,
        })
    end

    file:write("return " .. vim.inspect(exported))
    file:close()
    vim.notify(string.format("[Candela] exported to %s", path), vim.log.levels.INFO)
end

--- Delete all exported pattern files from the default data directory.
function M.clear()
    if not uv.fs_stat(data_dir) then
        return
    end
    local handle = uv.fs_scandir(data_dir)
    if not handle then
        return
    end

    local stem = default_filename:match("(.*)%.lua$")
    while true do
        local name, type = uv.fs_scandir_next(handle)
        if not name then
            break
        end
        if type == "file" and name:match("^" .. stem .. ".*%.lua$") then
            uv.fs_unlink(data_dir .. "/" .. name)
        end
    end
    vim.notify(string.format("[Candela] cleared exports from %s", data_dir), vim.log.levels.INFO)
end

return M
