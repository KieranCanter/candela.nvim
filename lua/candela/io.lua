M = {}
local uv = vim.uv

-- Default paths
local data_dir = vim.fn.stdpath("data") .. "/candela"
local default_filename = "patterns_export.lua"

-- Ensure directory exists
---@param path string
local function ensure_dir(path)
    if uv.fs_stat(path) == nil then
        uv.fs_mkdir(path, 448) -- 0700
    end
end

-- Generate a unique filename if path exists
---@param path string
local function unique_path(path)
    if path ~= data_dir .. "/" .. default_filename and not uv.fs_stat(path) then
        return path
    end

    local base, ext = path:match("^(.*)%.(.-)$")
    if not base then
        base, ext = path, ""
    end

    local new_path
    new_path = string.format("%s_%s.%s", base, os.date("%Y%m%d_%H%M%S"), ext)

    return new_path
end

function M.import_patterns(path)
    if not path:match("%.lua$") then
        vim.notify(string.format("[Candela] path must be a `.lua` file to be imported, got: `%s`", path), vim.log.levels.ERROR)
        return
    end

    local pattern_list = require("candela.pattern_list")
    local order = pattern_list.order

    if #order > 0 then
        local choice =
            vim.fn.confirm("[Candela] existing patterns found. Export before overwriting?", "&Yes\n&No\n&Cancel", 1)
        if choice == 1 then
            local export_path = vim.fn.input(
                "[Candela] enter path for export (leave blank for default path in `" .. data_dir .. "`): ",
                "",
                "file"
            )
            M.export_patterns(export_path)
        elseif choice == 3 then
            return -- cancel
        end

        pattern_list.clear_patterns()
    end

    local ok, imported = pcall(dofile, path)
    if not ok then
        vim.notify(string.format("[Candela] failed to import patterns from `%s`", path), vim.log.levels.ERROR)
        return
    end

    for _, pattern in ipairs(imported) do
        pattern_list.add_pattern(pattern.regex, pattern.color, pattern.highlight, pattern.lightbox)
    end

    require("candela.ui").update_ui()
end

-- Export patterns to lua table in file
---@param path? string: file path to export patterns to
function M.export_patterns(path)
    if not path or path == "" then
        ensure_dir(data_dir)
        path = data_dir .. "/" .. default_filename
    end

    if not path:match("%.lua$") then
        vim.notify(
            string.format(
                '[Candela] export path "%s" does not end in `.lua`. If you intend on importing'
                    .. "these patterns in the future, they must be in a `.lua` file.",
                path
            ),
            vim.log.levels.WARN
        )
    end

    local path_exists, _ = io.open(path, "r")
    if path_exists then
        local choice =
            vim.fn.confirm("[Candela] file path already exists, overwrite? Select \"No\" to automatically"
                .. " create a unique path using the date and time.", "&Yes\n&No\n&Cancel", 1)
        if choice == 2 then -- create unique path
            path = unique_path(path)
        elseif choice == 3 then -- cancel
            return
        end -- otherwise, choice is 1, overwrite path
    end

    local file, err = io.open(path, "w")
    if not file then
        vim.notify(string.format("[Candela] failed to open file for writing: %s", err), vim.log.levels.ERROR)
        return
    end

    local pattern_list = require("candela.pattern_list")
    local order, patterns = pattern_list.order, pattern_list.patterns
    local exported = {}
    for _, id in ipairs(order) do
        local pattern = patterns[id]
        local curr = {
            regex = pattern.regex,
            color = pattern.color,
            highlight = pattern.highlight,
            lightbox = pattern.lightbox,
        }
        table.insert(exported, curr)
    end

    file:write("return " .. vim.inspect(exported))
    file:close()

    vim.notify(string.format("[Candela] patterns successfully exported to `%s`", path), vim.log.levels.INFO)
end

function M.clear()
    if not uv.fs_stat(data_dir) then
        return
    end

    local handle = uv.fs_scandir(data_dir)
    if not handle then
        return
    end

    while true do
        local name, type = uv.fs_scandir_next(handle)
        if not name then
            break
        end

        local default_filestem = default_filename:match("(.*)%.lua$")
        if type == "file" and name:match("^" .. default_filestem .. ".*%.lua$") then
            local filepath = data_dir .. "/" .. name
            local ok, err = uv.fs_unlink(filepath)
            if not ok then
                vim.notify(
                    string.format("[Candela] failed to remove export file: `%` (%s)", filepath, err),
                    vim.log.levels.ERROR
                )
            end
        end
    end

    vim.notify(string.format("[Candela] successfully cleared exports from `%s`", data_dir), vim.log.levels.INFO)
end

return M
