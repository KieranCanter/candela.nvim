CandelaConfig = require("candela.config")

local M = {}

local function engine_health()
    local available = CandelaConfig.options.engine.available
    local selected = CandelaConfig.options.engine.selected
    local found = "Found"
    local version = ""

    if #available == 0 or selected == nil then
        vim.health.error("No regex search engine found... how do you not at least have grep?")
    end

    for i, engine in pairs(available) do
        if next(engine) == selected then
            version = engine[next(engine)]
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
    vim.health.info("{candela.nvim} version `" .. CandelaConfig.version .. "`")
    engine_health()
end

return M
