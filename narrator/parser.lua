local lume = require('narrator.libs.lume')
local enums = require('narrator.enums')

--
-- LPeg

-- To allow to build in Defold
local lpeg_name = 'lpeg'

if not pcall(require, lpeg_name) then
  return false
end

local lpeg = require(lpeg_name)

local S, C, P, V = lpeg.S, lpeg.C, lpeg.P, lpeg.V
local Cb, Ct, Cc, Cg = lpeg.Cb, lpeg.Ct, lpeg.Cc, lpeg.Cg
local Cmt = lpeg.Cmt

lpeg.locale(lpeg)

--
-- Parser

local parser = { }
local constructor = { }

---Parse ink content string
---@param content string
---@return Narrator.Book
function parser.parse(content)

  --
  -- Basic patterns

  local function get_length(array) return
    #array
  end

  local eof = -1
  local sp = S(' \t') ^ 0
  local ws = S(' \t\r\n') ^ 0
  local nl = S('\r\n') ^ 1
  local none = Cc(nil)

  local divert_sign = P'->'
  local gather_mark = sp * C('-' - divert_sign)
  local gather_level = Cg(Ct(gather_mark ^ 1) / get_length + none, 'level')

  local sticky_marks = Cg(Ct((sp * C('+')) ^ 1) / get_length, 'level') * Cg(Cc(true), 'sticky')
  local choice_marks = Cg(Ct((sp * C('*')) ^ 1) / get_length, 'level') * Cg(Cc(false), 'sticky')
  local choice_level = sticky_marks + choice_marks

  local id = (lpeg.alpha + '_') * (lpeg.alnum + '_') ^ 0
  local label = Cg('(' * sp * C(id) * sp * ')', 'label')
  local address = id * ('.' * id) ^ -2

  ---Something for tunnels
  local function check_tunnel(s, i, a)
    local r = lpeg.match (sp * divert_sign, s, i)
    return i, r ~= nil
  end

  -- TODO: Clean divert expression to divert and tunnel
  local divert = divert_sign * sp * Cg(address, 'path') -- base search for divert symbol and path to follow
  local check_tunnel = Cg(Cmt(Cb('path'), check_tunnel), 'tunnel') -- a weird way to to check tunnel
  local opt_tunnel_sign = (sp * divert_sign * sp * (#nl + #S'#') ) ^ -1 -- tunnel sign in end of string, keep newline not consumed
  divert = Cg(Ct(divert * sp * check_tunnel * opt_tunnel_sign), 'divert')

  local divert_to_nothing = divert_sign * none
  local exit_tunnel = Cg(divert_sign * divert_sign, 'exit')
  local tag = '#' * sp * V'text'
  local tags = Cg(Ct(tag * (sp * tag) ^ 0), 'tags')

  local todo = sp * 'TODO:' * (1 - nl) ^ 0
  local comment_line = sp * '//' * sp * (1 - nl) ^ 0
  local comment_multi = sp * '/*' * ((P(1) - '*/') ^ 0) * '*/'
  local comment = comment_line + comment_multi

  local multiline_end = ws * '}'

  --
  -- Dynamic patterns and evaluation helpers

  local function item_type(type)
    return Cg(Cc(type), 'type')
  end

  local function balanced_multiline_item(is_restricted)
    local is_restricted = is_restricted ~= nil and is_restricted or false
    local paragraph = is_restricted and V'restricted_paragraph' or V'paragraph'
    return sp * paragraph ^ -1 * sp * V'multiline_item' * sp * paragraph ^ -1 * ws
  end

  local function sentence_before(excluded, tailed)
    local tailed = tailed or false
    local character = P(1 - S(' \t')) - excluded
    local pattern = (sp * character ^ 1) ^ 1
    local with_tail = C(pattern * sp)
    local without_tail = C(pattern) * sp
    local without_tail_always = C(pattern) * sp * #(tags + nl)
    return without_tail_always + (tailed and with_tail or without_tail)
  end

  local function unwrap_assignment(assignment)
    local unwrapped = assignment
    unwrapped = unwrapped:gsub('([%w_]*)%s*([%+%-])[%+%-]', '%1 = %1 %2 1')
    unwrapped = unwrapped:gsub('([%w_]*)%s*([%+%-])=%s*(.*)', '%1 = %1 %2 %3')
    local name, value = unwrapped:match('([%w_]*)%s*=%s*(.*)')
    return name or '', value or assignment
  end

  local function check_special_escape(s, i, a)
    if string.sub(s, i - 2, i - 2) == '\\' then
      return
    end

    return i
  end

  --
  -- Grammar rules

  local ink_grammar = P({ 'root',

    -- Root

    root = ws * V'items' + eof,
    items = Ct(V'item' ^ 0),

    item = balanced_multiline_item() + V'singleline_item',
    singleline_item = sp * (V'global' + V'statement' + V'paragraph' + V'gatherPoint') * ws,
    multiline_item = ('{' * sp * (V'sequence' + V'switch') * sp * multiline_end) - V'inline_condition',

    -- Gather points
    gatherPoint = Ct(gather_level * sp * nl * item_type('gather')),

    -- Global declarations

    global =
      Ct(V'inclusion' * item_type('inclusion')) +
      Ct(V'list' * item_type('list')) +
      Ct(V'constant' * item_type('constant')) +
      Ct(V'variable' * item_type('variable'))
    ,

    inclusion = 'INCLUDE ' * sp * Cg(sentence_before(nl + comment), 'filename'),
    list = 'LIST ' * sp * V'assignment_pair',
    constant = 'CONST ' * sp * V'assignment_pair',
    variable = 'VAR ' * sp * V'assignment_pair',

    -- Statements

    statement =
      Ct(V'return_from_func' * item_type('return')) +
      Ct(V'assignment' * item_type('assignment')) +
      Ct(V'func' * item_type('func')) +
      Ct(V'knot' * item_type('knot')) +
      Ct(V'stitch' * item_type('stitch')) +
      Ct(V'choice' * item_type('choice')) +
      comment + todo
    ,

    section_name = C(id) * sp * P'=' ^ 0,
    knot = P'==' * (P'=' ^ 0) * sp * Cg(V'section_name', 'knot'),
    stitch = '=' * sp * Cg(V'section_name', 'stitch'),

    func_param = sp * C(id) * sp * S','^0,
    func_params = P'(' * Cg(Ct(V'func_param'^0), 'params') * P')',
    function_name = P'function' * sp * Cg(id, 'name') * sp * V'func_params' * sp * P'=' ^ 0,
    func =  P'==' * (P'=' ^ 0) * sp * Cg(Ct(V'function_name'), 'func'),

    return_from_func = sp * '~' * sp * P('return') * sp * Cg((P(1) - nl)^0, 'value') * nl ^ 0,

    assignment = gather_level * sp * '~' * sp * V'assignment_temp' * sp * V'assignment_pair',
    assignment_temp = Cg('temp' * Cc(true) + Cc(false), 'temp'),
    assignment_pair = Cg(sentence_before(nl + comment) / unwrap_assignment, 'name') * Cg(Cb('name') / 2, 'value'),

    choice_condition = Cg(V'expression' + none, 'condition'),
    choice_fallback = choice_level * sp * V'label_optional' * sp * V'choice_condition' * sp * (divert + divert_to_nothing) * sp * V'tags_optional',
    choice_normal = choice_level * sp * V'label_optional' * sp * V'choice_condition' * sp * Cg(V'text', 'text') * divert ^ -1 * sp * V'tags_optional',
    choice = V'choice_fallback' + V'choice_normal',

    -- Paragraph

    paragraph = Ct(gather_level * sp * (V'paragraph_label' + V'paragraph_text' + V'paragraph_tags') * item_type('paragraph')),
    paragraph_label = label * sp * Cg(V'text_optional', 'parts') * sp * V'tags_optional',
    paragraph_text = V'label_optional' * sp * Cg(V'text_complex', 'parts') * sp * V'tags_optional',
    paragraph_tags = V'label_optional' * sp * Cg(V'text_optional', 'parts') * sp * tags,

    label_optional = label + none,
    text_optional = V'text_complex' + none,
    tags_optional = tags + none,

    text_complex = Ct((Ct(
      Cg(V'inline_condition', 'condition') +
      Cg(V'inline_sequence', 'sequence') +
      Cg(V'expression', 'expression') +
      Cg(V'text' + ' ', 'text') * (exit_tunnel ^ -1) * (divert ^ -1) + exit_tunnel + divert
    ) - V'multiline_item') ^ 1),

    special_check_escape = Cmt(S("{|}"), check_special_escape),

    text = sentence_before(nl + exit_tunnel + divert + comment + tag + V'special_check_escape', true) - V'statement',
    -- Inline expressions, conditions, sequences

    expression = '{' * sp * sentence_before('}' + nl) * sp * '}',

    inline_condition = '{' * sp * Ct(V'inline_if_else' + V'inline_if') * sp * '}',
    inline_if = Cg(sentence_before(S':}' + nl), 'condition') * sp * ':' * sp * Cg(V'text_complex', 'success'),
    inline_if_else = (V'inline_if') * sp * '|' * sp * Cg(V'text_complex', 'failure'),

    inline_alt_empty = Ct(Ct(Cg(sp * Cc'', 'text') * sp * divert ^ -1)),
    inline_alt = V'text_complex' + V'inline_alt_empty',
    inline_alts = Ct(((sp * V'inline_alt' * sp * '|') ^ 1) * sp * V'inline_alt'),
    inline_sequence = '{' * sp * (
    '!' * sp * Ct(Cg(V'inline_alts', 'alts') * Cg(Cc('once'), 'sequence')) +
    '&' * sp * Ct(Cg(V'inline_alts', 'alts') * Cg(Cc('cycle'), 'sequence')) +
    '~' * sp * Ct(Cg(V'inline_alts', 'alts') * Cg(Cc('stopping'), 'sequence') * Cg(Cc(true),  'shuffle')) +
           Ct(Cg(V'inline_alts', 'alts') * Cg(Cc('stopping'), 'sequence'))
    ) * sp * '}',

    -- Multiline conditions and switches

    switch = Ct((V'switch_comparative' + V'switch_conditional') * item_type('switch')),

    switch_comparative = Cg(V'switch_condition', 'expression') * ws * Cg(Ct((sp * V'switch_case') ^ 1), 'cases'),
    switch_conditional = Cg(Ct(V'switch_cases_headed' + V'switch_cases_only'), 'cases'),

    switch_cases_headed = V'switch_if' * ((sp * V'switch_case') ^ 0),
    switch_cases_only = ws * ((sp * V'switch_case') ^ 1),

    switch_if = Ct(Cg(V'switch_condition', 'condition') * ws * Cg(Ct(V'switch_items'), 'node')),
    switch_case = ('-' - divert_sign) * sp * V'switch_if',
    switch_condition = sentence_before(':' + nl) * sp * ':' * sp * comment ^ -1,
    switch_items = (V'restricted_item' - V'switch_case') ^ 1,

    -- Multiline sequences

    sequence = Ct((V'sequence_params' * sp * nl * sp * V'sequence_alts') * item_type('sequence')),

    sequence_params = (
      V'sequence_shuffle_optional' * sp * V'sequence_type' +
      V'sequence_shuffle' * sp * V'sequence_type' +
      V'sequence_shuffle' * sp * V'sequence_type_optional'
    ) * sp * ':' * sp * comment ^ -1,

    sequence_shuffle_optional = V'sequence_shuffle' + Cg(Cc(false), 'shuffle'),
    sequence_shuffle = Cg(P'shuffle' / function() return true end, 'shuffle'),

    sequence_type_optional = V'sequence_type' + Cg(Cc'cycle', 'sequence'),
    sequence_type = Cg(P'cycle' + 'stopping' + 'once', 'sequence'),

    sequence_alts = Cg(Ct((sp * V'sequence_alt') ^ 1), 'alts'),
    sequence_alt = ('-' - divert_sign) * ws * Ct(V'sequence_items'),
    sequence_items = (V'restricted_item' - V'sequence_alt') ^ 1,

    -- Restricted items inside multiline items

    restricted_item = balanced_multiline_item(true) + V'restricted_singleline_item',
    restricted_singleline_item = sp * (V'global' + V'restricted_statement' + V'restricted_paragraph' - multiline_end) * ws,

    restricted_statement = Ct(
      V'choice' * item_type('choice') +
      V'assignment' * item_type('assignment')
    ) + comment + todo,

    restricted_paragraph = Ct((
      Cg(V'text_complex', 'parts') * sp * V'tags_optional' +
      Cg(V'text_optional', 'parts') * sp * tags
    ) * item_type('paragraph'))

  })

  --
  -- Result

  local parsed_items = ink_grammar:match(content)
  local book = constructor.construct_book(parsed_items)
  return book
end

--
-- A book construction

function constructor.unescape(text)
  local result = text

  result = result:gsub('\\|', '|')
  result = result:gsub('\\{', '{')
  result = result:gsub('\\}', '}')

  return result
end

function constructor.construct_book(items)

  local construction = {
    current_knot = '_',
    current_stitch = '_',
    variables_to_compute = { }
  }

  construction.book = {
    inclusions = { },
    lists = { },
    constants = { },
    variables = { },
    params = { },
    tree = { _ = { _ = { } } }
  }

  construction.book.version = {
    engine = enums.engine_version,
    tree = 1
  }

  construction.nodes_chain = {
    construction.book.tree[construction.current_knot][construction.current_stitch]
  }

  constructor.add_node(construction, items)
  constructor.clear(construction.book.tree)
  constructor.compute_variables(construction)

  return construction.book
end

function constructor:add_node(items, is_restricted)
  local is_restricted = is_restricted ~= nil and is_restricted or false

  for _, item in ipairs(items) do
    if is_restricted then
      -- Are not allowed inside multiline blocks by Ink rules:
      -- a) nesting levels
      -- b) choices without diverts

      item.level = nil
      if item.type == 'choice' and item.divert == nil then
        item.type = nil
      end
    end

    if item.type == 'inclusion' then
      -- filename
      constructor.add_inclusion(self, item.filename)
    elseif item.type == 'list' then
      -- name, value
      constructor.add_list(self, item.name, item.value)
    elseif item.type == 'constant' then
      -- name, value
      constructor.add_constant(self, item.name, item.value)
    elseif item.type == 'variable' then
      -- name, value
      constructor.add_variable(self, item.name, item.value)
    elseif item.type == 'func' then
      -- function
      constructor.add_function(self, item.func.name, item.func.params)
    elseif item.type == 'knot' then
      -- knot
      constructor.add_knot(self, item.knot)
    elseif item.type == 'stitch' then
      -- stitch
      constructor.add_stitch(self, item.stitch)
    elseif item.type == 'switch' then
      -- expression, cases
      constructor.add_switch(self, item.expression, item.cases)
    elseif item.type == 'sequence' then
      -- sequence, shuffle, alts
      constructor.add_sequence(self, item.sequence, item.shuffle, item.alts)
    elseif item.type == 'assignment' then
      -- level, name, value, temp
      constructor.add_assignment(self, item.level, item.name, item.value, item.temp)
    elseif item.type == 'return' then
      constructor.add_return(self, item.value)
    elseif item.type == 'paragraph' then
      -- level, label, parts, tags
      constructor.add_paragraph(self, item.level, item.label, item.parts, item.tags)
    elseif item.type == 'gather' then
      constructor.add_paragraph(self, item.level, "", nil, item.tags)
    elseif item.type == 'choice' then
      -- level, sticky, label, condition, text, divert, tags
      constructor.add_choice(self, item.level, item.sticky, item.label, item.condition, item.text, item.divert, item.tags)
    end
  end
