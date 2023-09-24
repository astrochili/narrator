local narrator, describe, it, assert = ...

local content = [[
  VAR mood = "sadly"
  ~ mood = "sunny"
]]

local book = narrator.parse_content(content)
local story = narrator.init_story(book)

local mood

story:observe('mood', function(value)
  mood = value
end)

story:begin()

it('Sunny mood.', function()
  assert.equal(mood, 'sunny')
end)