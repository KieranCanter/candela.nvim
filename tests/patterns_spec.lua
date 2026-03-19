describe("candela.patterns", function()
    local patterns

    before_each(function()
        package.loaded["candela.patterns"] = nil
        package.loaded["candela.config"] = nil
        patterns = require("candela.patterns")
        -- Stub config for convert_color_string
        package.loaded["candela.config"] = {
            defaults = { palette = { colors = { dark = {}, light = {} }, cycle = "constant" } },
            options = {
                palette = {
                    use = "replace",
                    cycle = "constant",
                    colors = { dark = { "#AA0000", "#00AA00", "#0000AA" }, light = { "#FF0000" } },
                    swatches = { dark = {}, light = {} },
                },
            },
        }
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
            assert.equals("ERROR", patterns.add("ERROR"))
            assert.is_not_nil(patterns.get("ERROR"))
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

        it("respects explicit highlight/lightbox", function()
            patterns.add("ERROR", nil, false, false)
            local p = patterns.get("ERROR")
            assert.is_false(p.highlight)
            assert.is_false(p.lightbox)
        end)

        it("rejects empty regex", function()
            assert.is_nil(patterns.add(""))
        end)

        it("rejects duplicate regex", function()
            patterns.add("ERROR")
            assert.is_nil(patterns.add("ERROR"))
        end)

        it("allows whitespace-only regex", function()
            assert.equals(" ", patterns.add(" "))
            assert.is_not_nil(patterns.get(" "))
        end)
    end)

    describe("edit", function()
        it("renames a pattern", function()
            patterns.add("ERROR")
            assert.equals("FATAL", patterns.edit("ERROR", "FATAL"))
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

        it("returns nil for nonexistent source", function()
            assert.is_nil(patterns.edit("NOPE", "SOMETHING"))
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

    describe("change_color", function()
        it("changes color with valid hex", function()
            patterns.add("ERROR")
            local p = patterns.change_color("ERROR", "#FFFFFF")
            assert.is_not_nil(p)
            assert.equals("#FFFFFF", patterns.get("ERROR").color)
        end)

        it("returns nil for nonexistent", function()
            assert.is_nil(patterns.change_color("NOPE", "#FFFFFF"))
        end)

        it("returns pattern unchanged if same color", function()
            patterns.add("ERROR", "#AA0000")
            local p = patterns.change_color("ERROR", "#AA0000")
            assert.is_not_nil(p)
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
