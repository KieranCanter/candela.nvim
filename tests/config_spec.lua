describe("candela.config", function()
    before_each(function()
        package.loaded["candela.config"] = nil
        package.loaded["candela"] = nil
        package.loaded["candela"] = { augroup = vim.api.nvim_create_augroup("CandelaTest", { clear = true }) }
    end)

    it("has defaults before setup", function()
        local config = require("candela.config")
        assert.is_not_nil(config.defaults)
        assert.is_not_nil(config.defaults.window)
        assert.is_nil(config.options)
    end)

    it("setup merges user opts with defaults", function()
        local config = require("candela.config")
        config.setup({ window = { margin = 99 } })
        assert.is_not_nil(config.options)
        assert.equals(99, config.options.window.margin)
        -- Other defaults preserved
        assert.equals(0.5, config.options.window.width)
    end)

    it("detects at least one engine", function()
        local config = require("candela.config")
        local available = config.get_engine_versions()
        assert.is_true(#available > 0)
    end)

    it("setup auto-detects engine when nil", function()
        local config = require("candela.config")
        config.setup({ engine = { command = nil } })
        assert.is_not_nil(config.options.engine.command)
    end)
end)
