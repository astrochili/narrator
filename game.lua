--
-- A simple command-line game example

-- Environment
package.path = _VERSION == "Lua 5.3" and package.path or "./?/init.lua;" .. package.path

-- Dependencies
local narrator = require("narrator")

-- Parse and load an ink story
local story = narrator.parseStory("stories.game")

-- Bind local function to observe the ink variable 'x'
story:observe("x", function(x) print("The x did change! Now it's " .. x) end)

-- Bind local functions to call from ink as external functions
story:bind("beep", function() print("ATENTION. Beep! 😃") end)
story:bind("sum", function(x, y) return x + y end)

-- Begin the story
story:begin()

print("--- Game started ---\n")

while story:canContinue() do
    
    -- Get current paragraphs to output
    local paragraphs = story:continue()

    for _, paragraph in ipairs(paragraphs) do
        local text = paragraph.text

        -- You can handle tags as you like, but we attach them to text here.
        if paragraph.tags then
            text = text .. " #" .. table.concat(paragraph.tags, " #")
        end

        -- Output text to the player
        print(text)
    end

    -- If there is no choice, it seems the game is over
    if not story:canChoose() then break end
    print("")
    
    -- Get available choices and output them to the player
    local choices = story:getChoices()
    for i, choice in ipairs(choices) do
        print(i .. ") " .. choice.title)
    end

    -- Read the choice from the player input
    answer = tonumber(io.read())
    print("")

    -- Send answer to the story to generate new paragraphs
    story:choose(answer)
end

print("\n--- Game over ---")