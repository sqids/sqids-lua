# [Sqids Lua](https://sqids.org/lua)

Sqids (pronounced "squids") is a small library that lets you generate YouTube-looking IDs from numbers. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

Features:

- **Encode multiple numbers** - generate short IDs from one or several non-negative numbers
- **Quick decoding** - easily decode IDs back into numbers
- **Unique IDs** - generate unique IDs by shuffling the alphabet once
- **ID padding** - provide minimum length to make IDs more uniform
- **URL safe** - auto-generated IDs do not contain common profanity
- **Randomized output** - Sequential input provides nonconsecutive IDs
- **Many implementations** - Support for [40+ programming languages](https://sqids.org/)

## 🧰 Use-cases

Good for:

- Generating IDs for public URLs (eg: link shortening)
- Generating IDs for internal systems (eg: event tracking)
- Decoding for quicker database lookups (eg: by primary keys)

Not good for:

- Sensitive data (this is not an encryption library)
- User IDs (can be decoded revealing user count)

##  🚀 Getting started

Sqids is available on [LuaRocks](https://luarocks.org/modules/nascarsayan/sqids-lua):

```bash
luarocks install sqids-lua
```

## 👩‍💻 Examples


```lua
local Sqids = require("sqids")
local sqids = Sqids.new()

local encoded = sqids:encode({ 1, 2, 3 }) -- 86Rf07
local decoded = sqids:decode(encoded) -- 1, 2, 3
```

Enforce a *minimum* length for IDs:

```lua
local Sqids = require("sqids")
local sqids = Sqids.new({
    minLength = 10,
})

local id = sqids:encode({ 1, 2, 3 }) -- 86Rf07xd4z
local numbers = sqids:decode(id) -- [1, 2, 3]
```

## 📝 License

[MIT](LICENSE)
