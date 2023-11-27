describe("MinLength tests", function()
    local Sqids = require("sqids")
    local defaultOptions = {
        alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    }
    it("simple", function()
        local sqids = Sqids.new({
            minLength = #defaultOptions.alphabet
        })

        local numbers = { 1, 2, 3 }
        local id = "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM"

        assert.are.equal(sqids:encode(numbers), id)
        assert.are.same(sqids:decode(id), numbers)
    end)

    it("incremental", function()

        local numbers = { 1, 2, 3 }

        local map = {
            [6] = "86Rf07",
            [7] = "86Rf07x",
            [8] = "86Rf07xd",
            [9] = "86Rf07xd4",
            [10] = "86Rf07xd4z",
            [11] = "86Rf07xd4zB",
            [12] = "86Rf07xd4zBm",
            [13] = "86Rf07xd4zBmi",
            [#defaultOptions.alphabet + 0] = "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM",
            [#defaultOptions.alphabet + 1] = "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMy",
            [#defaultOptions.alphabet + 2] = "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf",
            [#defaultOptions.alphabet + 3] = "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf1"
        }

        for minLength, id in pairs(map) do
            local sqids = Sqids.new({
                minLength = tonumber(minLength)
            })

            assert.are.equal(sqids:encode(numbers), id)
            assert.are.equal(#sqids:encode(numbers), tonumber(minLength))
            assert.are.same(sqids:decode(id), numbers)
        end
    end)

    it("incremental numbers", function()

        local sqids = Sqids.new({
            minLength = #defaultOptions.alphabet
        })

        local ids = {
            ["SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu"] = { 0, 0 },
            ["n3qafPOLKdfHpuNw3M61r95svbeJGk7aAEgYn4WlSjXURmF8IDqZBy0CT2VxQc"] = { 0, 1 },
            ["tryFJbWcFMiYPg8sASm51uIV93GXTnvRzyfLleh06CpodJD42B7OraKtkQNxUZ"] = { 0, 2 },
            ["eg6ql0A3XmvPoCzMlB6DraNGcWSIy5VR8iYup2Qk4tjZFKe1hbwfgHdUTsnLqE"] = { 0, 3 },
            ["rSCFlp0rB2inEljaRdxKt7FkIbODSf8wYgTsZM1HL9JzN35cyoqueUvVWCm4hX"] = { 0, 4 },
            ["sR8xjC8WQkOwo74PnglH1YFdTI0eaf56RGVSitzbjuZ3shNUXBrqLxEJyAmKv2"] = { 0, 5 },
            ["uY2MYFqCLpgx5XQcjdtZK286AwWV7IBGEfuS9yTmbJvkzoUPeYRHr4iDs3naN0"] = { 0, 6 },
            ["74dID7X28VLQhBlnGmjZrec5wTA1fqpWtK4YkaoEIM9SRNiC3gUJH0OFvsPDdy"] = { 0, 7 },
            ["30WXpesPhgKiEI5RHTY7xbB1GnytJvXOl2p0AcUjdF6waZDo9Qk8VLzMuWrqCS"] = { 0, 8 },
            ["moxr3HqLAK0GsTND6jowfZz3SUx7cQ8aC54Pl1RbIvFXmEJuBMYVeW9yrdOtin"] = { 0, 9 }
        }

        for id, numbers in pairs(ids) do
            assert.are.equal(sqids:encode(numbers), id)
            assert.are.same(sqids:decode(id), numbers)
        end
    end)

    it("min lengths", function()
        for _, minLength in ipairs({ 0, 1, 5, 10, #defaultOptions.alphabet }) do
            for _, numbers in ipairs({
                { 0 },
                { 0,               0,    0,   0, 0 },
                { 1,               2,    3,   4, 5, 6, 7, 8, 9, 10 },
                { 100,             200,  300 },
                { 1000,            2000, 3000 },
                { 1000000 },
                { 2 ^ 53 - 1 }
            }) do
                local sqids = Sqids.new({
                    minLength = minLength
                })

                local id = sqids:encode(numbers)
                assert.is_true(#id >= minLength)
                assert.are.same(sqids:decode(id), numbers)
            end
        end
    end)

    it("out-of-range invalid min length", function()
        local minLengthLimit = 255
        local minLengthError = "Minimum length has to be between 0 and " .. minLengthLimit

        assert.has_error(function()
            Sqids.new({
                minLength = -1
            })
        end, minLengthError)

        assert.has_error(function()
            Sqids.new({
                minLength = minLengthLimit + 1
            })
        end, minLengthError)
    end)
end)
