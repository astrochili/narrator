--
-- Dependencies

local localFolder = (...):match('(.-)[^%.]+$') or (...)
local parser = require(localFolder .. "dinky.parser")
local Story = require(localFolder .. "dinky.story")

--
-- Dinky

local Dinky = { }

function Dinky:parseStory(inkPath)
    local filePath = inkPath
    if inkPath:sub(-4) == ".ink" then
        filePath = inkPath .. ".ink"
    end

    local file = io.open(filePath, "r")
    if file == nil then
        print("File doesn't exist: " .. filePath)
        return nil
    end

    for line in io.lines(file) do 
        lines[#lines + 1] = line
    end
    file:close()
    
    model = parser.parse(lines)
    model.filePath = filePath
    return model
end

function Dinky:loadStory(luaPath)
    local tree = require(luaPath)
    return Story(tree)
end

return Dinky