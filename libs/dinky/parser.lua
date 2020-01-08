--
-- Dependencies

local lpeg = require("lpeg")

--
-- Parser

local Parser = { }

function Parser:parse(lines)
    for line in lines do
        print(line)
    end

    return { }
end

return Parser