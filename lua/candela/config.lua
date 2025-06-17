-- Module for defining user configuration

local Config = {}

---@class Config
Config.defaults = {
    -- Use log syntax highlighting
    syntax_highlighting = true,
}

---@type Config
Config.options = {}

function Config.setup(opts)
  Config.options = vim.tbl_deep_extend("force", {}, Config.defaults, opts or {})
end

return Config
