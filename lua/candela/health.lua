local CandelaConfig = require("candela.config")

local M = {}

local function get_version()
    local semver_fmt = "%d.%d.%d"
    if CandelaConfig.version.pre then
        semver_fmt = semver_fmt .. "-%s"
    end
    return string.format(
        semver_fmt,
        CandelaConfig.version.major,
        CandelaConfig.version.minor,
        CandelaConfig.version.patch,
        CandelaConfig.version.pre
    )
end

local function engine_health()
    local available = CandelaConfig.get_engine_versions()
    local command = CandelaConfig.options.engine.command
    local found = "Found"
    local selected = ""
    local version = ""

    if #available == 0 or command == nil then
        vim.health.error("No regex search engine found... how do you not at least have grep?")
    end

    for i, engine in pairs(available) do
        local cmd = engine[next(engine)]
        if next(engine) == command then
            selected = cmd[1]
            version = cmd[2]
        end

        if i == 1 then
            found = string.format("%s `%s`", found, next(engine))
        else
            found = string.format("%s, `%s`", found, next(engine))
        end
    end

    vim.health.ok(found)
    vim.health.ok(string.format("Selected `%s %s` for regex matching", selected, version))
end

function M.check()
    vim.health.start("candela.nvim")
    vim.health.info(string.format("{candela.nvim} version `%s`", get_version()))
    engine_health()
end

return M
