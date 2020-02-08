--
-- Dependencies

local lpeg = require("lpeg")

local libPath = (...):match("(.-).[^%.]+$")
local enums = require(libPath .. ".enums")

--
-- Parser

local Parser = { }

function Parser.parse(lines)
    local model = { version = {
        engine = enums.engineVersion,
        tree = 1
    } }

    for _, line in ipairs(lines) do
        print(line)
    end

    return model
end

return Parser