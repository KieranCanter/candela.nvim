CandelaConfig = require("candela.config")

local M = {}

function M.has_search_engine()
    local pattern = "%d+%.%d+%.*%d*"
    local rg_version = vim.fn.system("rg --version"):match(pattern)
    local ag_version = vim.fn.system("ag --version"):match(pattern)
    local grep_version = vim.fn.system("grep --version"):match(pattern)

    if rg_version ~= nil then
        vim.health.ok("`ripgrep " .. rg_version .. "` found")
    else
        vim.health.warn("`ripgrep` not found")
    end

    if ag_version ~= nil then
        vim.health.ok("`silver searcher " .. ag_version .. "` found")
    else
        vim.health.warn("`silver searcher` not found")
    end

    if rg_version == nil and ag_version == nil then
        vim.health.warn("Consider installing `ripgrep` or `silver searcher` for faster searches")
    end

    if grep_version ~= nil and (rg_version ~= nil or ag_version ~= nil) then
        vim.health.ok("`GNU grep " .. grep_version .. "` found")
    elseif grep_version ~= nil then
        vim.health.ok("`GNU grep " .. grep_version .. "` found, but consider installing `ripgrep`" ..
            "or `silver searcher` for faster searches")
    else
        vim.health.error("No search engine found... how do you not even have grep?")
    end
end

function M.check()
    vim.health.start("candela.nvim")
    vim.health.info("{candela.nvim} version `" .. CandelaConfig.version .. "`")
    M.has_search_engine()
end

return M
