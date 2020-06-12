--
-- Testing with Busted library

require('busted.runner')()

local narrator = require('narrator')
local bot = require('bot')

--- Run a test with parameters
-- @param path string: a path to the ink file
-- @param answers table: an array of bot answers (numbers)
-- @param expected string: an expected output of the game
local function run(book, answers, expected)
  local story = narrator.initStory(book)
  
  local function instructor()
    local answer = table.remove(answers, 1)
    assert.truthy(answer)
    return answer
  end

  local log = bot.play(story, instructor, true)
  assert.are.same(expected, log)
end

--- Run a test case
-- @param case table: a test case with name and answers
local function test(case)
  local inkPath = 'test/ink/' .. case.ink .. '.ink'
  local txtPath = 'test/txt/' .. (case.txt or case.ink) .. '.txt'
  local file = io.open(txtPath, 'r')
  local expected = file:read('*all')
  file:close()

  local book = narrator.parseFile(inkPath)
  run(book, case.answers, expected)
end

-- Iterate and run test cases
local cases = require('test.cases')
describe('Test case', function()
  for _, case in ipairs(cases) do
    it('\'' .. case.ink .. '\'.', function()
      test(case)
    end)
  end
end)