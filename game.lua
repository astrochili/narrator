--
-- Preconfig

debug.vscode = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1"
package.path = _VERSION == "Lua 5.3" and package.path or "./?/init.lua;" .. package.path

--
-- Dependencies

local dinky = require("dinky")

--
-- Game

local story = dinky.loadStory("stories.dev_root")
local botAnswers = { 1, 1, 1, 1, 1 }

story:observe("y", function(y) print("The y did change! Now it's " .. y) end)
story:bind("beep", function() print("ATENTION. Beep! 😃") end)
story:bind("sum", function(x, y) return x + y end)
story:begin()

print("\n--- Game begin ---")

while story:canContinue() or story:canChoose() do 
    while story:canContinue() do
        local paragraph = story:continue()[1]
        local currentTags = paragraph.tags
        print(paragraph.text)
    end

    if not story:canChoose() then break end

    local choices = story:getChoices()
    for i, choice in ipairs(choices) do
        print(i .. ") " .. choice.title)
    end

    math.randomseed(os.time())

    local answer
    if debug.vscode then
        answer = table.remove(botAnswers, 1)
        answer = answer or math.random(1, #choices)
    else
        answer = tonumber(io.read())
    end
    
    print(debug.vscode and answer .. "^" or "")
    story:choose(answer)
end

print("--- Game over ---")