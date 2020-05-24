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

    --
    -- Story construction functions

    local function addItem(level, item)
        local level = level > 0 and level or #nodesChain
        while #nodesChain > level do
            table.remove(nodesChain)
        end
        
        local node = nodesChain[#nodesChain]
        table.insert(node, item)
    end

    local function addInclude(filename)
        table.insert(model.includes, filename)
    end
    
    local function addList(name, list)
        local items = lume.array(value:gmatch("[%w_%.]+"))
        model.lists[name] = items

        local switched = lume.array(value:gmatch("%b()"))
        switched = lume.map(switched, function(item) return item:sub(2, #item - 1) end)
        model.variables[name] = { [name] = { } }
        lume.each(switched, function(item) model.variables[name][name][item] = true end)
    end

    local function addConstant(constant, value)
        model.constants[constant] = lume.deserialize(value)
    end

    local function addVariable(variable, value)
        model.variables[variable] = lume.deserialize(value)
    end

    local function convertParagraphToItems(parts, isRoot)
        if parts == nil then return nil end

        local isRoot = isRoot ~= nil and isRoot or false
        local items = { }
        local item
        
        for index, part in ipairs(parts) do
            if part.condition ~= nil then
                item = {
                    condition = part.condition.condition,
                    success = convertParagraphToItems(part.condition.success),
                    failure = convertParagraphToItems(part.condition.failure)
                }

                table.insert(items, item)
                item = nil
            elseif part.sequence ~= nil then
                item = {
                    seq = part.sequence.seq,
                    shuffle = part.sequence.shuffle and true or nil,
                    alts = { }
                }
                
                for _, alt in ipairs(part.sequence.alts) do
                    table.insert(item.alts, convertParagraphToItems(alt))
                end

                table.insert(items, item)
                item = nil
            else
                local nextPart = parts[index + 1]
                local isNakedDivert = part.divert ~= nil and part.text == nil

                if item == nil then
                    item = { text = (isRoot or isNakedDivert) and "" or "<>" }
                end

                if part.text ~= nil then
                    item.text = item.text .. part.text
                elseif part.expression ~= nil then
                    item.text = item.text .. "#" .. part.expression .. "#"
                end

                if part.divert ~= nil then
                    item.divert = part.divert
                    item.text = #item.text > 0 and item.text or nil
                    table.insert(items, item)
                    item = nil
                elseif nextPart == nil or (nextPart.text == nil and nextPart.expression == nil) then
                    item.text = item.text .. (isRoot and "" or "<>")
                    table.insert(items, item)
                    item = nil
                end
            end
        end

        if isRoot then
            -- Add a safe prefix and suffix for correct conditions gluing
            
            local firstItem = items[1]
            if firstItem.text == nil and firstItem.divert == nil then
                table.insert(items, 1, { text = "" } )
            end

            local lastItem = items[#items]
            if lastItem.text == nil and lastItem.divert == nil then
                table.insert(items, { text = "" } )
            end
        end

        return items
    end

    local function addSwitch(cases)
        print("")
        -- TODO: clean levels of choices and paragraphs inside multilines to nil, this is the rule by ink.
        -- TODO: also choices must have diverts else ignore them, this is also the rule by ink.
    end

    local function addParagraph(paragraph)
        local items = convertParagraphToItems(paragraph.parts, true)
        items = items or { }
        
        -- If the paragraph has a label, a divert or tags we need to place it as the first text item.
        if paragraph.label ~= nil or divert ~= nil or paragraph.tags ~= nil then
            -- TODO: where is divert ?!?!?!
            local firstItem

            if #items > 0 and items[1].condition == nil then
                firstItem = items[1]
            else
                firstItem = {  }
                table.insert(items, firstItem)
            end

            firstItem.label = paragraph.label
            firstItem.tags = paragraph.tags
        end

        for _, item in ipairs(items) do
            addItem(paragraph.level, item)
        end
    end

    local function addChoice(choice)
        local item = {
            sticky = choice.sticky or nil,
            divert = choice.divert,
            label = choice.label,
            node = { }
        }

        local text = choice.text
        if text == nil then
            item.choice = 0
        else
            local part1, divider, part2 = text:match("(.*)%[(.*)%](.*)")
            item.choice = (part1 or text) .. (divider or "")
            item.text = (part1 or text) .. (part2 or "")
        end

        local condition = choice.condition
        if condition then
            local conditionItem = {
                condition = condition,
                success = { item }
            }
            addItem(choice.level, conditionItem)
        else
            addItem(choice.level, item)
        end

        table.insert(nodesChain, item.node)    
    end

    local function addAssign(assign)
        local item = {
            temp = assign.temp or nil,
            var = assign.expression.variable,
            value = assign.expression.value
        }

        addItem(assign.level, item)
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

    --
    -- LPEG parsing

    local eof = -1
    local sp = S(" \t") ^ 0
    local ws = S(" \t\r\n") ^ 0
    local nl = S("\r\n") ^ 1
    local none = Cc(nil)

    local divertSign = P"->"
    local gatherMark = sp * C("-" - divertSign)
    local gatherLevel = Cg(Ct(gatherMark ^ 0) / table.getn, "level")
    
    local stickyMarks = Cg(Ct((sp * C("+")) ^ 1) / table.getn, "level") * Cg(Cc(true), "sticky")
    local choiceMarks = Cg(Ct((sp * C("*")) ^ 1) / table.getn, "level") * Cg(Cc(false), "sticky")
    local choiceLevel = stickyMarks + choiceMarks

    local id = (lpeg.alpha + "_") * (lpeg.alnum + "_") ^ 0
    local label = Cg("(" * sp * C(id) * sp * ")", "label")
    local address = id * ("." * id) ^ -2
    local divert = Cg(divertSign * sp * C(address), "divert")
    local divertToNothing = divertSign * none
    local tag = "#" * sp * V"text"
    local tags = Cg(Ct(tag * (sp * tag) ^ 0), "tags")

    local todo = sp * "TODO:" * (1 - nl) ^ 0
    local commentLine = sp * "//" * sp * (1 - nl) ^ 0
    local commentMulti = sp * "/*" * ((P(1) - "*/") ^ 0) * "*/"
    local comment = commentLine + commentMulti

    local multilineEnd = ws * "}"

    local function unwrapAssignment(expression)
        local unwrapped = expression
        unwrapped = unwrapped:gsub("([%w_]*)%s*([%+%-])[%+%-]", "%1 = %1 %2 1")
        unwrapped = unwrapped:gsub("([%w_]*)%s*([%+%-])=%s*(.*)", "%1 = %1 %2 %3")
        name, value = unwrapped:match("([%w_]*)%s*=%s*(.*)")
        return name, value
    end

    local function sentenceBefore(...)
        local excluded
        for _, pattern in ipairs(arg) do
            excluded = excluded == nil and pattern or excluded + pattern
        end

        local character = P(1 - S(" \t")) - excluded
        local pattern = (sp * character ^ 1) ^ 1
        local withSpaceTail = C(pattern * sp) * #(P"{" - V"multiline")
        local withoutSpaceTail = C(pattern) * sp

        return withSpaceTail + withoutSpaceTail
    end

    local function multiline(params)
        local paragraph = params.isRoot and V"paragraph" or V"restrictedParagraph"
        return sp * paragraph ^ -1 * sp * V"multiline" * sp * paragraph ^ -1 * ws
    end

    local function multilineLinesStartedWith(startPattern)

    end

    local function itemType(type)
        return Cg(Cc(type), "type")
    end

    local ink = P({ "root",

        --
        -- Root

        root = V"items" + eof,
        items = Ct((
            multiline { isRoot = true } + V"singleline"
        ) ^ 0),

        singleline = sp * (V"global" + V"statement" + V"paragraph") * ws,
        multiline = ("{" * sp * (V"sequence" + V"switch") * sp * multilineEnd) - V"inlineCondition",

        --
        -- Global declarations

        global =
            V"include" / addInclude +
            V"list" / addList +
            V"const" / addConstant +
            V"var" / addVariable
        ,

        include = "INCLUDE" * sp * V"text",
        list = "LIST" * sp * V"assignmentUnwrapped",
        const = "CONST" * sp * V"assignmentUnwrapped",
        var = "VAR" * sp * V"assignmentUnwrapped",

        --
        -- Statements

        statement = 
            Ct(V"assignment" * itemType("assignment")) + 
            Ct(V"knot" * itemType("knot")) +
            Ct(V"stitch" * itemType("stitch")) +
            Ct(V"choice" * itemType("choice")) +
            comment + todo
        ,
        
        sectionName = C(id) * sp * P("=") ^ 0,
        knot = "===" * sp * Cg(V"sectionName", "knot"),
        stitch = "=" * sp * Cg(V"sectionName", "stitch"),

        assignment = gatherLevel * sp * "~" * sp * V"assignmentTemp" * sp * V"assignmentPair",
        assignmentTemp = Cg("temp" * Cc(true) + Cc(false), "temp"),
        assignmentPair = Cg(V"assignmentUnwrapped", "var") * Cg(Cb("var") / 2, "value"),
        assignmentUnwrapped = V"text" / unwrapAssignment,

        choiceCondition = Cg(V"expression" + none, "condition"),
        choiceFallback = choiceLevel * sp * V"labelOptional" * sp * V"choiceCondition" * sp * (divert + divertToNothing),
        choiceNormal = choiceLevel * sp * V"labelOptional" * sp * V"choiceCondition" * sp * Cg(V"text", "text") * sp * divert ^ -1,
        choice = V"choiceFallback" + V"choiceNormal",

        --
        -- Paragraph

        paragraph = Ct(gatherLevel * sp * (V"paragraphLabel" + V"paragraphText" + V"paragraphTags") * itemType("paragraph")),
        paragraphLabel = label * sp * Cg(V"textOptional", "parts") * sp * V"tagsOptional",
        paragraphText = V"labelOptional" * sp * Cg(V"textComplex", "parts") * sp * V"tagsOptional",
        paragraphTags = V"labelOptional" * sp * Cg(V"textOptional", "parts") * sp * tags,
        
        labelOptional = label + none,
        textOptional = V"textComplex" + none,
        tagsOptional = tags + none,

        textComplex = Ct((Ct(
            Cg(V"inlineCondition", "condition") + 
            Cg(V"inlineSequence", "sequence") + 
            Cg(V"expression", "expression") +
            Cg(V"text", "text") * sp * (divert ^ -1) + sp * divert
        ) - V"multiline") ^ 1),

        text = sentenceBefore(nl, divert, comment, tag, S"{|}") - V"statement",

        --
        -- Inline expressions, conditions, sequences

        expression = "{" * sp * sentenceBefore("}", nl) * sp * "}",

        inlineCondition = "{" * sp * Ct(V"inlineIfElse" + V"inlineIf") * sp * "}",
        inlineIf = Cg(sentenceBefore(S":}" + nl), "condition") * sp * ":" * sp * Cg(V"textComplex", "success"),
        inlineIfElse = (V"inlineIf") * sp * "|" * sp * Cg(V"textComplex", "failure"),
        
        inlineAltEmpty = Ct(Ct(Cg(sp * Cc"", "text") * sp * divert ^ -1)),
        inlineAlt = V"textComplex" + V"inlineAltEmpty",
        inlineAlts = Ct(((sp * V"inlineAlt" * sp * "|") ^ 1) * sp * V"inlineAlt"),
        inlineSequence = "{" * sp * (
        "!" * sp * Ct(Cg(V"inlineAlts", "alts") * Cg(Cc("once"),  "seq")) +
        "&" * sp * Ct(Cg(V"inlineAlts", "alts") * Cg(Cc("cycle"), "seq")) +
        "~" * sp * Ct(Cg(V"inlineAlts", "alts") * Cg(Cc("stop"),  "seq") * Cg(Cc(true),  "shuffle")) +
                   Ct(Cg(V"inlineAlts", "alts") * Cg(Cc("stop"),  "seq"))
        ) * sp * "}",

        --
        -- Multiline switch

        switch = Ct((V"switchComparative" + V"switchConditional") * itemType("switch")),

        switchComparative = Cg(V"switchCondition", "condition") * ws * Cg(Ct((sp * V"switchCase") ^ 1), "cases"),
        switchConditional = Cg(Ct(V"switchCasesHeaded" + V"switchCasesOnly"), "cases"),
        
        switchCasesHeaded = V"switchIf" * ((sp * V"switchCase") ^ 0),
        switchCasesOnly = ws * ((sp * V"switchCase") ^ 1),

        switchIf = Ct(Cg(V"switchCondition", "case") * ws * Cg(Ct(V"switchItems"), "success")),
        switchCase = ("-" - divertSign) * sp * V"switchIf",
        switchCondition = sentenceBefore(":", nl) * sp * ":",
        switchItems = (V"restrictedItem" - V"switchCase") ^ 1,

        --
        -- Multiline sequences
        
        sequence = Ct((V"sequenceParams" * sp * nl * sp * V"sequenceAlts") * itemType("sequence")),

        sequenceParams = (
            V"sequenceShuffleOptional" * sp * V"sequenceType" +
            V"sequenceShuffle" * sp * V"sequenceType" +
            V"sequenceShuffle" * sp * V"sequenceTypeOptional"
        ) * sp * ":",

        sequenceShuffleOptional = V"sequenceShuffle" + Cg(Cc(false), "shuffle"),
        sequenceShuffle = Cg(P"shuffle" / function() return true end, "shuffle"),

        sequenceTypeOptional = V"sequenceType" + Cg(Cc"cycle", "sequence"),
        sequenceType = Cg(P"cycle" + "stopping" + "once", "sequence"),

        sequenceAlts = Cg(Ct((sp * V"sequenceAlt") ^ 1), "alts"),
        sequenceAlt = ("-" - divertSign) * ws * Ct(V"sequenceItems"),
        sequenceItems = (V"restrictedItem" - V"sequenceAlt") ^ 1,

        --
        -- Multiline items

        restrictedItem = V"restrictedSingleline" + V"restrictedMultiline",
        restrictedSingleline = sp * (V"global" + V"restrictedStatement" + V"restrictedParagraph" - multilineEnd) * ws,
        restrictedMultiline = multiline { isRoot = false },

        restrictedStatement = Ct(
            V"choice" * itemType("choice") +
            V"assignment" * itemType("assignment")
        ) + comment + todo,
        
        restrictedParagraph = Ct((
            Cg(V"textComplex", "parts") * sp * V"tagsOptional" +
            Cg(V"textOptional", "parts") * sp * tags
        ) * itemType("paragraph"))

    })

    local lines = ink:match(content)
    -- TODO: addLines(lines)
    return model
end

return Parser