--
-- Dependencies

local classic = require('narrator.libs.classic')
local lume = require('narrator.libs.lume')
local enums = require('narrator.enums')
local list_mt = require('narrator.list.mt')

--
-- Story

---@class Narrator.Story
---@field global_tags string[]
---@field constants table<string, any>
---@field variables table<string, any>
---@field migrate fun(state: Narrator.State, old_version: number, new_version: number):Narrator.State
---@field private tree any
---@field private lists any
---@field private params any
---@field private list_mt any
---@field private version any
---@field private functions any
---@field private observers any
---@field private temp any
---@field private seeds any
---@field private choices any
---@field private paragraphs any
---@field private output any
---@field private visits any
---@field private current_path any
---@field private is_over any
---@field private tunnels any
---@field private stack any
---@field private debug_seed any
---@field private return_value any
local story = classic:extend()

--
-- Initialization

---@private
---@param book Narrator.Book
function story:new(book)
  self.tree = book.tree
  self.constants = book.constants
  self.variables = lume.clone(book.variables)
  self.lists = book.lists
  self.params = book.params

  self.list_mt = list_mt
  self.list_mt.lists = self.lists

  self.version = book.constants.version or 0

  ---@param state Narrator.State
  ---@param old_version number
  ---@param new_version number
  ---@return Narrator.State
  self.migrate = function(state, old_version, new_version) return state end

  self.functions = self:ink_functions()
  self.observers = { }
  self.global_tags = self:get_tags()

  self.temp = { }
  self.seeds = { }
  self.choices = { }
  self.paragraphs = { }
  self.output = { }
  self.visits = { }
  self.current_path = nil
  self.is_over = false

  self.tunnels = { }
  self.stack = { }
end

--
-- Public

---Start a story
---Generate the first chunk of paragraphs and choices
function story:begin()
  if #self.paragraphs > 0 or #self.choices > 0 then
    return
  end

  self:jump_path('_')
end

---Does the story have paragraphs to output or not
---@return boolean can_continue
function story:can_continue()
  return #self.paragraphs > 0
end

---Pull the current paragraphs from the queue.
---@param steps number|nil Count of paragraphs to pull
---@return Narrator.Paragraph[]
function story:continue(steps)
  local lines = { }

  if not self:can_continue() then
    return lines
  end

  local steps = steps or 0
  local single_mode = steps == 1

  steps = steps > 0 and steps or #self.paragraphs
  steps = steps > #self.paragraphs and #self.paragraphs or steps

  for index = 1, steps do
    local paragraph = self.paragraphs[index]
    paragraph.text = paragraph.text:gsub('^%s*(.-)%s*$', '%1')

    table.insert(lines, paragraph)
    table.insert(self.output, paragraph)
  end

  for _ = 1, steps do
    table.remove(self.paragraphs, 1)
  end

  return single_mode and lines[1] or lines
end

---Does the story have choices to output or not.
---Also returns false if there are available paragraphs to continue.
---@return boolean can_choose
function story:can_choose()
  return self.choices ~= nil and #self.choices > 0 and not self:can_continue()
end

---Returns an array of available choice titles.
---Also returns an empty array if there are available paragraphs to continue.
---@return Narrator.Choice[]
function story:get_choices()
  local choices = { }

  if self:can_continue() then
    return choices
  end

  for _, choice in ipairs(self.choices) do
    local model = {
      text = choice.title,
      tags = choice.tags
    }

    table.insert(choices, model)
  end

  return choices
end

