local mt = { }

function mt.__add(lhs, rhs) -- +
    local result = lhs

    if type(rhs) == "table" then
        for listName, listItems in pairs(rhs) do
            result[listName] = result[listName] or { }
            for itemName, itemValue in pairs(listItems) do
                result[listName][itemName] = itemValue
            end
        end
    elseif type(rhs) == "number" then
        -- TODO: shift true values by number
    else
        error("Attempt to sum a list with " .. type(rhs))
    end

    return result
end

function mt.__sub(lhs, rhs) -- -
    return lhs
end

function mt.__mul(lhs, rhs) -- *
    return lhs
end

function mt.__div(lhs, rhs) -- /
    return lhs
end

function mt.__mod(lhs, rhs) -- %
    return lhs
end

function mt.__pow(lhs, rhs) -- ^
    return lhs
end

function mt.__eq(lhs, rhs) -- ==
    if type(rhs) ~= "table" then
        error("Attempt to equal a list with " .. type(rhs))
    end

    for listName, listItems in pairs(lhs) do
        if rhs[listName] == nil then return false end
    end

    for listName, listItems in pairs(rhs) do
        if lhs[listName] == nil then return false end
        for itemName, itemValue in pairs(listItems) do
            if (lhs[listName][itemName] or false) ~= itemValue then return false end
        end    
    end

    return true
end

function mt.__lt(lhs, rhs) -- <
    return false
end

function mt.__le(lhs, rhs) -- <=
    return false
end

return mt