require("utils")
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

    local answer
    if debugging then
        answer = math.random(1, #choices)
        sleep(1)
    else
        answer = tonumber(io.read())
    end
    
    local text = story:choose(answer)
    print(text)
end