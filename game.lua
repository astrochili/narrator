--
-- Dependencies

local dinky = require("dinky.dinky")

--
-- Game

function game()
    local story = dinky:loadStory("stories/dev")

    print("\n--- Game begin ---")

    while story:canContinue() do 
        while story:canContinue() do
            local paragraph = story:continue()[1]
            print(paragraph)
        end
    
        if not story:canChoose() then break end

        local choices = story:getChoices()
        for i, choice in ipairs(choices) do
            print(i .. ") " .. choice.title)
        end
    
        local answer
        if debug.vscode then
            math.randomseed(os.time())
            answer = math.random(1, #choices)
        else
            answer = tonumber(io.read())
        end
        
        print(debug.vscode and answer .. "^" or "")

        local text = story:choose(answer)
        if text ~= nil then
            print(text)
        end        
    end

    print("--- Game over ---")
end

function sleep(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end

game()