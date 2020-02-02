--
-- Dependencies

local localFolder = (...):gsub(".init$","")
local parser = require(localFolder .. ".parser")
local Story = require(localFolder .. ".story")

--
-- Dinky

local Dinky = { }

function Dinky:parseStory(inkPath)
    local hasExtension = inkPath:sub(-4) == ".ink"
    local file = io.open(inkPath .. (hasExtension and "" or ".ink"), "r")
    
    if file == nil then
        print("File doesn't exist: " .. inkPath)
        return nil
    end

    for line in io.lines(file) do 
        lines[#lines + 1] = line
    end
    file:close()
    
    model = parser.parse(lines)
    model.inkPath = inkPath
    return model
end

function Dinky:loadStory(luaPath)
    local model = require(luaPath)
    model.luaPath = luaPath
    return Story(model)
end

return Dinky