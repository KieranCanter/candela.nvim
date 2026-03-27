local pattern = require("candela.pattern")

describe("candela.pattern", function()
    before_each(function()
        -- Stub config for convert_color_string swatch lookup
        package.loaded["candela.config"] = {
            options = {
                palette = {
                    swatches = {
                        dark = { RED = "#FF0000", BLUE = "#0000FF" },
                        light = { RED = "#FF8888", BLUE = "#8888FF" },
                    },
                    colors = {
                        dark = { "#AA0000", "#00AA00" },
                        light = { "#FF0000" },
                    },
                },
            },
        }
    end)
    describe("new", function()
        it("creates a pattern with all fields", function()
            local p = pattern.new("ERROR", "#FF0000", true, false, 0)
            assert.equals("ERROR", p.regex)
            assert.equals("#FF0000", p.color)
            assert.is_true(p.highlight)
            assert.is_false(p.lightbox)
            assert.equals(0, p.count)
        end)

        it("methods work via metatable", function()
            local p = pattern.new("ERROR", "#FF0000", true, true, 0)
            p:toggle_highlight()
            assert.is_false(p.highlight)
        end)
    end)

    describe("edit_regex", function()
        it("updates the regex field", function()
            local p = pattern.new("ERROR", "#FF0000", true, true, 0)
            p:edit_regex("WARN")
            assert.equals("WARN", p.regex)
        end)
    end)

    describe("toggle_highlight", function()
        it("flips highlight state", function()
            local p = pattern.new("ERROR", "#FF0000", true, true, 0)
            p:toggle_highlight()
            assert.is_false(p.highlight)
            p:toggle_highlight()
            assert.is_true(p.highlight)
        end)
    end)

    describe("toggle_lightbox", function()
        it("flips lightbox state", function()
            local p = pattern.new("ERROR", "#FF0000", true, false, 0)
            p:toggle_lightbox()
            assert.is_true(p.lightbox)
        end)
    end)

    describe("convert_color_string", function()
        it("converts 6-digit hex", function()
            assert.equals("#FF0000", pattern.convert_color_string("ff0000"))
            assert.equals("#FF0000", pattern.convert_color_string("#ff0000"))
            assert.equals("#FF0000", pattern.convert_color_string("  #ff0000  "))
        end)

        it("converts 3-digit hex", function()
            assert.equals("#FF0000", pattern.convert_color_string("f00"))
            assert.equals("#FF0000", pattern.convert_color_string("#f00"))
        end)

        it("returns nil for invalid input", function()
            assert.is_nil(pattern.convert_color_string(""))
            assert.is_nil(pattern.convert_color_string("#GGGGGG"))
        end)
    end)

    describe("change_color", function()
        it("updates color with valid hex", function()
            local p = pattern.new("ERROR", "#000000", true, true, 0)
            p:change_color("#FF0000")
            assert.equals("#FF0000", p.color)
        end)

        it("updates color with 3-digit hex", function()
            local p = pattern.new("ERROR", "#000000", true, true, 0)
            p:change_color("f00")
            assert.equals("#FF0000", p.color)
        end)

        it("does not update with invalid color", function()
            local p = pattern.new("ERROR", "#000000", true, true, 0)
            p:change_color("notacolor")
            assert.equals("#000000", p.color)
        end)
    end)

    describe("complete_colors", function()
        it("returns swatch names and palette colors", function()
            local items = pattern.complete_colors("")
            assert.is_true(#items > 0)
        end)

        it("filters by arglead", function()
            local items = pattern.complete_colors("RED")
            for _, item in ipairs(items) do
                assert.truthy(item:lower():find("red"))
            end
        end)

        it("returns hex colors from palette", function()
            local items = pattern.complete_colors("#")
            local has_hex = false
            for _, item in ipairs(items) do
                if item:match("^#") then
                    has_hex = true
                    break
                end
            end
            assert.is_true(has_hex)
        end)
    end)
end)
