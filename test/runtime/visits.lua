local narrator, describe, it, assert = ...

local content = [[
  A root text
  + Go to knot -> knot
  === knot
  + Go to stitch -> stitch
  = stitch
  + Go to label -> label
  - (label) Some text
  + (choice) Go to root -> _._
]]

local book = narrator.parse_book(content)
local story = narrator.init_story(book)

story:begin()

local function visits()
  local visits = {
    root = story:get_visits(''),
    knot = story:get_visits('knot'),
    stitch = story:get_visits('knot.stitch'),
    label = story:get_visits('knot.stitch.label'),
    choice = story:get_visits('knot.stitch.choice')
  }
  return visits
end

local places = { 'root', 'knot', 'stitch', 'label' }

for cycle = 1, 3 do
  describe('Visits with cycle ' .. cycle .. '.', function()
    story:continue()

    for place_index = 1, #places do
      local place = places[place_index]

      it('Visit the ' .. place .. '.', function()
        story:continue()

        local place = place
        local divert = story.choices[1].divert

        local expected_root = cycle
        local expected_knot = place_index > 1 and cycle or cycle - 1
        local expected_stitch = place_index > 2 and cycle or cycle - 1
        local expected_label = place_index > 3 and cycle or cycle - 1
        local expected_choice = place_index > 4 and cycle or cycle - 1

        local visits = visits()

        assert.equal(visits.root, expected_root)
        assert.equal(visits.knot, expected_knot)
        assert.equal(visits.stitch, expected_stitch)
        assert.equal(visits.label, expected_label)
        assert.equal(visits.choice, expected_choice)

        story:choose(1)
      end)
    end

  end)
end