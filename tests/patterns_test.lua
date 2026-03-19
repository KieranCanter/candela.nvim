describe("candela.patterns", function()
    local patterns

    before_each(function()
        -- Fresh module state each test
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.config"] = nil
        patterns = require("candela.patterns")
        -- Manually set palette so init() doesn't need full config
        patterns.palette = { dark = { "#AA0000", "#00AA00", "#0000AA" }, light = { "#FF0000" } }
        patterns.next_color = (function()
            local i = 0
            return function()
                i = i + 1
                return patterns.palette.dark[((i - 1) % #patterns.palette.dark) + 1]
            end
        end)()
    end)

    describe("add", function()
        it("adds a pattern", function()
            local key = patterns.add("ERROR")
            assert.equals("ERROR", key)
            assert.is_not_nil(patterns.get("ERROR"))
            assert.equals("ERROR", patterns.get("ERROR").regex)
        end)

        it("auto-assigns color from cycler", function()
            patterns.add("ERROR")
            assert.equals("#AA0000", patterns.get("ERROR").color)
            patterns.add("WARN")
            assert.equals("#00AA00", patterns.get("WARN").color)
        end)

        it("accepts explicit color", function()
            patterns.add("ERROR", "#FFFFFF")
            assert.equals("#FFFFFF", patterns.get("ERROR").color)
        end)

        it("defaults highlight and lightbox to true", function()
            patterns.add("ERROR")
            local p = patterns.get("ERROR")
            assert.is_true(p.highlight)
            assert.is_true(p.lightbox)
        end)

        it("rejects empty regex", function()
            assert.is_nil(patterns.add(""))
        end)

        it("rejects duplicate regex", function()
            patterns.add("ERROR")
            assert.is_nil(patterns.add("ERROR"))
        end)
    end)

    describe("edit", function()
        it("renames a pattern", function()
            patterns.add("ERROR")
            local new = patterns.edit("ERROR", "FATAL")
            assert.equals("FATAL", new)
            assert.is_nil(patterns.get("ERROR"))
            assert.is_not_nil(patterns.get("FATAL"))
        end)

        it("preserves color and toggles", function()
            patterns.add("ERROR", "#123456", false, true)
            patterns.edit("ERROR", "FATAL")
            local p = patterns.get("FATAL")
            assert.equals("#123456", p.color)
            assert.is_false(p.highlight)
            assert.is_true(p.lightbox)
        end)

        it("returns same key if regex unchanged", function()
            patterns.add("ERROR")
            assert.equals("ERROR", patterns.edit("ERROR", "ERROR"))
        end)

        it("rejects edit to existing regex", function()
            patterns.add("ERROR")
            patterns.add("WARN")
            assert.is_nil(patterns.edit("ERROR", "WARN"))
        end)

        it("rejects empty new regex", function()
            patterns.add("ERROR")
            assert.is_nil(patterns.edit("ERROR", ""))
        end)
    end)

    describe("delete", function()
        it("removes a pattern", function()
            patterns.add("ERROR")
            assert.is_true(patterns.delete("ERROR"))
            assert.is_nil(patterns.get("ERROR"))
            assert.equals(0, patterns.count())
        end)

        it("returns false for nonexistent", function()
            assert.is_false(patterns.delete("NOPE"))
        end)
    end)

    describe("clear", function()
        it("removes all patterns", function()
            patterns.add("ERROR")
            patterns.add("WARN")
            assert.is_true(patterns.clear())
            assert.equals(0, patterns.count())
        end)

        it("returns false when already empty", function()
            assert.is_false(patterns.clear())
        end)
    end)

    describe("toggle_highlight", function()
        it("flips and returns new state", function()
            patterns.add("ERROR")
            assert.is_false(patterns.toggle_highlight("ERROR"))
            assert.is_true(patterns.toggle_highlight("ERROR"))
        end)

        it("returns nil for nonexistent", function()
            assert.is_nil(patterns.toggle_highlight("NOPE"))
        end)
    end)

    describe("toggle_lightbox", function()
        it("flips and returns new state", function()
            patterns.add("ERROR")
            assert.is_false(patterns.toggle_lightbox("ERROR"))
            assert.is_true(patterns.toggle_lightbox("ERROR"))
        end)
    end)

    describe("count", function()
        it("tracks pattern count", function()
            assert.equals(0, patterns.count())
            patterns.add("A")
            patterns.add("B")
            assert.equals(2, patterns.count())
            patterns.delete("A")
            assert.equals(1, patterns.count())
        end)
    end)

    describe("hash", function()
        it("returns consistent sha256", function()
            local h1 = patterns.hash("ERROR")
            local h2 = patterns.hash("ERROR")
            assert.equals(h1, h2)
            assert.not_equals(h1, patterns.hash("WARN"))
        end)
    end)
end)
