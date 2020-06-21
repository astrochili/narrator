# Narrator
The [Ink](https://www.inklestudios.com/ink/) language parser and runtime implementation in Lua.

Ink is a powerful narrative scripting language. You can find more information about how to write Ink scripts [here](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md). There is also [Inky](https://github.com/inkle/inky) editor with useful features to test and debug Ink scripts.

Narrator allows to convert raw Ink scripts to the book (a lua table) and play it as story.

- A book is a passive model on the shelf like a game level.
- A story is a runtime state of the book reading like a game process.

## Quick example

```lua
-- Dependencies
local narrator = require('narrator')

-- Parse a book from the Ink file.
local book = narrator.parseFile('stories.game')

-- Init a story from the book
local story = narrator.initStory(book)

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

  -- If there is no choice it seems like the game is over
  if not story:canChoose() then break end
  
  -- Get available choices and output them to the player
  local choices = story:getChoices()
  for i, choice in ipairs(choices) do
    print(i .. ') ' .. choice)
  end

  -- Read the choice from the player input
  answer = tonumber(io.read())

  -- Send answer to the story to generate new paragraphs
  story:choose(answer)
end
```

## Dependencies

Parser uses [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/). Functions ```parseFile()``` and ```parseBook()``` won't work without ```lpeg```.

```
$ luarocks install lpeg
```

You really don't need ```lpeg``` in the release, but you need it locally to parse Ink content and generate lua versions of books to play.

## Documentation

### narrator.parseFile(path, params)
Parses the Ink file at path with all the inclusions and returns a book instance. Path notations ```'stories/game.ink'```, ```'stories/game'``` and ```'stories.game'``` are valid.

You can save a parsed book to the lua file with the same path by passing ```{ save = true }``` as ```params``` table. The ```params``` table is optional and equal to ```{ save = false }``` by default.

- Parsing required ```lpeg``` so use it in development only, prefer already parsed and stored books in production.
- Reading and saving files required ```io``` so use ```narrator.parseBook()``` if you can't work with files by this way.

```lua
-- Parse a Ink file at path 'stories/game.ink'
local book = narrator.parseFile('stories.game')

-- Parse a Ink file at path 'stories/game.ink'
-- and save a book at path 'stories/game.lua'
local book = narrator.parseFile('stories.game', { save = true })
```

### narrator.parseBook(content, includes)
Parses the string with Ink content and returns a book instance. The ```includes``` param is optional and can be used to pass an array of strings with Ink content of inclusions.

String content parsing is useful when you should manage files by your engine environment (Defold, LÖVE, etc.) and you can pass to ```narrator``` the content of these files only.

- Parsing required ```lpeg``` so use it in development only, prefer already parsed and stored books in production.

```lua
local content = 'Content of a root Ink file'
local inclusions = {
  'Content of an included Ink file',
  'Content of another included Ink file'
}

-- Parse a string with Ink content
local book = narrator.parseBook(content)

-- Parse a string with Ink content and inclusions
local book = narrator.parseBook(content, inclusions)
```

### narrator.initStory(book)
Inits a story instance from the book. This is aclual to use in production. For example, just load a book with ```require()``` and pass it to this function.

```lua
-- Require a parsed and saved before book
local book = require('stories.game')

-- Init a story instance
local story = narrator.initStory(book)
```

### story:begin()
Begins the story. Generates the first chunk of paragraphs and choices.

### story:canContinue()
Returns a boolean, does the story have paragraphs to output or not.

```lua
while story:canContinue() do
  -- Get paragraphs?
end
```

### story:continue(steps)
Get the next paragraphs. You can specify the number of paragraphs that you want to pull by the ```steps``` param.
- Pass nothing if you want to get all the currently available paragraphs. ```0``` also works.
- Pass ```1``` if you want to get one next paragraph without wrapping to array.

A paragraph is a table like ```{ text = 'Hello.', tags = { 'tag1', 'tag2' } }```. The most of paragraphs doesn't have tags so ```tags``` can be ```nil```.


```lua
-- Get all the currently available paragraphs
local paragraphs = story:continue()

-- Get one next paragraph
local paragraph = story:continue(1)
```

### story:canChoose()
Returns a boolean, does the story have choices to output or not. Also returns ```false``` if there are available paragraphs to continue.

```lua
if story:canChoose() do
  -- Get choices?
end
```

### story:getChoices()
Returns an array of available choice titles. Returns an empty array if there are available paragraphs to continue.

```lua
  -- Get available choices and output them to the player
  local choices = story:getChoices()
  for i, choice in ipairs(choices) do
    print(i .. ') ' .. choice)
  end
```

### story:choose(index)
Make a choice to continue the story. Pass the ```index``` of the choice that you was received with ```getChoices()``` before. Will do nothing if ```canContinue()``` returns ```false```.

```lua
  -- Get the answer from the player in the terminal
  answer = tonumber(io.read())

  -- Send the answer to the story to generate new paragraphs
  story:choose(answer)

  -- Get the new paragraphs
  local newParagraphs = story:continue()
```

### story:jumpTo(pathString)
Jumps to the path. The ```pathString``` param is a string like ```'knot.stitch.label'```.

```lua
  -- Jump to the maze stitch in the adventure knot
  story:jumpTo('adventure.maze')

  -- Get the maze paragraphs
  local mazeParagraphs = story:continue()
```

### story.getVisits(pathString)
Returns the number of visits to the path. The ```pathString``` param is a string like ```'knot.stitch.label'```.

```lua
-- Get the number of visits to the maze's red room
local mazeTags = story:getVisits('adventure.maze.red_room')

-- Get the number of adventures visited.
local mazeTags = story:getVisits('adventure')
```

### story:getTags(pathString)
Returns tags for the path. The ```pathString``` param is a string like ```'knot.stitch'```. This function is useful when you want to get tags before continue the story and pull paragraphs. Read more about it [here](https://github.com/inkle/ink/blob/master/Documentation/RunningYourInk.md#knot-tags).

```lua
-- Get tags for the path 'adventure.maze'
local mazeTags = story:getTags('adventure.maze')
```

### story:saveState()
Raturns a table with the story state that can be saved and restored later. Use it to save the game.

```lua
-- Get the story's state
local state = story:saveState()

-- Save the state to your local storage
manager.save(state)
```

### story:loadState(state)
Restores a story's state from the saved before state. Use it to load the game.

```lua
-- Load the state from your local storage
local state = manager.load()

-- Restore the story's state
story:loadState(state)

```

### story:observe(variable, observer)
Assigns an observer function to the variable's changes.

```lua
local function xDidChange(x)
  print('The x did change! Now it\'s ' .. x)
end

-- Start observing the variable 'x'
story:observe('x', xDidChange)
```

### story:bind(funcName, handler)
Binds a function to external calling from the Ink. The function can returns the value or not.

```lua
local function beep()
  print('Beep! 😃')
end

local function sum(x, y)
  return x + y
end

-- Bind the function without params and returned value
story:bind('beep', beep)

-- Bind the function with params and returned value
story:bind('sum', sum)
```

### story.globalTags
An array with book's global tags. Tags are strings of course.

```lua
-- Get the global tags
local globalTags = story.globalTags

-- A hacky way to get the same global tags
local globalTags = story:getTags()
``` 

### story.constants
A table with book's constants. Just read them, constants changing is not a good idea.

```lua
-- Get the theme value from the Ink constants
local theme = story.constants['theme']
```

### story.variables
A table with story's variables. You can read or change them by this way.

```lua
-- Get the mood variable value
local mood = story.variables['mood']

-- Set the mood variable value
story.variables['mood'] = 'sunny'
```

### story.migrate
A function that you can specify for migration from old to new versions of your books. This is useful, for example, when you don't want to corrupt player's save after the game update.

This is the place where you can rename or change variables, visits, update the current path, etc. The default implementation returns the same state without any migration.


```lua
-- Default implementation
function(state, oldVersion, newVersion) return state end
```

The ```oldVersion``` is the version of the saved state, the ```newVersion``` is the version of the book. You can specify the verson of the book with the constant ```'version'``` in the Ink content, otherwise it's equal to ```0```.

```lua
-- A migration function example
local function migrate(state, oldVersion, newVersion)

  -- Check the need for migration
  if newVersion == oldVersion then
    return state
  end

  -- Migration for the second version of the book
  if newVersion == 2 then

    -- Get the old value
    local oldMood = state.variables['mood']

    -- If it exists then migrate ...
    if oldMood then 
      -- ... migrate the old number value to the new string value
      state.variables['mood'] = oldMood < 50 and 'sadly' or 'sunny'
    end
  end

  return state
end

-- Assign the migration function before loading a saved game
story.migrate = migrate

-- Load the game
story:loadState(savedState)
```

## Tests

To run tests you need to install [busted](https://github.com/Olivine-Labs/busted).
```
$ luarocks install busted
```

After that you can run tests from the terminal:
```
$ busted tests/run.lua
```

By the way, there are some configs for [VSCode](https://code.visualstudio.com/). For example, a task named ```Busted``` runs tests.

## Roadmap
- The Defold extension
- More documented and commented code
- Performance optimization and refactoring
- Remain features support