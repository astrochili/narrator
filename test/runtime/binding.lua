local narrator, describe, it, assert = ...

local content = [[
  ~ beep()
  { sum(1, 2) }
  { did_solve_puzzle("labirint") }
]]

local book = narrator.parse_content(content)
local story = narrator.init_story(book)

local is_beeped = false
local puzzles = { }

story:bind('beep', function()
  is_beeped = true
end)

story:bind('sum', function(x, y)
  return x + y
end)

story:bind('did_solve_puzzle', function(puzzle)
  puzzles[puzzle] = true
end)

story:begin()

it('Was a beep?', function()
  assert.is_true(is_beeped)
end)

it('Sum is equal to 3.', function()
  local paragraphs = story:continue()
  assert.equal(#paragraphs, 1)
  assert.equal('3', paragraphs[1].text)
end)

it('Labirint is sovled.', function()
  local puzzle_is_solved = puzzles['labirint']
  assert.is_true(puzzle_is_solved)
end)