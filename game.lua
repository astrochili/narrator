local dinky = require("libs.dinky")

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
    local text = choices[answer].text
    print(text)
    story:choose(answer)
end