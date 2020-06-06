--
-- Dependencies

local lume = require("lume")

local libPath = (...):gsub(".init$", "")
local enums = require(libPath .. ".enums")
local parser = require(libPath .. ".parser")
local Story = require(libPath .. ".story")

--
-- Private

local function clearPath(path)
    local path = path:gsub(".lua$", "")
    local path = path:gsub(".ink$", "")

    if path:match("%.") and not path:match("/") then
        path = path:gsub("%.", "/")
    end

    return path
end

local function merge(parent, childPath, maker)
    local child = maker(childPath)

    if child.version.engine and child.version.engine ~= enums.engineVersion then
        assert("Vesrion of model '" .. childPath .. "' (" .. child.version.engine ..")"
        .. " isn't equal to version of Narrator (" .. enums.engineVersion .. ").")
    end

    for _, include in ipairs(child.includes or { }) do
        local includePath = childPath:match('(.-)[^%./]+$') .. clearPath(include)
        child = merge(child, includePath, maker)
    end

    parent.tree = lume.merge(parent.tree or { }, child.tree or { })
    parent.constants = lume.merge(parent.constants or { }, child.constants or { })
    parent.lists = lume.merge(parent.lists or { }, child.lists or { })
    parent.variables = lume.merge(parent.variables or { }, child.variables or { })
    
    return parent
end

local function parseModel(path, save)
    local inkPath = path .. ".ink"
    local luaPath = path .. ".lua"

    local file = io.open(inkPath, "r")
    assert(file, "File doesn't exist: " .. inkPath)

    local content = file:read("*all")
    file:close()

    local model = parser.parse(content)

    if save then
        local data = lume.serialize(model)
        data = data:gsub("%[%d+%]=", "")
        data = data:gsub("[\"[%w_]+\"]", function(match) return
            match:sub(3, #match - 2)
        end)
        
        local file = io.open(luaPath, "w")
        file:write("return " .. data)
        file:close()
    end

    return model
end

local function loadStory(path, maker)
    local cleanPath = clearPath(path)

    local model = merge({ }, cleanPath, maker)
    local story = Story(model)

    return story
end

--
-- Narrator

local Narrator = { }

--- Parse story from a ink file
-- @param inkPath string: ink file path
-- @param save bool: save a parsed result to lua file or not
-- @return story
function Narrator.parseStory(inkPath, save)
    local maker = function(path) return parseModel(path, save) end
    return loadStory(inkPath, maker)
end

--- Load story from a lua file
-- @param luaPath string: lua file path
-- @return story
function Narrator.loadStory(luaPath)
    local maker = function(path) return require(path) end
    return loadStory(luaPath, maker)
end

return Narrator