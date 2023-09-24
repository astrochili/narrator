--
-- Testing with Busted library

--
-- Dependencies

require('busted.runner')()

if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
  require("lldebugger").start()
end

local bot = require('bot')
local narrator = require('narrator.narrator')
local lume = require('narrator.libs.lume')

--
-- Constants

local folder_separator = package.config:sub(1, 1)
local tests_folder = 'test' .. folder_separator

--- Make path for a .lua file
-- @param case string: an runtime test case
-- @return string: a .lua path
local function lua_path(case)
  return tests_folder .. case .. '.lua'
end

--- Make path for an .ink file
-- @param case string: an Ink test case
-- @return string: an .ink path
local function ink_path(case)
  return tests_folder .. case .. '.ink'
end

--- Make path for a .txt file
-- @param case string: an Ink test case
-- @param answers table: a sequence of answers (numbers)
-- @return string: a .txt path
local function txt_path(case, answers)
  local path = tests_folder .. case
  if answers and #answers > 0 then
    path = path .. folder_separator .. table.concat(answers, "-")
  end
  path = path .. '.txt'
  return path
end

--- Get all possible sequences and logs of the case
-- @param case string: an Ink test case
-- @return table: an array of possible games { sequence, log }
local function get_possible_results(case)
  local path = ink_path(case)
  local book = narrator.parse_file(path)

  local results = { }
  local sequences = { { } }
  local seq_index

  local function instructor(choices, step)
    local cur_seq = sequences[seq_index]
    local answer = cur_seq[step]

    if not answer then
      -- Transform a current sequence to branches for each available choice
      table.remove(sequences, seq_index)

      for index, _ in ipairs(choices) do
        local new_seq = lume.concat(cur_seq, { index })
        table.insert(sequences, new_seq)
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
      seq_index = index

      -- Play the sequence
      local story = narrator.init_story(book)
      local log = bot.play(story, instructor)

      -- If the sequence was finished then save the result and mark it as finished
      if log then
        local result = { sequence = sequence, log = log }
        table.insert(results, result)
        sequences[index] = { is_finished = true }
      end
    end

    -- Remove finished sequences
    for index = #sequences, 1, -1 do
      local sequence = sequences[index]
      if sequence.is_finished then
        table.remove(sequences, index)
      end
    end
  end

  return results
end

--- Create possible results for an Ink test case and save them to txt files
-- @param case string: an Ink test case
-- @param override boolean: override a txt file if it already exists.
local function create_txt_for_ink_case(case, override)
  local override = override ~= nil and override or false
  local results = get_possible_results(case)

  for _, result in ipairs(results) do
    local txt_path = txt_path(case, #results > 1 and result.sequence or nil)
    local file = io.open(txt_path, 'r')
    local is_file_exists = file ~= nil
    if is_file_exists then io.close(file) end

    if not is_file_exists or override then
      local folder_path = txt_path:match('(.*' .. folder_separator .. ')')
      local folder = io.open(folder_path, 'r')
      local is_folder_exists = folder ~= nil
      if is_folder_exists then
        io.close(folder)
      else
        os.execute('mkdir ' .. folder_path)
      end

      file = io.open(txt_path, 'w')
      assert(file, 'Has no access to the file at path  \'' .. txt_path .. '\'.')

      file:write(result.log)
      file:close()
    end
  end
end

--- Create possible results for Ink test cases and save them to txt files
-- @param cases table: an array of Ink test cases
-- @param override bool: override the txt file if it already exists
local function create_txt_for_ink_cases(cases, override)
  for _, case in ipairs(cases) do
    create_txt_for_ink_case(case, override)
  end
end

--- Test an Ink case
-- @param case string: an Ink test case
local function test_ink_case(case)
  describe('Test an Ink case \'' .. case .. '\'.', function()
    local path = ink_path(case)
    local book = narrator.parse_file(path)

    local results = get_possible_results(case)
    for _, result in ipairs(results) do
      describe('Sequence is [' .. table.concat(result.sequence, "-") .. '].', function()
        local txt_path = txt_path(case, #results > 1 and result.sequence or nil)
        local file = io.open(txt_path, 'r')

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

--- Test Ink cases
-- @param cases table: an array of test cases
local function test_ink_cases(cases)
  for _, case in ipairs(cases) do
    test_ink_case(case)
  end
end

--- Test a runtime case
-- @param case string: a runtime test case
local function test_lua_case(case)
  describe('Test a runtime case \'' .. case .. '\'.', function()
    local lua_path = lua_path(case)
    loadfile(lua_path)(narrator, describe, it, assert)
  end)
end

--- Test runtime cases
-- @param cases table: an array of runtime test cases
local function test_lua_cases(cases)
  for _, case in ipairs(cases) do
    test_lua_case(case)
  end
end

--- Override math.random functions to prevent different results beetween machines and pass test-cases.
local function override_random()
  local test_seed
  local original_random = math.random

  math.randomseed = function(x)
    test_seed = x
  end

  math.random = function(x, y)
    if test_seed then
      local result = math.max(x, math.min(test_seed, y))
      test_seed = nil
      return result
    else
      return original_random(x, y)
    end
  end
end

--
-- Main

local case = nil
local cases = require('test.cases')
local override_case_results = false

override_random()

if override_case_results then
  if case then
    create_txt_for_ink_case(case, true)
  else
    create_txt_for_ink_cases(cases.units, true)
    create_txt_for_ink_cases(cases.stories, true)
  end
end

if case then
  if case:find('runtime/', 1, 8) then
    test_lua_case(case)
  else
    test_ink_case(case)
  end
else
  test_lua_cases(cases.runtime)
  test_ink_cases(cases.units)
  test_ink_cases(cases.stories)
end