end

function constructor:add_inclusion(filename)
  table.insert(self.book.inclusions, filename)
end

function constructor:add_list(name, value)
  local items = lume.array(value:gmatch('[%w_%.]+'))
  self.book.lists[name] = items

  local switched = lume.array(value:gmatch('%b()'))
  switched = lume.map(switched, function(item) return item:sub(2, #item - 1) end)
  self.book.variables[name] = { [name] = { } }
  lume.each(switched, function(item) self.book.variables[name][name][item] = true end)
end

function constructor:add_constant(constant, value)
  local value = lume.deserialize(value)
  self.book.constants[constant] = value
end

function constructor:add_variable(variable, value)
  self.variables_to_compute[variable] = value
end

function constructor:add_function(fname, params)
  local node = { }
  self.book.tree[fname] = { ['_'] = node }
  self.book.params[fname] = params
  self.nodes_chain = { node }
end

function constructor:add_knot(knot)
  self.current_knot = knot
  self.current_stitch = '_'

  local node = { }
  self.book.tree[self.current_knot] = { [self.current_stitch] = node }
  self.nodes_chain = { node }
end

function constructor:add_stitch(stitch)
  -- If a root stitch is empty we need to add a divert to the first stitch in the ink file.
  if self.current_stitch == '_' then
    local root_stitch_node = self.book.tree[self.current_knot]._
    if #root_stitch_node == 0 then
      local divertItem = { divert = { path = stitch } }
      table.insert(root_stitch_node, divertItem)
    end
  end

  self.current_stitch = stitch

  local node = { }
  self.book.tree[self.current_knot][self.current_stitch] = node
  self.nodes_chain = { node }
end

function constructor:add_switch(expression, cases)
  if expression then
    -- Convert switch cases to comparing conditions with expression
    for _, case in ipairs(cases) do
      if case.condition ~= 'else' then
        case.condition = expression .. '==' .. case.condition
      end
    end
  end

  local item = {
    condition = { },
    success = { }
  }

  for _, case in ipairs(cases) do
    if case.condition == 'else' then
      local failure_node = { }
      table.insert(self.nodes_chain, failure_node)
      constructor.add_node(self, case.node, true)
      table.remove(self.nodes_chain)
      item.failure = failure_node
    else
      local success_node = { }
      table.insert(self.nodes_chain, success_node)
      constructor.add_node(self, case.node, true)
      table.remove(self.nodes_chain)
      table.insert(item.success, success_node)
      table.insert(item.condition, case.condition)
    end
  end

  constructor.add_item(self, nil, item)
end

function constructor:add_sequence(sequence, shuffle, alts)
  local item = {
    sequence = sequence,
    shuffle = shuffle and true or nil,
    alts = { }
  }

  for _, alt in ipairs(alts) do
    local alt_node = { }
    table.insert(self.nodes_chain, alt_node)
    constructor.add_node(self, alt, true)
    table.remove(self.nodes_chain)
    table.insert(item.alts, alt_node)
  end

  constructor.add_item(self, nil, item)
end

function constructor:add_return(value)
  local item = {
    return_value = value
  }

  constructor.add_item(self, nil, item)
end

function constructor:add_assignment(level, name, value, temp)
  local item = {
    temp = temp or nil,
    var = name,
    value = value
  }

  constructor.add_item(self, level, item)
end

function constructor:add_paragraph(level, label, parts, tags)
  local items = constructor.convert_paragraph_parts_to_items(parts, true)
  items = items or { }

  -- If the paragraph has a label or tags we need to place them as the first text item.
  if label ~= nil or tags ~= nil then
    local first_item

    if #items > 0 and items[1].condition == nil then
      first_item = items[1]
    else
      first_item = {  }
      table.insert(items, first_item)
    end

    first_item.label = label
    first_item.tags = tags
  end

  for _, item in ipairs(items) do
    constructor.add_item(self, level, item)
  end
end

function constructor.convert_paragraph_parts_to_items(parts, is_root)
  if parts == nil then return nil end

  local is_root = is_root ~= nil and is_root or false
  local items = { }
  local item

  for index, part in ipairs(parts) do

    if part.condition then -- Inline condition part

      item = {
        condition = part.condition.condition,
        success = constructor.convert_paragraph_parts_to_items(part.condition.success),
        failure = constructor.convert_paragraph_parts_to_items(part.condition.failure)
      }

      table.insert(items, item)
      item = nil

    elseif part.sequence then -- Inline sequence part

      item = {
        sequence = part.sequence.sequence,
        shuffle = part.sequence.shuffle and true or nil,
        alts = { }
      }

      for _, alt in ipairs(part.sequence.alts) do
        table.insert(item.alts, constructor.convert_paragraph_parts_to_items(alt))
      end

      table.insert(items, item)
      item = nil

    else -- Text, expression and divert may be

      local is_divert_only = part.divert ~= nil and part.text == nil

      if item == nil then
        item = { text = (is_root or is_divert_only) and '' or '<>' }
      end

      if part.text then
        item.text = item.text .. part.text:gsub('%s+', ' ')
        item.text = constructor.unescape(item.text)
      elseif part.expression then
        item.text = item.text .. '#' .. part.expression .. '#'
      end

      if part.divert or part.exit then
        item.exit = part.exit and true or nil
        item.divert = part.divert
        item.text = #item.text > 0 and (item.text .. '<>') or nil
        table.insert(items, item)
        item = nil
      else
        local next = parts[index + 1]
        local next_is_block = next and not (next.text or next.expression)

        if not next or next_is_block then
          if not is_root or next_is_block then
            item.text = item.text .. '<>'
          end
          table.insert(items, item)
          item = nil
        end
      end

    end
  end

  if is_root then
    -- Add a safe prefix and suffix for correct conditions gluing

    local first_item = items[1]
    if first_item.text == nil and first_item.divert == nil and first_item.exit == nil then
      table.insert(items, 1, { text = '' } )
    end

    local last_item = items[#items]
    if last_item.text == nil and last_item.divert == nil and last_item.exit == nil then
      table.insert(items, { text = '' } )
    elseif last_item.text ~= nil and last_item.divert == nil then
      last_item.text = last_item.text:gsub('(.-)%s*$', '%1')
    end
  end

  return items
end

function constructor:add_choice(level, sticky, label, condition, sentence, divert, tags)
  local item = {
    sticky = sticky or nil,
    condition = condition,
    label = label,
    divert = divert,
    tags = tags
  }

  if sentence == nil then
    item.choice = 0
  else
    local prefix, divider, suffix = sentence:match('(.*)%[(.*)%](.*)')
    prefix = prefix or sentence
    divider = divider or ''
    suffix = suffix or ''

    local text = (prefix .. suffix):gsub('%s+', ' ')
    local choice = (prefix .. divider):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')

    if divert and #text > 0 and text:match('%S+') then
      text = text .. '<>'
    else
      text = text:gsub('^%s*(.-)%s*$', '%1')
    end

    item.text = constructor.unescape(text)
    item.choice = constructor.unescape(choice)
  end

  constructor.add_item(self, level, item)

  if divert == nil then
    item.node = { }
    table.insert(self.nodes_chain, item.node)
  end
end

function constructor:add_item(level, item)
  local level = (level ~= nil and level > 0) and level or #self.nodes_chain
  while #self.nodes_chain > level do
    table.remove(self.nodes_chain)
  end

  local node = self.nodes_chain[#self.nodes_chain]
  table.insert(node, item)
end

function constructor:compute_variable(variable, value)
  local constant = self.book.constants[value]
  if constant then
    self.book.variables[variable] = constant
    return
  end

  local list_expression = value:match('%(([%s%w%.,_]*)%)')
  local item_expressions = list_expression and lume.array(list_expression:gmatch('[%w_%.]+')) or { value }
  local list_variable = list_expression and { } or nil

  for _, item_expression in ipairs(item_expressions) do
    local list_part, item_part = item_expression:match('([%w_]+)%.([%w_]+)')
    item_part = item_part or item_expression

    for list_name, list_items in pairs(self.book.lists) do
      local list_is_valid = list_part == nil or list_part == list_name
      local item_is_found = lume.find(list_items, item_part)

      if list_is_valid and item_is_found then
        list_variable = list_variable or { }
        list_variable[list_name] = list_variable[list_name] or { }
        list_variable[list_name][item_part] = true
      end
    end
  end

  if list_variable then
    self.book.variables[variable] = list_variable
  else
    self.book.variables[variable] = lume.deserialize(value)
  end
end

function constructor:compute_variables()
  for variable, value in pairs(self.variables_to_compute) do
    constructor.compute_variable(self, variable, value)
  end
end

function constructor.clear(tree)
  for knot, node in pairs(tree) do
    for stitch, node in pairs(node) do
      constructor.clear_node(node)
    end
  end
end

function constructor.clear_node(node)
  for index, item in ipairs(node) do

    -- Simplify text only items
    if item.text ~= nil and lume.count(item) == 1 then
      node[index] = item.text
    end

    if item.node ~= nil then
      -- Clear choice nodes
      if #item.node == 0 then
        item.node = nil
      else
        constructor.clear_node(item.node)
      end

    end

    if item.success ~= nil then
      -- Simplify single condition
      if type(item.condition) == 'table' and #item.condition == 1 then
        item.condition = item.condition[1]
      end

      -- Clear success nodes
      if item.success[1] ~= nil and item.success[1][1] ~= nil then
        for index, success_node in ipairs(item.success) do
          constructor.clear_node(success_node)
          if #success_node == 1 and type(success_node[1]) == 'string' then
            item.success[index] = success_node[1]
          end
        end

        if #item.success == 1 then
          item.success = item.success[1]
        end
      else
        constructor.clear_node(item.success)
        if #item.success == 1 and type(item.success[1]) == 'string' then
          item.success = item.success[1]
        end
      end

      -- Clear failure nodes
      if item.failure ~= nil then
        constructor.clear_node(item.failure)
        if #item.failure == 1 and type(item.failure[1]) == 'string' then
          item.failure = item.failure[1]
        end
      end
    end

    if item.alts ~= nil then
      for index, alt_node in ipairs(item.alts) do
        constructor.clear_node(alt_node)
        if #alt_node == 1 and type(alt_node[1]) == 'string' then
          item.alts[index] = alt_node[1]
        end
      end
    end
  end
end

return parser