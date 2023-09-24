local narrator, describe, it, assert = ...

local content = [[
  # global tag 1
  # global tag 2 # global tag 3
  Root line -> knot
  === knot ===
  # knot tag
  A knot line 1 # line 1 tag
  A knot line 2 # line 2 tag
  = stitch
  # stitch tag
  A stitch line # line 3 tag
]]

local book = narrator.parse_book(content)
local story = narrator.init_story(book)

story:begin()

local paragraphs = story:continue()

it('Global tags.', function()
  local expected = { 'global tag 1', 'global tag 2', 'global tag 3' }
  assert.are.same(expected, story.global_tags)

  local global_tags = story:get_tags()
  assert.are.same(expected, global_tags)
end)

it('Knot tags.', function()
  local expected = { 'knot tag' }
  local knot_tags = story:get_tags('knot')
  assert.are.same(expected, knot_tags)
end)

it('Stitch tags.', function()
  local expected = { 'stitch tag' }
  local stitch_tags = story:get_tags('knot.stitch')
  assert.are.same(expected, stitch_tags)
end)

it('Paragraph tags.', function()
  assert.equal(#paragraphs, 2)

  local expected = { 'global tag 1', 'global tag 2', 'global tag 3', 'knot tag', 'line 1 tag' }
  assert.are.same(expected, paragraphs[1].tags)

  local expected = { 'line 2 tag' }
  assert.are.same(expected, paragraphs[2].tags)
end)