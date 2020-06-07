--
-- Script for debugging in VSCode with
-- Local Lua Debugger by Tom Blind (https://github.com/tomblind/local-lua-debugger-vscode)

-- Environment
package.path = _VERSION == "Lua 5.3" and package.path or "./?/init.lua;" .. package.path

-- Dependencies
local narrator = require("narrator")
local bot = require("bot")

-- Loading
local story = narrator.parseStory("stories.debug")
local answers = { }

-- Choice instructor for a bot
local function instructor(choices)
    local answer = table.remove(answers, 1)
    if answer == nil then
        math.randomseed(os.clock() * 100000000000)
        answer = math.random(1, #choices)
    end
    return answer
end

-- Game
print("--- Game started ---\n")
bot.play(story, instructor)
print("\n--- Game over ---")