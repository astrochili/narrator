--
-- Dependencies

local lume = require('narrator.libs.lume')

--
-- Metatable

local mt = { lists = { } }

function mt.__tostring(self)
  local pool = { }

  local list_keys = { }
  for key, _ in pairs(self) do
    table.insert(list_keys, key)
  end
  table.sort(list_keys)

  for i = 1, #list_keys do
    local list_name = list_keys[i]
    local list_items = self[list_name]
    for index = 1, #mt.lists[list_name] do
      pool[index] = pool[index] or { }
      local item_name = mt.lists[list_name][index]
      if list_items[item_name] == true then
        table.insert(pool[index], 1, item_name)
      end
    end
  end

  local items = { }

  for _, titles in ipairs(pool) do
    for _, title in ipairs(titles) do
      table.insert(items, title)
    end
  end

  return table.concat(items, ', ')
end

--
-- Operators

function mt.__add(lhs, rhs) -- +
  if type(rhs) == 'table' then
    return mt.__add_list(lhs, rhs)
  elseif type(rhs) == 'number' then
    return mt.__shift_by_number(lhs, rhs)
  else
    error('Attempt to sum the list with ' .. type(rhs))
  end
end

function mt.__sub(lhs, rhs) -- -
  if type(rhs) == 'table' then
    return mt.__subList(lhs, rhs)
  elseif type(rhs) == 'number' then
    return mt.__shift_by_number(lhs, -rhs)
  else
    error('Attempt to sub the list with ' .. type(rhs))
  end
end

function mt.__mod(lhs, rhs) -- % (contain)
  if type(rhs) ~= 'table' then
    error('Attempt to check content of the list for ' .. type(rhs))
  end

  for list_name, list_items in pairs(rhs) do
    if lhs[list_name] == nil then return false end
    for item_name, item_value in pairs(list_items) do
      if (lhs[list_name][item_name] or false) ~= item_value then return false end
    end
  end

  return true
end

function mt.__pow(lhs, rhs) -- ^ (intersection)
  if type(rhs) ~= 'table' then
    error('Attempt to interselect the list with ' .. type(rhs))
  end

  local intersection = { }

  for list_name, list_items in pairs(lhs) do
    for item_name, item_value in pairs(list_items) do
      local left = lhs[list_name][item_name]
      local right = (rhs[list_name] or { })[item_name]
      if left == true and right == true then
        intersection[list_name] = intersection[list_name] or { }
        intersection[list_name][item_name] = true
      end
    end
  end

  setmetatable(intersection, mt)
  return intersection
end

function mt.__len(self) -- #
  local len = 0

  for list_name, list_items in pairs(self) do
    for item_name, item_value in pairs(list_items) do
      if item_value == true then len = len + 1 end
    end
  end

  return len
end

function mt.__eq(lhs, rhs) -- ==
  if type(rhs) ~= 'table' then
    error('Attempt to compare the list with ' .. type(rhs))
  end

  local function keys_count(object)
    local count = 0
    for _, _ in pairs(object) do
      count = count + 1
    end
    return count
  end

  local left_lists_count = keys_count(lhs)
  local right_lists_count = keys_count(rhs)
  if left_lists_count ~= right_lists_count then
    return false
  end

  for list_name, left_items in pairs(lhs) do
    local right_items = rhs[list_name]
    if right_items == nil then
      return false
    end

    local left_items_count = keys_count(left_items)
    local right_items_count = keys_count(right_items)

    if left_items_count ~= right_items_count then
      return false
    end
  end

  return mt.__mod(lhs, rhs)
end

function mt.__lt(lhs, rhs) -- <
  if type(rhs) ~= 'table' then
    error('Attempt to compare the list with ' .. type(rhs))
  end

  -- LEFT < RIGHT means "the smallest value in RIGHT is bigger than the largest values in LEFT"

  local minLeft = mt.min_value_of(lhs, true)
  local maxRight = mt.max_value_of(rhs, true)

  return minLeft < maxRight
end

function mt.__le(lhs, rhs) -- <=
  if type(rhs) ~= 'table' then
    error('Attempt to compare the list with ' .. type(rhs))
  end

  -- LEFT => RIGHT means "the smallest value in RIGHT is at least the smallest value in LEFT,
  --                  and the largest value in RIGHT is at least the largest value in LEFT".

  local minRight = mt.min_value_of(rhs, true)
  local minLeft = mt.min_value_of(lhs, true)
  local maxRight = mt.max_value_of(rhs, true)
  local maxLeft = mt.max_value_of(lhs, true)

  return minRight >= minLeft and maxRight >= maxLeft
end

--
-- Custom operators

function mt.__add_list(lhs, rhs)
  local result = lume.clone(lhs)

  for list_name, list_items in pairs(rhs) do
    result[list_name] = result[list_name] or { }
    for item_name, item_value in pairs(list_items) do
      result[list_name][item_name] = item_value
    end
  end

  return result
