--
-- Dependencies

local dinky = require("dinky.dinky")

--
-- Game

function game()
    local story = dinky:loadStory("stories/main")

    while story:canContinue() or #story:choices() > 0 do 
        while story:canContinue() do
            sleep(0.3)
            local text = story:continue()
            print(text)
        end
    
        local choices = story:choices()
        for i, choice in ipairs(choices) do
            print(i .. ") " .. choice.title)
        end
    
        local answer
        if debug.vscode then
            sleep(1.0)
            answer = math.random(1, #choices)
        else
            answer = tonumber(io.read())
        end
        
        local text = story:choose(answer)
        print(text)
    end
end

function sleep(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end

game()