--
-- Testing with Busted library

require('busted.runner')()

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end

local bot = require('bot')
local narrator = require('narrator')
local lume = require('narrator.libs.lume')

local folderSeparator = package.config:sub(1,1)

--- Make path fot ink
-- @param case string: a test case
-- @return string: a path
local function inkPath(case)  
  local path = 'test' .. folderSeparator .. 'ink' .. folderSeparator .. case .. '.ink'
  return path
end

--- Make path fot txt
-- @param case string: a test case
-- @param answers table: a sequence of answers (numbers)
-- @return string: a path
local function txtPath(case, answers)
  local path = 'test' .. folderSeparator .. 'txt' .. folderSeparator .. case
  if answers and #answers > 0 then
    path = path .. folderSeparator .. table.concat(answers, "-")
  end
  path = path .. '.txt'
  return path
end

--- Get all possible sequences and logs of the case
-- @param case string: a test case
-- @return table: an array of possible games { sequence, log }
local function getPossibleResults(case)
  local path = inkPath(case)
  local book = narrator.parseFile(path)
  
  local results = { }
  local sequences = { { } }
  local seqIndex

  local function instructor(choices, step)
    local curSeq = sequences[seqIndex]
    local answer = curSeq[step]
    
    if not answer then
      -- Transform a current sequence to branches for each available choice
      table.remove(sequences, seqIndex)

      for index, choice in ipairs(choices) do
        local newSeq = lume.concat(curSeq, { index })
        table.insert(sequences, newSeq)
      end

      -- Set a stop signal for the bot
      answer = -1
    end

    return answer
  end

  while #sequences > 0 do
    -- Iterate sequences and play them
    for index = 1, #sequences do
      local sequence = sequences[index]
      seqIndex = index

      -- Play the sequence
      local story = narrator.initStory(book)
      local log = bot.play(story, instructor)

      -- If the sequence was finished then save the result and mark it as finished
      if log then
        local result = { sequence = sequence, log = log }
        table.insert(results, result)
        sequences[index] = { isFinished = true }
      end
    end

    -- Remove finished sequences
    for index = #sequences, 1, -1 do
      local sequence = sequences[index]
      if sequence.isFinished then
        table.remove(sequences, index)
      end
    end    
  end

  return results
end

--- Generate possible results for a test case and save them to txt files
-- @param case string: a test case
-- @param override bool: override a txt file if it already exists
local function generateTxtForCase(case, override)
  local override = override ~= nil and override or false
  local results = getPossibleResults(case)
  
  for _, result in ipairs(results) do
    local txtPath = txtPath(case, result.sequence)    
    local file = io.open(txtPath, 'r')
    local isFileExists = file ~= nil
    if isFileExists then io.close(file) end

    if not isFileExists or override then
      local folderPath = txtPath:match('(.*' .. folderSeparator .. ')')
      local folder = io.open(folderPath, 'r')
      local isFolderExists = folder ~= nil
      if isFolderExists then
        io.close(folder)
      else
        os.execute('mkdir ' .. folderPath)
      end

      file = io.open(txtPath, 'w')
      assert(file, 'Has no access to the file at path  \'' .. txtPath .. '\'.')
      
      file:write(result.log)
      file:close()
    end
  end
end

--- Test the case
-- @param case string: a test case
local function testCase(case)
  describe('Test case \'' .. case .. '\'.', function()
    local path = inkPath(case)
    local book = narrator.parseFile(path)

    local results = getPossibleResults(case)
    for _, result in ipairs(results) do
      describe('Sequence [' .. table.concat(result.sequence, "-") .. '].', function()
        local txtPath = txtPath(case, result.sequence)
        local file = io.open(txtPath, 'r')

        it('Checking results.', function()
          assert.is_not_nil(file)

          local expected = file:read('*all')
          file:close()
  
          assert.are.same(expected, result.log)
        end)
      end)
    end
  end)
end

--- Generate possible results for test cases and save them to txt files
-- @param cases table: an array of test cases
-- @param override bool: override the txt file if it already exists
local function generateTxtForCases(cases, override)
  for _, case in ipairs(cases) do
    generateTxtForCase(case, override)
  end
end

--- Test the cases
-- @param cases table: an array of test cases
local function testCases(cases)
  for _, case in ipairs(cases) do
    testCase(case)
  end
end

local cases = require('test.cases')
-- generateTxtForCases(cases, true)
testCases(cases)