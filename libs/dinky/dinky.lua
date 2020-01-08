--
-- Dependencies

local localFolder = (...):match('(.-)[^%.]+$') or (...)
local parser = require(localFolder .. ".parser")
local Story = require(localFolder .. ".story")

--
-- Dinky

local Dinky = { }

function Dinky:parseStory(inkFile)
    local file = io.open(inkFile, "r")
    if file == nil then
        print("File doesn't exist: " .. inkFile)
        return nil
    end

    for line in io.lines(file) do 
        lines[#lines + 1] = line
    end
    file:close()
    
    model = parser.parse(lines)
    model.filePath = inkFile
    return model
end

function Dinky:loadStory(luaFile)
    local tree = require(luaFile)
    return Story(tree)
end

return Dinky