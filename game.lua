--
-- Dependencies

local dinky = require("dinky.dinky")

--
-- Game

function game()
    local story = dinky:loadStory("stories/dev")
    local answers = { 1, 1, 1, 1, 1 }

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
            answer = answers[1]
            table.remove(answers, 1)
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

function sleep(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end

game()