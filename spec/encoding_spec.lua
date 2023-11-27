describe("Encoding tests", function()
    local Sqids = require("sqids")

    it("match against a short blocklist word", function()
        local sqids = Sqids.new({
            blocklist = {
                'pnd'
            }
        })

        local decodedResult = sqids:decode(sqids:encode({ 1000 }))

        assert.are.same(decodedResult, { 1000 })
    end)

    it("blocklist filtering in constructor", function()
        local sqids = Sqids.new({
            alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
            blocklist = {
                'sxnzkl' -- lowercase blocklist in only-uppercase alphabet
            }
        })

        local id = sqids:encode({ 1, 2, 3 })
        local numbers = sqids:decode(id)

        assert.are.equal(id, 'IBSHOZ') -- without blocklist, would've been "SXNZKL"
        assert.are.same(numbers, { 1, 2, 3 })
    end)

    it("max encoding attempts", function()
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

        local success, _ = pcall(function() sqids:encode({ 0 }) end)
        assert.is_false(success)
    end)

    it("incremental numbers, same index 0", function()
        local sqids = Sqids.new()

        local ids = {
            SvIz = { 0, 0 },
            n3qa = { 0, 1 },
            tryF = { 0, 2 },
            eg6q = { 0, 3 },
            rSCF = { 0, 4 },
            sR8x = { 0, 5 },
            uY2M = { 0, 6 },
            ['74dI'] = { 0, 7 },
            ['30WX'] = { 0, 8 },
            moxr = { 0, 9 }
        }

        for id, numbers in pairs(ids) do
            assert.are.equal(sqids:encode(numbers), id)
            assert.are.same(sqids:decode(id), numbers)
        end
    end)

    it("incremental numbers, same index 1", function()
        local sqids = Sqids.new()

        local ids = {
            SvIz = { 0, 0 },
            nWqP = { 1, 0 },
            tSyw = { 2, 0 },
            eX68 = { 3, 0 },
            rxCY = { 4, 0 },
            sV8a = { 5, 0 },
            uf2K = { 6, 0 },
            ['7Cdk'] = { 7, 0 },
            ['3aWP'] = { 8, 0 },
            m2xn = { 9, 0 }
        }

        for id, numbers in pairs(ids) do
            assert.are.equal(sqids:encode(numbers), id)
            assert.are.same(sqids:decode(id), numbers)
        end
    end)

    it("multi input", function()
        local sqids = Sqids.new()

        local numbers = {}
        for i = 0, 99 do
            table.insert(numbers, i)
        end

        local output = sqids:decode(sqids:encode(numbers))
        assert.are.same(numbers, output)
    end)

    it("decoding empty string", function()
        local sqids = Sqids.new()
        assert.are.same(sqids:decode(''), {})
    end)

    it("decoding an ID with an invalid character", function()
        local sqids = Sqids.new()
        assert.are.same(sqids:decode('*'), {})
    end)

    it("encode out-of-range numbers", function()
        local encodingError =
        "Encoding supports numbers between 0 and 2 ^ 53 - 1"

        local sqids = Sqids.new()
        local success, _ = pcall(function() sqids:encode({ -1 }) end)
        assert.is_false(success)

        local success2, _ = pcall(function() sqids:encode({ 2 ^ 53 }) end)
        assert.is_false(success2)
    end)
    
end)
