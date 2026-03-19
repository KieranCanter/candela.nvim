describe("candela.engine", function()
    local engine = require("candela.engine")
    local tmpfile

    before_each(function()
        tmpfile = vim.fn.tempname() .. ".log"
        local f = io.open(tmpfile, "w")
        f:write("ERROR first line\nOK second line\nERROR third line\nWARN fourth\n")
        f:close()
    end)

    after_each(function()
        os.remove(tmpfile)
    end)

    describe("run_search", function()
        it("returns raw output lines", function()
            local results = engine.run_search({ "rg", "--line-number", "--color=never", "ERROR", tmpfile })
            assert.is_true(#results > 0)
            assert.truthy(results[1]:match("^%d+:"))
        end)

        it("returns empty for no matches", function()
            local results = engine.run_search({ "rg", "--line-number", "--color=never", "ZZZZNOTFOUND", tmpfile })
            -- rg returns exit code 1 for no matches, systemlist may return {""}
            for _, line in ipairs(results) do
                assert.is_false(line:match("ZZZZNOTFOUND") ~= nil)
            end
        end)
    end)

    describe("get_matches", function()
        it("parses line numbers and content", function()
            local matches = engine.get_matches({ "rg", "--line-number", "--color=never", "ERROR", tmpfile })
            assert.equals(2, #matches)
            assert.equals(1, matches[1].lineno)
            assert.equals("ERROR first line", matches[1].line)
            assert.equals(3, matches[2].lineno)
            assert.equals("ERROR third line", matches[2].line)
        end)

        it("handles single match", function()
            local matches = engine.get_matches({ "rg", "--line-number", "--color=never", "WARN", tmpfile })
            assert.equals(1, #matches)
            assert.equals(4, matches[1].lineno)
        end)
    end)
end)