---Make a choice to continue the story.
---@param index number an index of the choice
function story:choose(index)
  if self:can_continue() then
    return
  end

  if #self.tunnels > 0 then
    self.tunnels[#self.tunnels].restore = true
    -- we are moving to another context, so the last one should be restored on exit from tunnel
  end

  local choice_is_available = index > 0 and index <= #self.choices
  assert(choice_is_available, 'Choice index ' .. index .. ' out of bounds 1-' .. #self.choices)

  local choice = self.choices[index]
  assert(choice, 'Choice index ' .. index .. ' out of bounds 1-' .. #self.choices)

  self.paragraphs = { }
  self.choices = { }

  if choice.text and #choice.text > 0 then
    local paragraph = {
      text = choice.text,
      tags = choice.tags
    }
    table.insert(self.paragraphs, paragraph)
  end

  self:visit(choice.path)

  if choice.divert ~= nil then
    if choice.divert.tunnel then
      local context = { path = choice.path, restore = true, previous = self.current_path }
      table.insert(self.tunnels, context)
    end
    self:jump_path(choice.divert.path)
  else
    self:read_path(choice.path)
  end
end

---Jump to the path
---@param path_string string a path string like 'knot.stitch.label'
function story:jump_to(path_string)
  self:jump_path(path_string)
end

---Get the number of visits for the path.
---@param path_string string a path string like 'knot.stitch.label'
---@return integer
function story:get_visits(path_string)
  return self:get_visits_with_context(path_string)
end

---Get tags for the path
---@param path_string string|nil a path string with knot or stitch
---@return string[]
function story:get_tags(path_string)
  local path = self:path_from_string(path_string)
  local items = self:items_for(path.knot, path.stitch)
  local tags = { }

  for _, item in ipairs(items) do
    if type(item) == 'table' and lume.count(item) > 1 or item.tags == nil then
      break
    end

    local item_tags = type(item.tags) == 'string' and { item.tags } or item.tags
    tags = lume.concat(tags, item_tags)
  end

  return tags
end

---Creates a table with the story state that can be saved and loaded later.
---Use it to save the game.
---@return Narrator.State
function story:save_state()
  local state = {
    version = self.version,
    temp = self.temp,
    seeds = self.seeds,
    variables = self.variables,
    params = self.params,
    visits = self.visits,
    path = self.current_path,
    paragraphs = self.paragraphs,
    choices = self.choices,
    output = self.output,
    tunnels = self.tunnels
  }

  return state
end

---Restore the story state from the saved state.
---Use it to load the game.
---@param state Narrator.State
function story:load_state(state)
  if self.version ~= state.version then
    state = self.migrate(state, state.version, self.version)
  end

  self.temp = state.temp
  self.seeds = state.seeds
  self.variables = state.variables
  self.params = state.params or { }
  self.visits = state.visits
  self.current_path = state.path
  self.paragraphs = state.paragraphs
  self.choices = state.choices
  self.output = state.output
  self.tunnels = state.tunnels or { }
end

---Assign an observer function to the variable's changes.
---@param variable string
---@param observer fun(variable)
function story:observe(variable, observer)
  self.observers[variable] = observer
end

---Bind a function to external calling from the Ink.
---The function can returns the value or not.
---@param func_name string
---@param handler fun(...):any
function story:bind(func_name, handler)
  self.functions[func_name] = handler
end

--
-- Private

---@private
function story:path_chain_for_label(path)
  local label = path.label
  local items = self:items_for(path.knot, path.stitch)

  -- TODO: Find a more smart solution to divert to labels
  -- TODO: This works but... isn't good.

  local function find_label_chain_in_items(items)
    if type(items) ~= 'table' then
      return nil
    end

    for index, item in ipairs(items) do

      if item.label == label then
        return { index }

      elseif item.node ~= nil then
        local result = find_label_chain_in_items(item.node)

        if result ~= nil then
          table.insert(result, 1, index)
          return result
        end

      elseif item.success ~= nil then
        if type(item.success) == 'table' then
          local is_switch = item.success[1] ~= nil and item.success[1][1] ~= nil
          local cases = is_switch and item.success or { item.success }

          for case_index, case in ipairs(cases) do
            local result = find_label_chain_in_items(case)

            if result ~= nil then
              table.insert(result, 1, 't' .. case_index)
              table.insert(result, 1, index)
              return result
            end
          end
        end

        if type(item.failure) == 'table' then
          local result = find_label_chain_in_items(item.failure)

          if result ~= nil then
            table.insert(result, 1, 'f')
            table.insert(result, 1, index)
            return result
          end
        end
      end
    end

    return nil
  end

  local chain = find_label_chain_in_items(items)
  assert(chain, 'Label \'' ..path.label .. '\' not found')
  return chain
end

---@private
function story:jump_path(path_string, params)
  assert(path_string, 'The path_string can\'t be nil')

  self.choices = { }

  if path_string == 'END' or path_string == 'DONE' then
    self.is_over = true
    return
  end

  local path = self:path_from_string(path_string, self.current_path)

  if path.label ~= nil then
    path.chain = self:path_chain_for_label(path)
  end

  return self:read_path(path, params)
end

---@private
function story:read_path(path, params)
  assert(path, 'The reading path can\'t be nil')

  if self.is_over then
    return
  end

  -- Visit only the paths without labels.
  -- Items with labels will increment visits counter by themself in read_items().
  if not path.label then
    self:visit(path)
  end

  if params then
    for name, value in pairs(params) do
      self:assign_value_to(name, value, true)
    end
  end

  local items = self:items_for(path.knot, path.stitch)
  return self:read_items(items, path)
end

---@private
function story:items_for(knot, stitch)
  local root_node = self.tree
  local knot_node = knot == nil and root_node._ or root_node[knot]
  assert(knot_node or lume.isarray(root_node), 'The knot \'' .. (knot or '_') .. '\' not found')

  local stitch_node = stitch == nil and knot_node._ or knot_node[stitch]
  assert(stitch_node or lume.isarray(knot_node), 'The stitch \'' .. (knot or '_') .. '.' .. (stitch or '_') .. '\' not found')

  return stitch_node or knot_node or root_node
end

---@private
function story:read_items(items, path, depth, mode, current_index)
  assert(items, 'Items can\'t be nil')
  assert(path, 'Path can\'t be nil')

  local chain = path.chain or { }
  local depth = depth or 0
  local deep_index = chain[depth + 1]
  local mode = mode or enums.read_mode.text

  -- Deep path factory

  local make_deep_path = function(values, label_prefix)
    local deep_chain = lume.slice(chain, 1, depth)

    for values_index, value in ipairs(values) do
      deep_chain[depth + values_index] = value
    end

    local deep_path = lume.clone(path)
    deep_path.chain = deep_chain

    if label_prefix then
      deep_path.label = label_prefix .. table.concat(deep_chain, '.')
    end

    return deep_path
  end

  -- Iterate items

  for index = current_index or (deep_index or 1), #items do
    local context = {
      items = items,
      path = path,
      depth = depth,
      mode = mode,
      index = index + 1,
      previous = self.current_path
    }

    local item = items[index]
    local skip = false

    if item.return_value then
      self.return_value = tostring(item.return_value)
      return enums.read_mode.quit
    end

    local item_type = enums.item.text

    if type(item) == 'table' then
      if item.choice ~= nil then
        item_type = enums.item.choice
      elseif item.success ~= nil then
        item_type = enums.item.condition
      elseif item.var ~= nil then
        item_type = enums.item.variable
      elseif item.alts ~= nil then
        item_type = enums.item.alts
      end
    end

    -- Go deep
    if index == deep_index then
      if item_type == enums.item.choice and item.node ~= nil then
        -- Go deep to the choice node
        mode = enums.read_mode.gathers
        mode = self:read_items(item.node, path, depth + 1) or mode

      elseif item_type == enums.item.condition then
        -- Go deep to the condition node
        local chain_value = chain[depth + 2]
        local is_success = chain_value:sub(1, 1) == 't'
        local node

        if is_success then
          local success_index = tonumber(chain_value:sub(2, 2)) or 0
          node = success_index > 0 and item.success[success_index] or item.success
        else
          node = item.failure
        end

        mode = self:read_items(node, path, depth + 2, mode) or mode
      end

      if item_type == enums.item.condition or item_type == enums.item.choice then
        mode = mode ~= enums.read_mode.quit and enums.read_mode.gathers or mode
        skip = true
      end
    end

    -- Check the situation
    if mode == enums.read_mode.choices and item_type ~= enums.item.choice then
      mode = enums.read_mode.quit
      skip = true
    elseif mode == enums.read_mode.gathers and item_type == enums.item.choice then
      skip = true
    end

    -- Read the item
    if skip then
      -- skip
    elseif item_type == enums.item.text then
      mode = enums.read_mode.text
      local safe_item = type(item) == 'string' and { text = item } or item
      mode = self:read_text(safe_item, context) or mode
    elseif item_type == enums.item.alts then
      mode = enums.read_mode.text
      local deep_path = make_deep_path({ index }, '~')
      mode = self:read_alts(item, deep_path, depth + 1, mode) or mode
    elseif item_type == enums.item.choice and self:check_condition(item.condition) then
      mode = enums.read_mode.choices
      local deep_path = make_deep_path({ index }, '>')
      deep_path.label = item.label or deep_path.label
      mode = self:read_choice(item, deep_path) or mode

      if index == #items and type(chain[#chain]) == 'number' then
        mode = enums.read_mode.quit
      end
    elseif item_type == enums.item.condition then
      local result, chain_value

      if type(item.condition) == 'string' then
        local success = self:check_condition(item.condition)
        result = success and item.success or (item.failure or { })
        chain_value = success and 't' or 'f'
      elseif type(item.condition) == 'table' then
        local success = self:check_switch(item.condition)
        result = success > 0 and item.success[success] or (item.failure or { })
        chain_value = success > 0 and ('t' .. success) or 'f'
      end

      if type(result) == 'string' then
        mode = enums.read_mode.text
        mode = self:read_text({ text = result }, context) or mode
      elseif type(result) == 'table' then
        local deep_path = make_deep_path({ index, chain_value })
        mode = self:read_items(result, deep_path, depth + 2, mode) or mode
      end
    elseif item_type == enums.item.variable then
      self:assign_value_to(item.var, item.value, item.temp)
    end

    -- Read the label
    if item.label ~= nil and item_type ~= enums.item.choice and not skip then
      local label_path = lume.clone(path)
      label_path.label = item.label
      self:visit(label_path)
    end

    if mode == enums.read_mode.quit then
      break
    end
  end

  if depth == 0 then
    for index = #self.paragraphs, 1, -1 do
      local paragraph = self.paragraphs[index]
      if (not paragraph.text or #paragraph.text == 0) and (not paragraph.tags or #paragraph.tags == 0) then
        -- Remove safe prefixes and suffixes of failured inline conditions
        table.remove(self.paragraphs, index)
      else
        -- Remove <> tail from unexpectedly broken paragraphs
        paragraph.text = paragraph.text:match('(.-)%s*<>$') or paragraph.text
      end
    end
  end

  return mode
end

---@private
function story:read_text(item, context)
  local text = item.text
  local tags = type(item.tags) == 'string' and { item.tags } or item.tags
  local paragraphs = #self.stack == 0 and self.paragraphs or self.stack[#self.stack]

  if text ~= nil or tags ~= nil then
    local paragraph = { text = text or '<>', tags = tags }
    local stack

    paragraph.text, stack = self:replace_expressions(paragraph.text)
    paragraph.text = paragraph.text:gsub('%s+', ' ')

    table.insert(stack, paragraph)

    for _, paragraph in ipairs(stack) do

      local glued_by_prev = #paragraphs > 0 and paragraphs[#paragraphs].text:sub(-2) == '<>'
      local glued_by_this = text ~= nil and text:sub(1, 2) == '<>'

      if glued_by_prev then
        local prev_paragraph = paragraphs[#paragraphs]
        prev_paragraph.text = prev_paragraph.text:sub(1, #prev_paragraph.text - 2)
        paragraphs[#paragraphs] = prev_paragraph
      end

      if glued_by_this then
        paragraph.text = paragraph.text:sub(3)
      end

      if glued_by_prev or (glued_by_this and #paragraphs > 0) then
        local prev_paragraph = paragraphs[#paragraphs]
        prev_paragraph.text = (prev_paragraph.text .. paragraph.text):gsub('%s+', ' ')
        prev_paragraph.tags = lume.concat(prev_paragraph.tags, paragraph.tags)
        prev_paragraph.tags = #prev_paragraph.tags > 0 and prev_paragraph.tags or nil
        paragraphs[#paragraphs] = prev_paragraph
      else
        table.insert(paragraphs, #paragraphs + 1, paragraph)
      end
    end
  end

  if item.divert ~= nil then
    if item.divert.tunnel then
      table.insert(self.tunnels, context)
    end

    local mode = self:jump_path(item.divert.path)

    if item.divert.tunnel then
      return (mode == enums.read_mode.quit and #self.choices == 0) and enums.read_mode.text or mode
    end

    return enums.read_mode.quit
  end

  if item.exit then
    local context = assert(table.remove(self.tunnels), 'Tunnel stack is empty')
    self.current_path = context.previous
    if context.restore then

      if context.items == nil then
        self:read_path(context.path)
        return enums.read_mode.quit
      end

      self:read_items(context.items, context.path, context.depth, context.mode, context.index)
      return enums.read_mode.quit
    end

    return enums.read_mode.text
  end
end

---@private
function story:read_alts(item, path, depth, mode)
  assert(item.alts, 'Alternatives can\'t be nil')
  local alts = lume.clone(item.alts)

  local sequence = item.sequence or enums.sequence.stopping
  if type(sequence) == 'string' then
    sequence = enums.sequence[item.sequence]
  end

  self:visit(path)
  local visits = self:get_visits_for_path(path)
  local index = 0

  if item.shuffle then
    local seed_key = (path.knot or '_') .. '.' .. (path.stitch or '_') .. ':' .. path.label
    local seed = visits % #alts == 1 and (self.debug_seed or os.time() * 1000) or self.seeds[seed_key]
    self.seeds[seed_key] = seed

    for index, alt in ipairs(alts) do
      math.randomseed(seed + index)

      local pair_index = index < #alts and math.random(index, #alts) or index
      alts[index] = alts[pair_index]
      alts[pair_index] = alt
    end
  end

  if sequence == enums.sequence.cycle then
    index = visits % #alts
    index = index > 0 and index or #alts
  elseif sequence == enums.sequence.stopping then
    index = visits < #alts and visits or #alts
  elseif sequence == enums.sequence.once then
    index = visits
  end

  local alt = index <= #alts and alts[index] or { }
  local items = type(alt) == 'string' and { alt } or alt

  return self:read_items(items, path, depth, mode)
end

---@private
function random_seed()

end

---@private
function story:read_choice(item, path)
  local is_fallback = item.choice == 0

  if is_fallback then
    -- Works correctly only when a fallback is the last choice
    if #self.choices == 0 then
      if item.divert ~= nil then
        self:jump_path(item.divert.path)
      else
        self:read_path(path)
      end
    end

    return enums.read_mode.quit
  end

  local title = self:replace_expressions(item.choice)
  title = title:match('(.-)%s*<>$') or title

  local choice = {
    title = title,
    text = item.text ~= nil and self:replace_expressions(item.text) or title,
    divert = item.divert,
    tags = item.tags,
    path = path
  }

  if item.sticky or self:get_visits_for_path(path) == 0 then
    table.insert(self.choices, #self.choices + 1, choice)
  end
end

-- Expressions

---@private
function story:replace_expressions(text)
  local stack = { }

  local replaced = text:gsub('%b##', function(match)
    if #match == 2 then
      return '#'
    else
      local result
      result, stack = self:do_expression(match:sub(2, #match - 1))

      if type(result) == 'table' then
        result = self.list_mt.__tostring(result)
      elseif type(result) == 'boolean' then
        result = result and 1 or 0
      elseif type(result) == 'number' then
        result = tostring(result)

        if result:sub(-2) == '.0' then
          result = result:sub(1, -3)
        end
      elseif result == nil then
        result = ''
      end

      return result
    end
  end)

  return replaced, stack
end

---@private
function story:check_switch(conditions)
  for index, condition in ipairs(conditions) do
    if self:check_condition(condition) then
      return index
    end
  end

  return 0
end

---@private
function story:check_condition(condition)
  if condition == nil then
    return true
  end

  local result, stack = self:do_expression(condition)

  for _, paragraph in ipairs(stack) do
    table.insert(self.paragraphs, paragraph)
  end

  if type(result) == 'table' and not next(result) then
    result = nil
  end

  return result ~= nil and result ~= false
end

---@private
function story:do_expression(expression)
  assert(type(expression) == 'string', 'Expression must be a string')

  local code = ''
  local lists = { }
  local stack = { }

  -- Replace operators
  expression = expression:gsub('!=', '~=')
  expression = expression:gsub('%s*||%s*', ' or ')
  expression = expression:gsub('%s*%&%&%s*', ' and ')
  expression = expression:gsub('%s+has%s+', ' ? ')
  expression = expression:gsub('%s+hasnt%s+', ' !? ')
  expression = expression:gsub('!%s*%w', ' not ')

  -- Replace functions results
  expression = expression:gsub('[%a_][%w_]*%b()', function(match)
    local func_name = match:match('([%a_][%w_]*)%(')
    local params_string = match:match('[%a_][%w_]*%((.+)%)')
    local params = params_string ~= nil and lume.map(lume.split(params_string, ','), lume.trim) or nil

    for index, param in ipairs(params or { }) do
      params[index] = self:do_expression(param)
    end

    local func = self.functions[func_name]

    if func ~= nil then
      local value = func((table.unpack or unpack)(params or { }))

      if type(value) == 'table' then
        lists[#lists + 1] = value
        return '__list' .. #lists
      else
        return lume.serialize(value)
      end
    elseif self.lists[func_name] ~= nil then
      local index = params and params[1] or 0
      local item = self.lists[func_name][index]
      local list = item and { [func_name] = { [item] = true } } or { }

      lists[#lists + 1] = list

      return '__list' .. #lists
    else
      self.return_value = nil

      local func_params = { }
      local path = self.current_path

      if params then
        for i, value in ipairs(params) do
          func_params[self.params[func_name][i]] = tostring(value)
        end
      end

      table.insert(self.stack, { })
      self:jump_path(func_name, func_params)
      self.current_path = path

      for _, paragraph in ipairs(table.remove(self.stack)) do
        table.insert(stack, paragraph)
      end

      return self.return_value
    end
  end)

  -- Replace lists
  expression = expression:gsub('%(([%s%w%.,_]*)%)', function(match)
    local list = self:make_list_for(match)

    if list ~= nil then
      lists[#lists + 1] = list
      return '__list' .. #lists
    else
      return 'nil'
    end
  end)

  -- Store strings to the bag before to replace variables
  -- otherwise it can replace strings inside quotes to nils.
  -- Info: Ink doesn't interpret single quotes '' as string expression value
  local strings_bag = { }
  expression = expression:gsub('%b\"\"', function(match)
    table.insert(strings_bag, match)
    return '#' .. #strings_bag .. '#'
  end)

  -- Replace variables
  expression = expression:gsub('[%a_][%w_%.]*', function(match)
    local exceptions = { 'and', 'or', 'true', 'false', 'nil', 'not'}

    if lume.find(exceptions, match) or match:match('__list%d*') then
      return match
    else
      local value = self:get_value_for(match)

      if type(value) == 'table' then
        lists[#lists + 1] = value
        return '__list' .. #lists
      else
        return lume.serialize(value)
      end
    end
  end)

  -- Replace with math results
  expression = expression:gsub('[%a_#][%w_%.#]*[%s]*[%?!]+[%s]*[%a_#][%w_%.#]*', function(match)
    local lhs, operator, rhs = match:match('([%a_#][%w_%.#]*)[%s]*([%!?]+)[%s]*([%a_#][%w_%.#]*)')

    if lhs:match('__list%d*') then
      return lhs .. ' % ' .. rhs .. (operator == '?' and ' == true' or ' == false')
    else
      return 'string.match(' .. lhs .. ', ' .. rhs .. ')' .. (operator == '?' and ' ~= nil' or ' == nil')
    end
  end)

  -- Restore strings after variables replacement
  expression = expression:gsub('%b##', function(match)
    local index = tonumber(match:sub(2, -2))
    return strings_bag[index or 0]
  end)

  -- Attach the metatable to list tables
  if #lists > 0 then
    code = code .. 'local mt = require(\'narrator.list.mt\')\n'
    code = code .. 'mt.lists = ' .. lume.serialize(self.lists) .. '\n\n'

    for index, list in pairs(lists) do
      local name = '__list' .. index

      code = code .. 'local ' .. name .. ' = ' .. lume.serialize(list) .. '\n'
      code = code .. 'setmetatable(' .. name .. ', mt)\n\n'
    end
  end

  code = code .. 'return ' .. expression
  return lume.dostring(code), stack
end


-- Variables

---@private
function story:assign_value_to(variable, expression, temp)
  if self.constants[variable] ~= nil then
    return
  end
  local value = self:do_expression(expression)

  if #variable == 0 then
    return
  end
  local storage = (temp or self.temp[variable] ~= nil) and self.temp or self.variables

  if storage[variable] == value then
    return
  end
  storage[variable] = value

  local observer = self.observers[variable]
  if observer ~= nil then
    observer(value)
  end
end

---@private
function story:get_value_for(variable)
  local result = self.temp[variable]

  if result == nil then
    result = self.variables[variable]
  end
  if result == nil then
    result = self.constants[variable]
  end
  if result == nil then
    result = self:make_list_for(variable)
  end
  if result == nil then
    local visits = self:get_visits_with_context(variable, self.current_path)
    result = visits > 0 and visits or nil
  end

  return result
end


-- Lists

---@private
function story:make_list_for(expression)
  local result = { }
  if not expression:find('%S') then
    return result
  end

  local items = lume.array(expression:gmatch('[%w_%.]+'))

  for _, item in ipairs(items) do
    local list_name, item_name = self:get_list_name_for(item)
    if list_name ~= nil and item_name ~= nil then
      result[list_name] = result[list_name] or { }
      result[list_name][item_name] = true
    end
  end

  return next(result) ~= nil and result or nil
end

---@private
function story:get_list_name_for(name)
  local list_name, item_name = name:match('([%w_]+)%.([%w_]+)')
  item_name = item_name or name

  if list_name == nil then
    for key, list in pairs(self.lists) do
      for _, string in ipairs(list) do
        if string == item_name then
          list_name = key
          break
        end
      end
    end
  end

  local not_found = list_name == nil or self.lists[list_name] == nil

  if not_found then
    return nil
  end

  return list_name, item_name
end


-- Visits

---@private
function story:visit(path)
  local path_is_changed = self.current_path == nil or path.knot ~= self.current_path.knot or path.stitch ~= self.current_path.stitch

  if path_is_changed then
    if self.current_path == nil or path.knot ~= self.current_path.knot then
      local knot = path.knot or '_'
      local visits = self.visits[knot] or { _root = 0 }

      visits._root = visits._root + 1
      self.visits[knot] = visits
    end

    local knot, stitch = path.knot or '_', path.stitch or '_'
    local visits = self.visits[knot][stitch] or { _root = 0 }

    visits._root = visits._root + 1
    self.visits[knot][stitch] = visits
  end

  if path.label ~= nil then
    local knot, stitch, label = path.knot or '_', path.stitch or '_', path.label
    self.visits[knot] = self.visits[knot] or { _root = 1, _ = { _root = 1 } }
    self.visits[knot][stitch] = self.visits[knot][stitch] or { _root = 1 }

    local visits = self.visits[knot][stitch][label] or 0
    visits = visits + 1
    self.visits[knot][stitch][path.label] = visits
  end

  self.current_path = lume.clone(path)
  self.current_path.label = nil
  self.temp = path_is_changed and { } or self.temp
end

---@private
function story:get_visits_for_path(path)
  if path == nil then
    return 0
  end

  local knot, stitch, label = path.knot or '_', path.stitch, path.label

  if stitch == nil and label ~= nil then
    stitch = '_'
  end

  local knot_visits = self.visits[knot]

  if knot_visits == nil then
    return 0
  elseif stitch == nil then
    return knot_visits._root or 0
  end

  local stitch_visits = knot_visits[stitch]

  if stitch_visits == nil then
    return 0
  elseif label == nil then
    return stitch_visits._root or 0
  end

  local label_visits = stitch_visits[label]
  return label_visits or 0
end

---@private
function story:get_visits_with_context(path_string, context)
  local path = self:path_from_string(path_string, context)
  local visits_count = self:get_visits_for_path(path)
  return visits_count
end

---@private
function story:path_from_string(path_string, context)
  local path_string = path_string or ''
  local context_knot = context and context.knot
  local context_stitch = context and context.stitch

  context_knot = context_knot or '_'
  context_stitch = context_stitch or '_'

  -- Try to parse 'part1.part2.part3'
  local part1, part2, part3 = path_string:match('([%w_]+)%.([%w_]+)%.([%w_]+)')

  if not part1 then
    -- Try to parse 'part1.part2'
    part1, part2 = path_string:match('([%w_]+)%.([%w_]+)')
  end

  if not part1 then
    -- Try to parse 'part1'
    part1 = #path_string > 0 and path_string or nil
  end

  local path = { }

  if not part1 then
    -- Path is empty
    return path
  end

  if part3 then
    -- Path is 'part1.part2.part3'
    path.knot = part1
    path.stitch = part2
    path.label = part3

    return path
  end

  if part2 then
    -- Path is 'part1.part2'

    if self.tree[part1] and self.tree[part1][part2] then
      -- Knot 'part1' and stitch 'part2' exist so return part1.part2
      path.knot = part1
      path.stitch = part2

      return path
    end

    if self.tree[context_knot][part1] then
      -- Stitch 'part1' exists so return context_knot.part1.part2
      path.knot = context_knot
      path.stitch = part1
      path.label = part2

      return path
    end

    if self.tree[part1] then
      -- Knot 'part1' exists so seems it's a label with a root stitch
      path.knot = part1
      path.stitch = '_'
      path.label = part2

      return path
    end

    if self.tree._[part1] then
      -- Root stitch 'part1' exists so return _.part1.part2
      path.knot = '_'
      path.stitch = part1
      path.label = part2

      return path
    end
  end

  if part1 then
    -- Path is 'part1'
    if self.tree[context_knot][part1] then
      -- Stitch 'part1' exists so return context_knot.part1
      path.knot = context_knot
      path.stitch = part1

      return path
    elseif self.tree[part1] then
      -- Knot 'part1' exists so return part1
      path.knot = part1

      return path
    else
      -- Seems it's a label
      path.knot = context_knot
      path.stitch = context_stitch
      path.label = part1
    end
  end

  return path
end


-- Ink functions

---@private
function story:ink_functions()
  return {
    CHOICE_COUNT = function() return #self.choices end,
    SEED_RANDOM = function(seed) self.debug_seed = seed end,
    POW = function(x, y) return math.pow and math.pow(x, y) or x ^ y end,

    RANDOM = function(x, y)
      math.randomseed(self.debug_seed or os.time() * 1000)
      return math.random(x, y)
    end,

    INT = function(x) return math.floor(x) end,
    FLOOR = function(x) return math.floor(x) end,
    FLOAT = function(x) return x end,

    -- TURNS = function() return nil end -- TODO
    -- TURNS_SINCE = function(path) return nil end -- TODO

    LIST_VALUE = function(list) return self.list_mt.first_raw_value_of(list) end,
    LIST_COUNT = function(list) return self.list_mt.__len(list) end,
    LIST_MIN = function(list) return self.list_mt.min_value_of(list) end,
    LIST_MAX = function(list) return self.list_mt.max_value_of(list) end,

    LIST_RANDOM = function(list)
      math.randomseed(self.debug_seed or os.time() * 1000)
      return self.list_mt.random_value_of(list)
    end,

    LIST_ALL = function(list) return self.list_mt.posible_values_of(list) end,
    LIST_RANGE = function(list, min, max) return self.list_mt.range_of(list, min, max) end,
    LIST_INVERT = function(list) return self.list_mt.invert(list) end
  }
end

return story