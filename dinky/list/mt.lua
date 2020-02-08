--
-- Dependencies

local lume = require("lume")

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
                table.insert(pool[index], itemName)
            end
        end
    end

    local items = { }

    for _, titles in ipairs(pool) do
        for _, title in ipairs(titles) do
            table.insert(items, title)
        end
    end

    return table.concat(items, ", ")
end

--
-- Operators

function mt.__add(lhs, rhs) -- +
    if type(rhs) == "table" then
        return mt.__addList(lhs, rhs)
    elseif type(rhs) == "number" then
        return mt.__shiftByNumber(lhs, rhs)
    else
        error("Attempt to sum the list with " .. type(rhs))
    end
end

function mt.__sub(lhs, rhs) -- -
    if type(rhs) == "table" then
        return mt.__subList(lhs, rhs)
    elseif type(rhs) == "number" then
        return mt.__shiftByNumber(lhs, -rhs)
    else
        error("Attempt to sub the list with " .. type(rhs))
    end
end

function mt.__mod(lhs, rhs) -- % (contain)
    if type(rhs) ~= "table" then
        error("Attempt to check content of the list for " .. type(rhs))
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
    if type(rhs) ~= "table" then
        error("Attempt to interselect the list with " .. type(rhs))
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
    if type(rhs) ~= "table" then
        error("Attempt to compare the list with " .. type(rhs))
    end

    for listName, listItems in pairs(lhs) do
        if rhs[listName] == nil then return false end
    end

    return mt.__mod(lhs, rhs)
end

function mt.__lt(lhs, rhs) -- <
    if type(rhs) ~= "table" then
        error("Attempt to compare the list with " .. type(rhs))
    end

    -- LEFT < RIGHT means "the smallest value in LEFT is bigger than the largest values in RIGHT"
    
    local minLeft = mt.getMinValueOf(lhs)
    local maxRight = mt.getMaxValueOf(rhs)

    return minLeft > maxRight
end

function mt.__le(lhs, rhs) -- <=
    if type(rhs) ~= "table" then
        error("Attempt to compare the list with " .. type(rhs))
    end

    -- LEFT <= RIGHT means "the smallest value in RIGHT is at least the smallest value in LEFT,
    --                      and the largest value in RIGHT is at least the largest value in LEFT".

    local minRight = mt.getMinValueOf(rhs)
    local minLeft = mt.getMinValueOf(lhs)
    local maxRight = mt.getMaxValueOf(rhs)
    local maxLeft = mt.getMaxValueOf(lhs)

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

function mt.getIndexInList(listName, itemName)
    if mt.lists[listName] == nil then return 0 end
    local index = lume.find(mt.lists[listName], itemName)
    return index or 0
end

function mt.getMinValueOf(list)
    local minValue = 0

    for listName, listItems in pairs(list) do
        for itemName, itemValue in pairs(listItems) do
            if itemValue == true then
                local index = mt.getIndexInList(listName, itemName)
                if index < minValue or minValue == 0 then
                    minValue = index
                end
            end
        end
    end

    return minValue
end

function mt.getMaxValueOf(list)
    local maxValue = 0

    for listName, listItems in pairs(list) do
        for itemName, itemValue in pairs(listItems) do
            if itemValue == true then
                local index = mt.getIndexInList(listName, itemName)
                if index > maxValue or maxValue == 0 then
                    maxValue = index
                end
            end
        end
    end

    return maxValue
end

return mt