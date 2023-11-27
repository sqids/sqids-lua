describe("Blocklist tests", function()
    local Sqids = require("sqids")

    it("if no custom blocklist param, use the default blocklist", function()
        local sqids = Sqids.new()

        assert.are.same(sqids:decode('aho1e'), {4572721})
        assert.are.equal(sqids:encode({4572721}), 'JExTR')
    end)

    it("if an empty blocklist param passed, don't use any blocklist", function()
        local sqids = Sqids.new({
            blocklist = {}
        })

        assert.are.same(sqids:decode('aho1e'), {4572721})
        assert.are.equal(sqids:encode({4572721}), 'aho1e')
    end)

    it("if a non-empty blocklist param passed, use only that", function()
        local sqids = Sqids.new({
            blocklist = {
                'ArUO' -- originally encoded [100000]
            }
        })

        -- make sure we don't use the default blocklist
        assert.are.same(sqids:decode('aho1e'), {4572721})
        assert.are.equal(sqids:encode({4572721}), 'aho1e')

        -- make sure we are using the passed blocklist
        assert.are.same(sqids:decode('ArUO'), {100000})
        assert.are.equal(sqids:encode({100000}), 'QyG4')
        assert.are.same(sqids:decode('QyG4'), {100000})
    end)

    it("blocklist", function()
        local sqids = Sqids.new({
            blocklist = {
                'JSwXFaosAN', -- normal result of 1st encoding, let's block that word on purpose
                'OCjV9JK64o', -- result of 2nd encoding
                'rBHf', -- result of 3rd encoding is `4rBHfOiqd3`, let's block a substring
                '79SM', -- result of 4th encoding is `dyhgw479SM`, let's block the postfix
                '7tE6' -- result of 4th encoding is `7tE6jdAHLe`, let's block the prefix
            }
        })

        local encodedResult = sqids:encode({1000000, 2000000})
        local decodedResult = sqids:decode('1aYeB7bRUt')

        assert.are.equal(encodedResult, '1aYeB7bRUt')
        assert.are.same(decodedResult, {1000000, 2000000})
    end)

    it("decoding blocklist words should still work", function()
        local sqids = Sqids.new({
            blocklist = {
                '86Rf07', 'se8ojk', 'ARsz1p', 'Q8AI49', '5sQRZO'
            }
        })

        local decodedResult1 = sqids:decode('86Rf07')
        local decodedResult2 = sqids:decode('se8ojk')
        local decodedResult3 = sqids:decode('ARsz1p')
        local decodedResult4 = sqids:decode('Q8AI49')
        local decodedResult5 = sqids:decode('5sQRZO')

        assert.are.same(decodedResult1, {1, 2, 3})
        assert.are.same(decodedResult2, {1, 2, 3})
        assert.are.same(decodedResult3, {1, 2, 3})
        assert.are.same(decodedResult4, {1, 2, 3})
        assert.are.same(decodedResult5, {1, 2, 3})
    end)

    it("match against a short blocklist word test", function()
        local sqids = Sqids.new({
            blocklist = {
                'pnd'
            }
        })

        local decodedResult = sqids:decode(sqids:encode({1000}))

        assert.are.same(decodedResult, {1000})
    end)

    it("blocklist filtering in constructor test", function()
        local sqids = Sqids.new({
            alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
            blocklist = {
                'sxnzkl' -- lowercase blocklist in only-uppercase alphabet
            }
        })

        local id = sqids:encode({1, 2, 3})
        local numbers = sqids:decode(id)

        assert.are.equal(id, 'IBSHOZ') -- without blocklist, would've been "SXNZKL"
        assert.are.same(numbers, {1, 2, 3})
    end)

    it("max encoding attempts test", function()
        local alphabet = 'abc'
        local minLength = 3
        local blocklist = {
            'cab', 'abc', 'bca'
        }

        local sqids = Sqids.new({
            alphabet = alphabet,
            minLength = minLength,
            blocklist = blocklist
        })

        assert.are.equal(#alphabet, minLength)
        assert.are.equal(#blocklist, minLength)

        local success, _ = pcall(function() sqids:encode({0}) end)
        assert.is_false(success)
    end)
end)
