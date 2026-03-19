describe("candela.health", function()
    before_each(function()
        package.loaded["candela.health"] = nil
        package.loaded["candela.config"] = nil
        local config = require("candela.config")
        config.setup({})
    end)

    it("check runs without error", function()
        assert.has_no.errors(function()
            require("candela.health").check()
        end)
    end)
end)
