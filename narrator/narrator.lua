--
-- Dependencies

local lume = require('narrator.libs.lume')
local enums = require('narrator.enums')
local parser = require('narrator.parser')
local Story = require('narrator.story')

--
-- Private

local folder_separator = package.config:sub(1, 1)

--- Clears path from '.lua' and '.ink' extensions and replace '.' to '/' or '\'
-- @param path string: path to clear
-- @return string: a clean path
local function clear_path(path)
  local path = path:gsub('.lua$', '')
  local path = path:gsub('.ink$', '')

  if path:match('%.') and not path:match(folder_separator) then
    path = path:gsub('%.', folder_separator)
  end

  return path
end

--- Parse an Ink file to a string content
-- @param path string: path to an Ink file
-- @return string: a content string
local function read_file(path)
  local path = clear_path(path) .. '.ink'

  local file = io.open(path, 'r')
  assert(file, 'File doesn\'t exist: ' .. path)

  local content = file:read('*all')
  file:close()

  return content
end

--- Save a book to lua module
-- @param book table: a book
-- @param path string: a path to save
-- @return boolean: success
local function save_book(book, path)
  local path = clear_path(path)  .. '.lua'

  local data = lume.serialize(book)
  data = data:gsub('%[%d+%]=', '')
  data = data:gsub('[\"[%w_]+\"]', function(match) return
    match:sub(3, #match - 2)
  end)

  local file = io.open(path, 'w')
  if file == nil then
    return false
  end

  file:write('return ' .. data)
  file:close()

  return true
end

--- Merge a chapter to a book
-- @param book table: a parent book
-- @param chapter table: a chapter to merge
-- @return table: a book
local function merge(book, chapter)
  -- Check a engine version compatibility
  if chapter.version.engine and chapter.version.engine ~= enums.engine_version then
    assert('Version ' .. chapter.version.engine .. ' of book isn\'t equal to the version ' .. enums.engine_version .. ' of Narrator.')
  end

  -- Merge the root knot and it's stitch
  book.tree._._ = lume.concat(chapter.tree._._, book.tree._._)
  chapter.tree._._ = nil
  book.tree._ = lume.merge(chapter.tree._, book.tree._)
  chapter.tree._ = nil

  -- Merge a chapter to a book
  book.tree = lume.merge(book.tree or { }, chapter.tree or { })
  book.constants = lume.merge(book.constants or { }, chapter.constants or { })
  book.lists = lume.merge(book.lists or { }, chapter.lists or { })
  book.variables = lume.merge(book.variables or { }, chapter.variables or { })
  book.params = lume.merge(book.params or { }, chapter.params or { })

  return book
end

--
-- Public

local narrator = { }

--- Parse a book from an Ink file
-- Use parsing in development, but prefer already parsed and stored books in production
-- Required: lpeg, io
-- @param path string: path to an Ink file
-- @param params table: parameters { save }
-- @param params.save boolean: save a parsed book to a lua file
-- @return a book
function narrator.parse_file(path, params)
  local params = params or { save = false }
  assert(parser, "Can't parse anything without lpeg, sorry.")

  local content = read_file(path)
  local book = parser.parse(content)

  for _, inclusion in ipairs(book.inclusions) do
    local folder_path = clear_path(path):match('(.*' .. folder_separator .. ')')
    local inclusion_path = folder_path .. clear_path(inclusion) .. '.ink'
    local chapter = narrator.parse_file(inclusion_path)
    merge(book, chapter)
  end

  if params.save then
    save_book(book, path)
  end

  return book
end

--- Parse a book from Ink content
-- Use parsing in development, but prefer already parsed and stored books in production
-- Required: lpeg
-- @param content string: root Ink content
-- @param inclusions table: an array of strings with Ink content inclusions
-- @return table: a book
function narrator.parse_book(content, inclusions)
  local inclusions = inclusions or { }
  assert(parser, "Can't parse anything without a parser.")

  local book = parser.parse(content)

  for _, inclusion in ipairs(inclusions) do
    local chapter = parser.parse(inclusion)
    merge(book, chapter)
  end

  return book
end

--- Init a story from a book
-- @param book table: a book
-- @return table: a story
function narrator.init_story(book)
  local story = Story(book)
  return story
end

return narrator