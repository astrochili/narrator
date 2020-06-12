# Narrator
The [Ink](https://www.inklestudios.com/ink/) language parser and runtime implementation in Lua.

*Work in progress*

## Roadmap
- Documentation
- Test cases
- Defold extension

## Quick example

```lua
-- Dependencies
local narrator = require('narrator')

-- Parse a book from the Ink file.
-- You can save a book anywhere to load it in the future, the book is just a Lua table.
local book = narrator.parseFile('stories.game', { save = false })

-- Init the story from a book
local story = narrator.initStory(book)

-- Bind local function to observe the ink variable 'x'
story:observe('x', function(x) print('The x did change! Now it\'s ' .. x) end)

-- Bind local functions to call from ink as external functions
story:bind('beep', function() print('ATENTION. Beep! 😃') end)
story:bind('sum', function(x, y) return x + y end)

-- Begin the story
story:begin()

while story:canContinue() do
  
  -- Get current paragraphs to output
  local paragraphs = story:continue()

  for _, paragraph in ipairs(paragraphs) do
    local text = paragraph.text

    -- You can handle tags as you like, but we attach them to text here.
    if paragraph.tags then
      text = text .. ' #' .. table.concat(paragraph.tags, ' #')
    end

    -- Output text to the player
    print(text)
  end

  -- If there is no choice, it seems the game is over
  if not story:canChoose() then break end
  
  -- Get available choices and output them to the player
  local choices = story:getChoices()
  for i, choice in ipairs(choices) do
    print(i .. ') ' .. choice.title)
  end

  -- Read the choice from the player input
  answer = tonumber(io.read())

  -- Send answer to the story to generate new paragraphs
  story:choose(answer)
end
```

## Dependencies

Parser uses [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/).
```
$ luarocks install lpeg
```

Tests use [busted](https://github.com/Olivine-Labs/busted).
```
$ luarocks install busted
```