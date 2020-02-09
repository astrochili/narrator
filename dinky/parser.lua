--
-- Dependencies

local lpeg = require("lpeg")
local lume = require("lume")

local libPath = (...):match("(.-).[^%.]+$")
local enums = require(libPath .. ".enums")

--
-- LPeg

local S, C, Ct, Cc, Cg = lpeg.S, lpeg.C, lpeg.Ct, lpeg.Cc, lpeg.Cg
local Cb, Cf, Cmt, P, V = lpeg.Cb, lpeg.Cf, lpeg.Cmt, lpeg.P, lpeg.V
lpeg.locale(lpeg)

--
-- Parser


local Parser = { }

function Parser.parse(inkContent)
    local model = {
        version = { engine = enums.engineVersion, tree = 1 },
        root = { },
        includes = { },
        constants = { },
        variables = { },
        lists = { }
    }
    
    local addInclude = function(include)
        table.insert(model.includes, include)
    end
    
    local addList = function(list, value)
        local items = lume.array(value:gmatch("[%w_%.]+"))
        model.lists[list] = items

        local switched = lume.array(value:gmatch("%b()"))
        switched = lume.map(switched, function(item) return item:sub(2, #item - 1) end)
        model.variables[list] = { [list] = { } }
        lume.each(switched, function(item) model.variables[list][list][item] = true end)
    end

    local addConstant = function(constant, value)
        model.constants[constant] = lume.deserialize(value)
    end

    local addVariable = function(variable, value)
        model.variables[variable] = lume.deserialize(value)
    end

    local addText = function(text)
        local block = { text = text }
        table.insert(model.root, block)
    end

    local sp = S(" \t")^0
    local ws = S(" \t\r\n")^0
    local nl = S("\r\n")^1
    local id = (lpeg.alpha + '_') * (lpeg.alnum + '_')^0
    local any = P(1 - nl)^1

    local include = ("INCLUDE" * sp * C(any)) / addInclude
    local list = ("LIST" * sp * C(id) * sp * "=" * sp * C(any)) / addList
    local constant = ("CONST" * sp * C(id) * sp * "=" * sp * C(any)) / addConstant
    local variable = ("VAR" * sp * C(id) * sp * "=" * sp * C(any)) / addVariable
    local initial = include + list + constant + variable

    local text = C(any) / addText
    
    local line = initial + text
    local ink = (sp * line * ws)^0
    ink:match(inkContent)

    return model
end

return Parser

-- local id = (lpeg.alpha + '_') * (lpeg.alnum + '_')^0 -- b_SDF_3ed334
-- local addr = C(id) * ('.' * C(id))^-1
-- local todo = Ct(sp * 'TODO:'/"todo" * sp * C((1-nl)^0)) * wh
-- local commOL = Ct(sp * '//'/"comment" * sp * C((1-nl)^0)) * wh
-- local commML = Ct(sp * '/*'/"comment" * wh * C((P(1)-'*/')^0)) * '*/' * wh
-- local comm = commOL + commML + todo
-- local glue = Ct(P'<>'/'glue') *wh -- FIXME do not consume spaces after glue
-- local divertSym = '->' *wh
-- local divertEnd = Ct(divertSym/'end' * 'END' * wh)
-- local divertJump = Ct(divertSym/'divert' * addr * wh)
-- local divert = divertEnd + divertJump
-- local knot = Ct(P('=')^2/'knot' * wh * C(id) * wh * P('=')^0) * wh
-- local stitch = Ct(P('=')^1/'stitch' * wh * C(id) * wh * P('=')^0) * wh
-- local optDiv = '[' * C((P(1) - ']')^0) * ']'
-- local optStar = sp * C'*'
-- local optStars = wh * Ct(optStar * optStar^0)/table.getn
-- local gatherMark = sp * C'-'
-- local gatherMarks = wh * Ct(gatherMark * gatherMark^0)/table.getn
-- local hash = P('#')
-- local tag = hash * wh * V'text'
-- local tagGlobal = Ct(Cc'tag' * Cc'global' * tag * wh)
-- local tagAbove = Ct(Cc'tag' * Cc'above' * tag * wh)
-- local tagEnd = Ct(Cc'tag' * Cc'end' * tag * sp)

-- Parser.inkPattern = P({
    -- stmt = glue + divert + knot + stitch + V'option' + optDiv + comm + V'include',
    -- text = C((1-nl-V'stmt'-hash)^1),
    -- textEmptyCapt = C((1-nl-V'stmt'-hash)^0),
    -- optAnsWithDiv    = V'textEmptyCapt' * sp * optDiv * V'text'^0 * wh,
    -- optAnsWithoutDiv = V'textEmptyCapt' * sp * Cc ''  * Cc ''     * wh, -- huh?
    -- optAns = V'optAnsWithDiv' + V'optAnsWithoutDiv',
    -- option = Ct(Cc'option' * optStars * sp * V'optAns'),
    -- gather = Ct(Cc'gather' * gatherMarks * sp * V'text'),
    -- include = Ct(P('INCLUDE')/'include' * wh * V'text' * wh),
    -- para = tagAbove^0 * Ct(Cc'para' * V'text') * tagEnd^0 * wh  +  tagGlobal,
    -- line = V'stmt' + V'gather'+ V'para'
-- })