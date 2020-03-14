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
        root = { _ = { _ = { } } },
        includes = { },
        constants = { },
        variables = { },
        lists = { }
    }

    local currentKnot = "_"
    local currentStitch = "_"
    local nodesChain = { model.root[currentKnot][currentStitch] }

    local function addBlock(level, block)
        local level = level > 0 and level or #nodesChain
        while #nodesChain > level do
            table.remove(nodesChain)
        end
        
        local node = nodesChain[#nodesChain]
        table.insert(node, block)
    end

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

    local function addParagraph(level, label, text, divert, tags)
        local block = {
            text = text,
            label = label,
            divert = divert,
            tags = tags
        }

        addBlock(level, block)
    end

    local function addChoice(level, sticky, text, divert)
        local block = {
            sticky = sticky or nil,
            divert = divert,
            node = { }
        }

        if text == nil then
            block.choice = 0
        else
            local part1, divider, part2 = text:match("(.*)%[(.*)%](.*)")
            block.choice = (part1 or text) .. (divider or "")
            block.text = (part1 or text) .. (part2 or "")
        end

        addBlock(level, block)
        table.insert(nodesChain, block.node)
    end

    local function addAssign(level, temp, var, value)
        local block = {
            temp = temp or nil,
            var = var,
            value = value
        }

        addBlock(level, block)
    end

    local function addKnot(knot)
        currentKnot = knot
        currentStitch = "_"

        local node = { }
        model.root[currentKnot] = { [currentStitch] = node }
        nodesChain = { node }
    end

    local function addStitch(stitch)
        currentStitch = stitch

        local node = { }
        model.root[currentKnot][currentStitch] = node
        nodesChain = { node }
    end

    local eof = -1
    local sp = S(" \t") ^ 0
    local ws = S(" \t\r\n") ^ 0
    local nl = S("\r\n") ^ 1
    local none = Cc(nil)

    local divertSign = "->"

    local gatherMark = sp * C("-" - P(divertSign))
    local gatherLevel = Ct(gatherMark ^ 0) / table.getn
    
    local stickyMarks = Ct((sp * C("+")) ^ 1) / table.getn * Cc(true)
    local choiceMarks = Ct((sp * C("*")) ^ 1) / table.getn * Cc(false)
    local choiceLevel = stickyMarks + choiceMarks

    local id = (lpeg.alpha + "_") * (lpeg.alnum + "_") ^ 0
    local label = "(" * sp * C(id) * sp * ")"
    local address = id * ("." * id) ^ -2
    local divert = divertSign * sp * C(address)
    local divertToNothing = divertSign * none
    local tag = "#" * sp * V"text"
    local tags = Ct(tag * (sp * tag) ^ 0)

    local todo = sp * "TODO:" * (1 - nl) ^ 0
    local commentLine = sp * "//" * sp * (1 - nl) ^ 0
    local commentMulti = sp * "/*" * ((P(1) - "*/") ^ 0) * "*/"
    local comment = commentLine + commentMulti
    
    local function unwrapAssign(expression)
        local unwrapped = expression
        unwrapped = unwrapped:gsub("([%w_]*)%s*([%+%-])[%+%-]", "%1 = %1 %2 1")
        unwrapped = unwrapped:gsub("([%w_]*)%s*([%+%-])=%s*(.*)", "%1 = %1 %2 %3")
        return unwrapped:match("([%w_]*)%s*=%s*(.*)")
    end

    local ink = P({
        "lines",
        statement = V"include" + V"list" + V"const" + V"var" + V"choice" + V"knot" + V"stitch" + V"assignValue" + comment + todo,
        text = sp * C((sp * (1 - S(" \t") - nl - divert - comment - tag) ^ 1) ^ 1) - V("statement"),

        include = "INCLUDE" * sp * V("text") / addInclude,
        assign = C(id) * sp * "=" * sp * V("text"),
        list = "LIST" * sp * V"assign" / addList,
        const = "CONST" * sp * V"assign" / addConstant,
        var = "VAR" * sp * V"assign" / addVariable,
        knot = "===" * sp * C(id) * sp * P("=") ^ 0 / addKnot,
        stitch = "=" * sp * C(id) * sp * P("=") ^ 0 / addStitch,

        assignTemp = "temp" * Cc(true) + Cc(false),
        assignUnwrapped = V"text" / unwrapAssign,
        assignValue = gatherLevel * sp * "~" * sp * V"assignTemp" * sp * V"assignUnwrapped" / addAssign,

        choiceFallback = choiceLevel * sp * none * (divert + divertToNothing),
        choiceDefault = choiceLevel * sp * V"text" * sp * divert ^ -1,
        choice = (V"choiceFallback" + V"choiceDefault") / addChoice,

        labelOptional = label + none,
        textOptional = V"text" + none,
        divertOptional = divert + none,
        tagsOptional = tags + none,

        paragraphLabel = label * sp * V"textOptional" * sp * V"divertOptional" * sp * V"tagsOptional",
        paragraphText = V"labelOptional" * sp * V"text" * sp * V"divertOptional" * sp * V"tagsOptional",
        paragraphDivert = V"labelOptional" * sp * V"textOptional" * sp * divert * sp * V"tagsOptional",
        paragraphTags = V"labelOptional" * sp * V"textOptional" * sp * V"divertOptional" * sp * tags,
        paragraph = gatherLevel * sp * (V"paragraphLabel" + V"paragraphText" + V"paragraphDivert" + V"paragraphTags") / addParagraph,

        line = sp * (V"statement" + V"paragraph") * ws,
        lines = Ct(V"line" ^ 0) + eof
    })

    local lines = ink:match(content)
    return model
end

return Parser

-- TODO: condition, success, failure (text / node / switches = if+elseif+else)

-- My friend's call me {friendly_name_of_player}. I'm {age} years old.
-- { "Yes, please." == "Yes, please." } // output 1

-- The train jolted and rattled. { mood > 0:I was feeling positive enough, however, and did not mind the odd bump|It was more than I could bear}.
-- *	{ not knows_about_wager } 'But, Monsieur, why are we travelling?'[] I asked.
-- * 	{ knows_about_wager} I contemplated our strange adventure[]. Would it be possible?
-- *	{shove} [Grapple and fight] -> fight_the_guard

-- { 
-- 	- x == 0:
-- 		~ y = 0
-- 	- x > 0:
-- 		~ y = x - 1
-- 	- else:
-- 		~ y = x + 1
-- }

-- { x:
-- - 0: 	zero 
-- - 1: 	one 
-- - 2: 	two 
-- - else: lots
-- }

-- {
--     - visited_snakes && not dream_about_snakes:
--         ~ fear++
--         -> dream_about_snakes

--     - visited_poland && not dream_about_polish_beer:
--         ~ fear--
--         -> dream_about_polish_beer 

--     - else:
--         // breakfast-based dreams have no effect
--         -> dream_about_marmalade
-- }

-- TODO: alts, seq, shuffle

-- text {~a|b|c||d} text

-- VAR a_colour = ""
-- ~ a_colour = "{~red|blue|green|yellow}" 
-- {a_colour} 

-- At the table, I drew a card. <>
-- { shuffle:
-- 	- 	Ace of Hearts.
-- 	- 	King of Spades.
-- 	- 	2 of Diamonds.
-- 		'You lose this time!' crowed the croupier.
-- }

-- TODO
-- diverts -> full paths
-- if stitch "_" is empty add divert to first stitch (by ink)
--
-- CLEAN
-- clean output from empty knots and stitches
-- convert expressions to lua code?
-- Почему бы для choice и alts не зафигачивать label сразу при парсинге а не считать их в рантайме?
-- divertions to labels - автозамена лэйблов на цепочку чойсов