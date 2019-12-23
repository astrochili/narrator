if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    local separator = string.sub(package.config, 1, 1)
    local filePath = debug.getinfo(1).short_src
    local rootFolder = string.gsub(filePath, "^(.+"..separator..")[^"..separator.."]+$", "%1");
    package.path = rootFolder .. [[?.lua]]
end

local dinky = require("libs.dinky.dinky")

-- local story = dinky.parseStory("stories/main")
local story = dinky:loadStory("stories/main")

while story:canContinue() or #story:choices() > 0 do 
    while story:canContinue() do
        local text = story:continue()
        print(text)
    end

    local choices = story:choices()
    for i, choice in ipairs(choices) do
        print(i .. ") " .. choice.title)
    end

    local answer = tonumber(io.read())
    local text = "1" --choices[answer].text
    story:choose(answer)
end