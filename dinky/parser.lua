--
-- Dependencies

local lpeg = require("lpeg")

local localFolder = (...):match("(.-)[^%.]+$")
local enums = require(localFolder .. "enums")

--
-- Parser

local Parser = { }

function Parser:parse(lines)
    for line in lines do
        print(line)
    end

    -- TODO

    return nil
end

return Parser