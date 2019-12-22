local localFolder = (...):match("(.-)[^%.]+$") or (...)
local Story = require(localFolder .. ".story")
local Dinky = { }

function Dinky:parseStory(inkFile)
    -- TODO: Make a parser of Ink language
    return { filePath = inkFile }
end

function Dinky:loadStory(luaFile)
    local tree = require(luaFile)
    return Story(tree)
end

return Dinky