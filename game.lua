--
-- Dependencies

debug.vscode = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1"
local dinky = require("dinky")

--
-- Game

local function game()
    local story = dinky:loadStory("stories.dev")

    story:observe("y", function(y) print("The y did change! Now it's " .. y) end)
    story:bind("beep", function() print("ATENTION. Beep! 😃") end)
    story:bind("sum", function(x, y) return x + y end)
    
    print("\n--- Game begin ---")
    local botAnswers = { 1, 1, 1, 1, 1 }

    while story:canContinue() do 
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
    
        local answer
        if debug.vscode then
            answer = botAnswers[1]
            table.remove(botAnswers, 1)
            math.randomseed(os.time())
            answer = answer or math.random(1, #choices)
        else
            answer = tonumber(io.read())
        end
        
        print(debug.vscode and answer .. "^" or "")
        story:choose(answer)
    end

    print("--- Game over ---")
end

game()