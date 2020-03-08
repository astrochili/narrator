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

function Parser.parse(content)
    local model = {
        version = { engine = enums.engineVersion, tree = 1 },
        root = { },
        includes = { },
        constants = { },
        variables = { },
        lists = { }
    }
        
    local function addInclude(include)
        table.insert(model.includes, include)
    end
    
    local function addList(list, value)
        local items = lume.array(value:gmatch("[%w_%.]+"))
        model.lists[list] = items

        local switched = lume.array(value:gmatch("%b()"))
        switched = lume.map(switched, function(item) return item:sub(2, #item - 1) end)
        model.variables[list] = { [list] = { } }
        lume.each(switched, function(item) model.variables[list][list][item] = true end)
    end

    local function addConstant(constant, value)
        model.constants[constant] = lume.deserialize(value)
    end

    local function addVariable(variable, value)
        model.variables[variable] = lume.deserialize(value)
    end

    local function addParagraph(label, text, divert)
        local block = { text = text, label = label, divert = divert }
        table.insert(model.root, block)
    end

    local eof = -1
    local sp = S(" \t") ^ 0 + eof
    local ws = S(" \t\r\n") ^ 0 + eof
    local nl = S("\r\n") ^ 1 + eof

    local id = (lpeg.alpha + "_") * (lpeg.alnum + "_") ^ 0
    local label = "(" * C(id) * ")"
    local address = id * ('.' * id) ^ -2
    local divert = "->" * sp * C(address)

    local ink = P({
        "lines",
        statement = V("include") + V("list") + V("const") + V("var"),
        text = C((1 - nl - V("statement") - divert) ^ 1),

        include = "INCLUDE" * sp * V("text") / addInclude,
        assign = (C(id) * sp * "=" * sp * V("text")),
        list = "LIST" * sp * V("assign") / addList,
        const = "CONST" * sp * V("assign") / addConstant,
        var = "VAR" * sp * V("assign") / addVariable,

        textAndDivert = V("text") * sp * divert ^ -1,
        justDivert = Cc(nil) * divert,
        labelOrNil = label + Cc(nil),
        paragraph = (V("labelOrNil") * sp * (V("textAndDivert") + V("justDivert"))) / addParagraph,
        
        line = sp * (V("statement") + V("paragraph")) * ws,
        lines = Ct(V("line") ^ 0)
    })

    local lines = ink:match(content)
    return model
end

return Parser

-- local eof = -1
-- local sp = S" \t" ^0 + eof
-- local wh = S" \t\r\n" ^0 + eof
-- local nl = S"\r\n" ^1 + eof
-- local id = (lpeg.alpha + '_') * (lpeg.alnum + '_')^0
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

-- local ink = P({
--  "lines",
--  stmt = glue + divert + knot + stitch + V'option' + optDiv + comm + V'include',
--  text = C((1-nl-V'stmt'-hash)^1),
--  textEmptyCapt = C((1-nl-V'stmt'-hash)^0),
--  optAnsWithDiv    = V'textEmptyCapt' * sp * optDiv * V'text'^0 * wh,
--  optAnsWithoutDiv = V'textEmptyCapt' * sp * Cc ''  * Cc ''     * wh, -- huh?
--  optAns = V'optAnsWithDiv' + V'optAnsWithoutDiv',
--  option = Ct(Cc'option' * optStars * sp * V'optAns'),
--  gather = Ct(Cc'gather' * gatherMarks * sp * V'text'),
--  include = Ct(P('INCLUDE')/'include' * wh * V'text' * wh),
--  para = tagAbove^0 * Ct(Cc'para' * V'text') * tagEnd^0 * wh  +  tagGlobal,
--  line = V'stmt' + V'gather'+ V'para' ,
--  lines = Ct(V'line'^0)
-- })