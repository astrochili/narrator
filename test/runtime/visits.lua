local narrator, describe, it, assert = ...

local content = [[
  A root text
  + Go to knot -> knot
  === knot
  + Go to stitch -> stitch
  = stitch
  + Go to label -> label
  - (label) Some text
  + (choice) Go to root -> _
]]

local book = narrator.parseBook(content)
local story = narrator.initStory(book)

story:begin()

local function visits()
  local visits = {
    root = story:getVisitsFor('_._'),
    knot = story:getVisitsFor('knot'),
    stitch = story:getVisitsFor('knot.stitch'),
    label = story:getVisitsFor('knot.stitch.label'),
    choice = story:getVisitsFor('knot.stitch.choice')
  }
  return visits
end

local places = { 'root', 'knot', 'stitch', 'label' }

for cycle = 1, 3 do
  describe('Visits with cycle ' .. cycle .. '.', function()
    story:continue()
    
    for placeIndex = 1, #places do
      local place = places[placeIndex]

      it('Visit the ' .. place .. '.', function()
        story:continue()

        local place = place
        local divert = story.choices[1].divert
        
        local expectedRoot = cycle
        local expectedKnot = placeIndex > 1 and cycle or cycle - 1
        local expectedStitch = placeIndex > 2 and cycle or cycle - 1
        local expectedLabel = placeIndex > 3 and cycle or cycle - 1
        local expectedChoice = placeIndex > 4 and cycle or cycle - 1
        
        local visits = visits()

        assert.equal(visits.root, expectedRoot)
        assert.equal(visits.knot, expectedKnot)
        assert.equal(visits.stitch, expectedStitch)
        assert.equal(visits.label, expectedLabel)
        assert.equal(visits.choice, expectedChoice)

        story:choose(1)
      end)
    end

  end)
end