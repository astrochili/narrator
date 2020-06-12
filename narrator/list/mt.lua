--
-- Dependencies

local libPath = (...):gsub('.list.mt$', '')
local lume = require(libPath .. '.libs.lume')

--
-- Metatable

local mt = { lists = { } }

function mt.__tostring(self)
  local pool = { }

  for listName, listItems in pairs(self) do
    for index = 1, #mt.lists[listName] do
      pool[index] = pool[index] or { }
      local itemName = mt.lists[listName][index]
      if listItems[itemName] == true then
        table.insert(pool[index], 1, itemName)
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
    return mt.__addList(lhs, rhs)
  elseif type(rhs) == 'number' then
    return mt.__shiftByNumber(lhs, rhs)
  else
    error('Attempt to sum the list with ' .. type(rhs))
  end
end

function mt.__sub(lhs, rhs) -- -
  if type(rhs) == 'table' then
    return mt.__subList(lhs, rhs)
  elseif type(rhs) == 'number' then
    return mt.__shiftByNumber(lhs, -rhs)
  else
    error('Attempt to sub the list with ' .. type(rhs))
  end
end

function mt.__mod(lhs, rhs) -- % (contain)
  if type(rhs) ~= 'table' then
    error('Attempt to check content of the list for ' .. type(rhs))
  end

  for listName, listItems in pairs(rhs) do
    if lhs[listName] == nil then return false end
    for itemName, itemValue in pairs(listItems) do
      if (lhs[listName][itemName] or false) ~= itemValue then return false end
    end  
  end

  return true
end

function mt.__pow(lhs, rhs) -- ^ (intersection)
  if type(rhs) ~= 'table' then
    error('Attempt to interselect the list with ' .. type(rhs))
  end

  local intersection = { }
  
  for listName, listItems in pairs(lhs) do
    for itemName, itemValue in pairs(listItems) do
      local left = lhs[listName][itemName]
      local right = (rhs[listName] or { })[itemName]
      if left == true and right == true then
        intersection[listName] = intersection[listName] or { }
        intersection[listName][itemName] = true
      end
    end
  end

  return intersection
end

function mt.__len(self) -- #
  local len = 0

  for listName, listItems in pairs(self) do
    for itemName, itemValue in pairs(listItems) do
      if itemValue == true then len = len + 1 end
    end
  end

  return len
end

function mt.__eq(lhs, rhs) -- ==
  if type(rhs) ~= 'table' then
    error('Attempt to compare the list with ' .. type(rhs))
  end

  for listName, listItems in pairs(lhs) do
    if rhs[listName] == nil then return false end
  end

  return mt.__mod(lhs, rhs)
end

function mt.__lt(lhs, rhs) -- <
  if type(rhs) ~= 'table' then
    error('Attempt to compare the list with ' .. type(rhs))
  end

  -- LEFT < RIGHT means "the smallest value in LEFT is bigger than the largest values in RIGHT"
  
  local minLeft = mt.minValueOf(lhs, true)
  local maxRight = mt.maxValueOf(rhs, true)

  return minLeft > maxRight
end

function mt.__le(lhs, rhs) -- <=
  if type(rhs) ~= 'table' then
    error('Attempt to compare the list with ' .. type(rhs))
  end

  -- LEFT <= RIGHT means "the smallest value in RIGHT is at least the smallest value in LEFT,
  --            and the largest value in RIGHT is at least the largest value in LEFT".

  local minRight = mt.minValueOf(rhs, true)
  local minLeft = mt.minValueOf(lhs, true)
  local maxRight = mt.maxValueOf(rhs, true)
  local maxLeft = mt.maxValueOf(lhs, true)

  return minRight >= minLeft and maxRight >= maxLeft
end

--
-- Custom operators

function mt.__addList(lhs, rhs)
  local result = lume.clone(lhs)

  for listName, listItems in pairs(rhs) do
    result[listName] = result[listName] or { }
    for itemName, itemValue in pairs(listItems) do
      result[listName][itemName] = itemValue
    end
  end

  return result
end

function mt.__subList(lhs, rhs)
  local result = lume.clone(lhs)

  for listName, listItems in pairs(rhs) do
    if lhs[listName] ~= nil then
      for itemName, itemValue in pairs(listItems) do
        lhs[listName][itemValue] = nil
      end  
    end
  end

  return mt.removeEmptiesInList(result)
end

function mt.__shiftByNumber(list, number)
  local result = { }

  for listName, listItems in pairs(list) do
    result[listName] = { }
    for index, itemName in ipairs(mt.lists[listName]) do
      if listItems[itemName] == true then
        local nextItem = mt.lists[listName][index + number]
        if nextItem ~= nil then
          result[listName][nextItem] = true
        end
      end
    end
  end

  return mt.removeEmptiesInList(result)
end

--
-- Helpers

function mt.removeEmptiesInList(list)
  local result = lume.clone(list)

  for listName, listItems in pairs(list) do
    if next(listItems) == nil then
      result[listName] = nil
    end
  end

  return result
end

function mt.minValueOf(list, raw)
  local minIndex = 0
  local minValue = { }

  for listName, listItems in pairs(list) do
    for itemName, itemValue in pairs(listItems) do
      if itemValue == true then
        local index = lume.find(mt.lists[listName], itemName)
        if index and index < minIndex or minIndex == 0 then
          minIndex = index
          minValue = { [listName] = { [itemName] = true } }
        end
      end
    end
  end

  return raw and minIndex or minValue
end

function mt.maxValueOf(list, raw)
  local maxIndex = 0
  local maxValue = { }

  for listName, listItems in pairs(list) do
    for itemName, itemValue in pairs(listItems) do
      if itemValue == true then
        local index = lume.find(mt.lists[listName], itemName)
        if index and index > maxIndex or maxIndex == 0 then
          maxIndex = index
          maxValue = { [listName] = { [itemName] = true } }
        end
      end
    end
  end

  return raw and maxIndex or maxValue
end

function mt.randomValueOf(list)
  local items = { }

  for listName, listItems in pairs(list) do
    for itemName, itemValue in pairs(listItems) do
      if itemValue == true then
        local result = { [listName] = { [itemName] = true } }
        table.insert(result)
      end
    end
  end

  math.randomseed(os.time)
  local randomIndex = math.random(1, #items)
  return items[randomIndex]
end

function mt.firstRawValueOf(list)
  local result = 0
  
  for listName, listItems in pairs(list) do
    for itemName, itemValue in pairs(listItems) do
      if itemValue == true then
        local index = lume.find(mt.lists[listName], itemName)
        if index then
          result = index
          break
        end
      end
    end
  end

  return result
end

function mt.posibleValuesOf(list)
  local result = { }

  for listName, listItems in pairs(list) do
    local subList = { }
    for _, itemName in ipairs(mt.lists[listName]) do
      subList[itemName] = true
    end
    result[listName] = subList
  end

  return result
end

function mt.rangeOf(list, min, max)
  local result = mt.posibleValuesOf(list)

  for listName, listItems in pairs(list) do
    for itemName, itemValue in pairs(listItems) do
      if itemValue == true then
        local index = lume.find(mt.lists[listName], itemName)
        if index and index < min or index > max then
          result[listName][itemName] = nil
        end
      end
    end
  end

  return result
end

function mt.invert(list)
  local result = mt.posibleValuesOf(list)

  for listName, listItems in pairs(list) do
    for itemName, itemValue in pairs(listItems) do
      if itemValue == true then
        result[listName][itemName] = nil
      end
    end
  end

  return result
end

return mt