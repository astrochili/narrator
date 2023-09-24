local narrator, describe, it, assert = ...

local content = [[
  VAR x = 1
  * (choice) [Hello]
  - (hello) Hello world!
  -> knot
  === knot
  = stitch
  ~ x = 2
  ~ temp y = 3
  A line 1
  A line 2
  A line 3
  * Just a road to hell -> END
  * The best road to hell -> END
]]

local book = narrator.parse_book(content)

local saved_state

it('Saving', function()
  local story = narrator.init_story(book)
  story:begin()
  story:continue()
  story:choose(1)
  story:continue(2)

  saved_state = story:save_state()

  local expected_path = { knot = 'knot', stitch = 'stitch' }
  assert.are.same(saved_state.path, expected_path)
  assert.equal(saved_state.variables['x'], 2)
  assert.equal(saved_state.temp['y'], 3)
  assert.equal(saved_state.visits._._.hello, 1)
  assert.equal(#saved_state.output, 2)
  assert.equal(#saved_state.paragraphs, 2)
  assert.equal(#saved_state.choices, 2)
end)

it('Loading.', function()
  local story = narrator.init_story(book)
  story:begin()
  story:load_state(saved_state)

  local expected_path = { knot = 'knot', stitch = 'stitch' }
  assert.are.same(story.current_path, expected_path)
  assert.equal(story.variables['x'], 2)
  assert.equal(story.temp['y'], 3)
  assert.equal(story:get_visits('hello'), 1)
  assert.equal(#story.output, 2)

  local paragraphs = story:continue()
  local choices = story:get_choices()

  assert.equal(#paragraphs, 2)
  assert.equal(#choices, 2)
end)