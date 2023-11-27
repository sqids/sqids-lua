require 'busted.runner' ()

describe("Alphabet tests", function()
    local Sqids = require("sqids")

    it("simple", function()
        local sqids = Sqids.new({
            alphabet = "0123456789abcdef"
        })

        local numbers = { 1, 2, 3 }
        local id = "489158"

        assert.are.equal(sqids:encode(numbers), id)
        assert.are.same(sqids:decode(id), numbers)
    end)

    it("short alphabet", function()
        local sqids = Sqids.new({
            alphabet = "abc"
        })

        local numbers = { 1, 2, 3 }
        assert.are.same(sqids:decode(sqids:encode(numbers)), numbers)
    end)

    it("long alphabet", function()
        local sqids = Sqids.new({
            alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:'\"/?.>,<`~"
        })

        local numbers = { 1, 2, 3 }
        assert.are.same(sqids:decode(sqids:encode(numbers)), numbers)
    end)

    it("multibyte characters", function()
        assert.has_error(function()
            Sqids.new({
                alphabet = "ë1092"
            })
        end, "Alphabet cannot contain multibyte characters")
    end)

    it("repeating alphabet characters", function()
        assert.has_error(function()
            Sqids.new({
                alphabet = "aabcdefg"
            })
        end, "Alphabet must contain unique characters")
    end)

    it("too short of an alphabet", function()
        assert.has_error(function()
            Sqids.new({
                alphabet = "ab"
            })
        end, "Alphabet length must be at least 3")
    end)
end)
