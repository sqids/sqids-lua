-- package.cpath = "lua_modules/lib/lua/5.4/?.so;" .. package.path
-- package.path = "lua_modules/share/lua/5.4/?.lua;" .. package.path

local cjson = require "cjson"

DefaultOptions = {
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    minLength = 0,
    blocklist = {}
}

local minLengthLimit = 255

local function get_script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    local parent_dir = str:match("(.*/)")
    if parent_dir then
        return parent_dir
    end
    return "./"
end

local current_directory = get_script_path()
local blocklistFilePath = current_directory .. "blocklist.json"

-- Load blocklist from blocklist.json file
local blocklistFile = io.open(blocklistFilePath, "r")
if not blocklistFile then
    error("Cannot open blocklist.json")
end

local blocklistData = blocklistFile:read("*all")
blocklistFile:close()

local success, defaultBlocklist = pcall(cjson.decode, blocklistData)
if not success or type(defaultBlocklist) ~= "table" then
    error("Invalid blocklist data in blocklist.json")
end

local Sqids = {}
Sqids.__index = Sqids

local function toId(num, alphabet)
    local id = {}
    local chars = {}
    for i = 1, #alphabet do
        table.insert(chars, alphabet:sub(i, i))
    end

    local result = num
    repeat
        table.insert(id, 1, chars[result % #chars + 1])
        result = math.floor(result / #chars)
    until result <= 0

    return table.concat(id)
end

local function isBlockedId(id, blocklist)
    id = id:lower()

    for _, word in ipairs(blocklist) do
        if #word <= #id then
            if #id <= 3 or #word <= 3 then
                if id == word then
                    return true
                end
            elseif string.match(word, "%d") then
                if id:sub(1, #word) == word or id:sub(#id - #word + 1) == word then
                    return true
                end
            elseif string.find(id, word) then
                return true
            end
        end
    end

    return false
end

-- Helper function to determine the maximum unsigned integer value based on Lua's capabilities
local function maxValue()
    -- Determine the maximum unsigned integer value based on Lua's capabilities
    -- For Lua, it's typically 2^53 - 1 due to number representation
    return 2 ^ 53 - 1
end

-- Helper function to convert an ID to a number
local function toNumber(id, alphabet)
    local charIdx = {}
    for i = 1, #alphabet do
        charIdx[alphabet:sub(i, i)] = i - 1
    end

    local result = 0
    for i = 1, #id do
        result = result * #alphabet + charIdx[id:sub(i, i)]
    end

    return result
end

-- Helper function to check if a string contains unique characters
local function hasUniqueChars(str)
    local charSet = {}
    for i = 1, #str do
        local c = str:sub(i, i)
        if charSet[c] then
            return false
        end
        charSet[c] = true
    end
    return true
end

-- consistent shuffle (always produces the same result given the input)
local function shuffle(alphabet)
    local chars = {}
    for i = 1, #alphabet do
        table.insert(chars, alphabet:sub(i, i))
    end

    for i = 1, #chars - 1 do
        local j = #chars - i + 1
        local r = (i * j + chars[i]:byte() + chars[j]:byte()) % #chars + 1
        chars[i], chars[r] = chars[r], chars[i]
    end

    return table.concat(chars)
end

-- encodeNumbers function (internal) in Lua
local function encodeNumbers(sq, numbers, increment)
    increment = increment or 0 -- Default value for increment

    -- if increment is greater than alphabet length, we've reached max attempts
    if increment > #sq.alphabet then
        error('Reached max attempts to re-generate the ID')
    end

    -- get a semi-random offset from input numbers
    local offset = 0
    for i, v in ipairs(numbers) do
        offset = sq.alphabet:byte(v % #sq.alphabet + 1) + i + offset
    end
    offset = offset % #sq.alphabet

    -- if there is a non-zero `increment`, it's an internal attempt to re-generate the ID
    offset = (offset + increment) % #sq.alphabet

    -- re-arrange alphabet so that second-half goes in front of the first-half
    local alphabet = sq.alphabet:sub(offset + 1) .. sq.alphabet:sub(1, offset)

    -- `prefix` is the first character in the generated ID, used for randomization
    local prefix = alphabet:sub(1, 1)

    -- reverse alphabet (otherwise for [0, x] `offset` and `separator` will be the same char)
    alphabet = alphabet:reverse()

    -- final ID will always have the `prefix` character at the beginning
    local ret = { prefix }

    -- encode input array
    for i, num in ipairs(numbers) do
        -- the first character of the alphabet is going to be reserved for the `separator`
        local alphabetWithoutSeparator = alphabet:sub(2)
        table.insert(ret, toId(num, alphabetWithoutSeparator))

        -- if not the last number
        if i < #numbers then
            -- `separator` character is used to isolate numbers within the ID
            table.insert(ret, alphabet:sub(1, 1))

            -- shuffle on every iteration
            alphabet = shuffle(alphabet)
        end
    end

    -- join all the parts to form an ID
    local id = table.concat(ret, '')

    -- handle `minLength` requirement, if the ID is too short
    if sq.minLength > #id then
        -- append a separator
        id = id .. alphabet:sub(1, 1)

        -- keep appending `separator` + however much alphabet is needed
        -- for decoding: two separators next to each other is what tells us the rest are junk characters
        while sq.minLength - #id > 0 do
            alphabet = shuffle(alphabet)
            id = id .. alphabet:sub(1, math.min(sq.minLength - #id, #alphabet))
        end
    end

    -- if ID has a blocked word anywhere, restart with a +1 increment
    if isBlockedId(id, sq.blocklist) then
        id = encodeNumbers(sq, numbers, increment + 1)
    end

    return id
end

function Sqids.new(options)
    options = options or {}

    local alphabet = options.alphabet or DefaultOptions.alphabet
    local minLength = options.minLength or DefaultOptions.minLength
    local blocklist = options.blocklist or defaultBlocklist

    -- Validate the alphabet
    if #alphabet ~= utf8.len(alphabet) then
        error('Alphabet cannot contain multibyte characters')
    end

    if #alphabet < 3 then
        error('Alphabet length must be at least 3')
    end

    if not hasUniqueChars(alphabet) then
        error('Alphabet must contain unique characters')
    end

    -- Validate the minimum length
    if type(minLength) ~= 'number' or minLength < 0 or minLength > minLengthLimit then
        error('Minimum length has to be between 0 and ' .. minLengthLimit)
    end

    -- Filter the blocklist
    local filteredBlocklist = {}
    local alphabetChars = alphabet:lower():gsub('.', function(c) return c .. '\1' end)
    for _, word in ipairs(blocklist) do
        if #word >= 3 then
            local wordLowercased = word:lower()
            local intersection = wordLowercased:gsub('.', function(c) return alphabetChars:find(c, 1, true) and c or '' end)
            if intersection == wordLowercased then
                table.insert(filteredBlocklist, wordLowercased)
            end
        end
    end

    local instance = {
        alphabet = shuffle(alphabet),
        minLength = minLength,
        blocklist = filteredBlocklist
    }

    setmetatable(instance, Sqids)
    return instance
end

-- encode function in Lua
function Sqids:encode(numbers)
    -- if no numbers passed, return an empty string
    if #numbers == 0 then
        return ''
    end

    return encodeNumbers(self, numbers)
end

-- Decode function in Lua
function Sqids:decode(id)
    local ret = {} -- Array of unsigned integers

    -- if an empty string, return an empty array
    if id == '' then
        return ret
    end

    -- if a character is not in the alphabet, return an empty array
    local alphabetChars = {}
    for i = 1, #self.alphabet do
        table.insert(alphabetChars, self.alphabet:sub(i, i))
    end

    for i = 1, #id do
        local c = id:sub(i, i)
        local found = false
        for _, char in ipairs(alphabetChars) do
            if char == c then
                found = true
                break
            end
        end

        if not found then
            return ret
        end
    end

    -- first character is always the `prefix`
    local prefix = id:sub(1, 1)

    -- `offset` is the semi-random position that was generated during encoding
    local offset = self.alphabet:find(prefix, 1, true)

    -- re-arrange alphabet back into its original form
    local alphabet = self.alphabet:sub(offset) .. self.alphabet:sub(1, offset - 1)

    -- reverse alphabet
    alphabet = alphabet:reverse()

    -- now it's safe to remove the prefix character from ID, it's not needed anymore
    id = id:sub(2)

    -- decode
    while #id > 0 do
        local separator = alphabet:sub(1, 1)

        -- we need the first part to the left of the separator to decode the number
        local chunks = {}
        for chunk in id:gmatch(string.format("([^%s]*)", separator)) do
            table.insert(chunks, chunk)
        end

        if #chunks > 0 then
            -- if chunk is empty, we are done (the rest are junk characters)
            if chunks[1] == '' then
                return ret
            end

            -- decode the number without using the `separator` character
            local alphabetWithoutSeparator = alphabet:sub(2)
            table.insert(ret, toNumber(chunks[1], alphabetWithoutSeparator))

            -- if this ID has multiple numbers, shuffle the alphabet because that's what encoding function did
            if #chunks > 1 then
                alphabet = shuffle(alphabet)
            end
        end

        -- `id` is now going to be everything to the right of the `separator`
        id = table.concat(chunks, separator, 2)
    end

    return ret
end

return Sqids
