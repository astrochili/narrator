--
-- Dependencies

local lpeg = require("lpeg")

local libPath = (...):match("(.-).[^%.]+$")
local enums = require(libPath .. ".enums")

--
-- Parser

local Parser = { }

function Parser.parse(lines)
    local model = { }
    model.version = { engine = enums.engineVersion, tree = 1 }
    model.root = { _ = { _ = { } } }

    for _, line in ipairs(lines) do
        -- TODO lpeg parsing
    end

    return model
end

return Parser