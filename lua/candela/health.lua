CandelaConfig = require("candela.config")

local M = {}

local function get_version()
    return string.format(
        "%d.%d.%d",
        CandelaConfig.version.major,
        CandelaConfig.version.minor,
        CandelaConfig.version.patch
    )
end

local function engine_health()
    local available = CandelaConfig.get_engine_versions()
    local command = CandelaConfig.options.engine.command
    local found = "Found"
    local version = ""

    if #available == 0 or command == nil then
        vim.health.error("No regex search engine found... how do you not at least have grep?")
    end

    for i, engine in pairs(available) do
        if next(engine) == command then
            version = engine[next(engine)]
        end

        if i == 1 then
            found = string.format("%s `%s`", found, next(engine))
        else
            found = string.format("%s, `%s`", found, next(engine))
        end
    end

    vim.health.ok(found)
    vim.health.ok(string.format("Selected `%s` for regex matching", version))
end

function M.check()
    vim.health.start("candela.nvim")
    vim.health.info(string.format("{candela.nvim} version `%s`", get_version()))
    engine_health()
end

return M