end

function mt.__subList(lhs, rhs)
  local result = lume.clone(lhs)

  for list_name, list_items in pairs(rhs) do
    if lhs[list_name] ~= nil then
      for item_name, _ in pairs(list_items) do
        lhs[list_name][item_name] = nil
      end
    end
  end

  return mt.remove_empties_in_list(result)
end

function mt.__shift_by_number(list, number)
  local result = { }

  for list_name, list_items in pairs(list) do
    result[list_name] = { }
    for index, item_name in ipairs(mt.lists[list_name]) do
      if list_items[item_name] == true then
        local nextItem = mt.lists[list_name][index + number]
        if nextItem ~= nil then
          result[list_name][nextItem] = true
        end
      end
    end
  end

  return mt.remove_empties_in_list(result)
end

--
-- Helpers

function mt.remove_empties_in_list(list)
  local result = lume.clone(list)

  for list_name, list_items in pairs(list) do
    if next(list_items) == nil then
      result[list_name] = nil
    end
  end

  return result
end

function mt.min_value_of(list, raw)
  local min_index = 0
  local min_value = { }

  local list_keys = { }
  for key, _ in pairs(list) do
    table.insert(list_keys, key)
  end
  table.sort(list_keys)

  for i = 1, #list_keys do
    local list_name = list_keys[i]
    local list_items = list[list_name]
    for item_name, item_value in pairs(list_items) do
      if item_value == true then
        local index = lume.find(mt.lists[list_name], item_name)
        if index and index < min_index or min_index == 0 then
          min_index = index
          min_value = { [list_name] = { [item_name] = true } }
        end
      end
    end
  end

  return raw and min_index or min_value
end

function mt.max_value_of(list, raw)
  local max_index = 0
  local max_value = { }

  local list_keys = { }
  for key, _ in pairs(list) do
    table.insert(list_keys, key)
  end
  table.sort(list_keys)

  for i = 1, #list_keys do
    local list_name = list_keys[i]
    local list_items = list[list_name]
    for item_name, item_value in pairs(list_items) do
      if item_value == true then
        local index = lume.find(mt.lists[list_name], item_name)
        if index and index > max_index or max_index == 0 then
          max_index = index
          max_value = { [list_name] = { [item_name] = true } }
        end
      end
    end
  end

  return raw and max_index or max_value
end

function mt.random_value_of(list)
  local items = { }

  local list_keys = { }
  for key, _ in pairs(list) do
    table.insert(list_keys, key)
  end
  table.sort(list_keys)

  for i = 1, #list_keys do
    local list_name = list_keys[i]
    local list_items = list[list_name]
    local items_keys = { }
    for key, _ in pairs(list_items) do
      table.insert(items_keys, key)
    end
    table.sort(items_keys)

    for i = 1, #items_keys do
      local item_name = items_keys[i]
      local item_value = list_items[item_name]
      if item_value == true then
        local result = { [list_name] = { [item_name] = true } }
        table.insert(items, result)
      end
    end
  end

  local random_index = math.random(1, #items)
  return items[random_index]
end

function mt.first_raw_value_of(list)
  local result = 0

  for list_name, list_items in pairs(list) do
    for item_name, item_value in pairs(list_items) do
      if item_value == true then
        local index = lume.find(mt.lists[list_name], item_name)
        if index then
          result = index
          break
        end
      end
    end
  end

  return result
end

function mt.posible_values_of(list)
  local result = { }

  for list_name, list_items in pairs(list) do
    local subList = { }
    for _, item_name in ipairs(mt.lists[list_name]) do
      subList[item_name] = true
    end
    result[list_name] = subList
  end

  return result
end

function mt.range_of(list, min, max)
  if type(min) ~= 'table' and type(min) ~= 'number' then
    error('Attempt to get a range with incorrect min value of type ' .. type(min))
  end
  if type(max) ~= 'table' and type(max) ~= 'number' then
    error('Attempt to get a range with incorrect max value of type ' .. type(max))
  end

  local result = { }
  local allList = mt.posible_values_of(list)
  local min_index = type(min) == 'number' and min or mt.first_raw_value_of(min)
  local max_index = type(max) == 'number' and max or mt.first_raw_value_of(max)

  for list_name, list_items in pairs(allList) do
    for item_name, item_value in pairs(list_items) do
      local index = lume.find(mt.lists[list_name], item_name)
      if index and index >= min_index and index <= max_index and list[list_name][item_name] == true then
        result[list_name] = result[list_name] or { }
        result[list_name][item_name] = true
      end
    end
  end

  return result
end

function mt.invert(list)
  local result = mt.posible_values_of(list)

  for list_name, list_items in pairs(list) do
    for item_name, item_value in pairs(list_items) do
      if item_value == true then
        result[list_name][item_name] = nil
      end
    end
  end

  return result
end

return mt