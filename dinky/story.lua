--
-- Dependencies

local lume = require("lume")
local Object = require("classic")

local localFolder = (...):match('(.-)[^%.]+$') or (...)
local enums = require(localFolder .. "enums")

--
-- Story

local Story = Object:extend()

function Story:new(model)
	self.root = { }
	self.constants = { }
	self.variables = { }
	self:include(model)

	self.functions = self:inkFunctions()
	self.observers = { }
	self.globalTags = self:tagsFor(nil, nil)

	self.temp = { }
	self.seeds = { }
	self.choices = { }
	self.paragraphs = { }
	self.output = { }
	self.visits = { }
	self.currentPath = nil
	self.isOver = false
end

function Story:include(model)
	if model.includes ~= nil and model.luaPath ~= nil then
		for _, include in ipairs(model.includes) do
			local includePath = model.luaPath:match('(.-)[^%.]+$') .. include
			local includeModel = require(includePath)
			includeModel.luaPath = includePath
			self:include(includeModel)
		end
	end

	self.root = lume.merge(self.root, model.root or { })
	self.constants = lume.merge(self.constants, model.constants or { })
	self.variables = lume.merge(self.variables, model.variables or { })
end

function Story:begin()
	if #self.paragraphs == 0 and #self.choices == 0 and not self.isOver then
		self:read({ })
	end
end

function Story:canContinue()
	return #self.paragraphs > 0
end

function Story:continue(steps)
	if not self:canContinue() then return nil end
	local steps = steps or 1
	steps = steps > 0 and steps or #self.paragraphs

	local lines = { }
	for index = 1, steps do
		local paragraph = self.paragraphs[index]
		table.insert(lines, paragraph)
		table.insert(self.output, paragraph)
		table.remove(self.paragraphs, 1)
	end

	return lines
end

function Story:canChoose()
	return self.choices ~= nil and #self.choices > 0 and not self:canContinue()
end

function Story:getChoices()
	if self:canContinue() then return nil end
	return self.choices
end

function Story:choose(index)
	if self:canContinue() then return nil end
	local choiceIsAvailable = index > 0 and index <= #self.choices
	assert(choiceIsAvailable, "Choice index " .. index .. " out of bounds 1-" .. #self.choices)

	local choice = self.choices[index]
	assert(choice, "Choice index " .. index .. " out of bounds 1-" .. #self.choices)
	
	self.paragraphs = { }
	self.choices = { }

	if choice.text ~= nil and #choice.text > 0 then
		table.insert(self.paragraphs, { text = choice.text })
	end

	self:visit(choice.path)
	self:read(choice.divert or choice.path)
end

function Story:itemsFor(knot, stitch)
	local rootNode = self.root
	local knotNode = knot == nil and rootNode._ or rootNode[knot]
	assert(knotNode or lume.isarray(rootNode), "The knot '" .. (knot or "_") .. "' not found")
	local stitchNode = stitch == nil and knotNode._ or knotNode[stitch]
	assert(stitchNode or lume.isarray(knotNode), "The stitch '" .. (knot or "_") .. "." .. (stitch or "_") .. "' not found")
	return stitchNode or knotNode or rootNode
end

function Story:read(path)
	assert(path, "The path can't be nil")
	if path.knot == "END" or path.knot == "DONE" then
		self.isOver = true
	end
	if self.isOver then
		return
	end
	
	local items = self:itemsFor(path.knot, path.stitch)	
	self:visit(path)
	self:readItems(items, path)
end	

function Story:readItems(items, path, depth, mode)
	assert(items, "Items can't be nil")
	assert(path, "Path can't be nil")

	local chain = path.chain or { }
	local depth = depth or 0
	local deepIndex = chain[depth + 1]
	local mode = mode or enums.readMode.text

	-- Deep path factory

	local makeDeepPath = function(values, labelPrefix)
		local deepChain = lume.slice(chain, 1, depth)
		for valuesIndex, value in ipairs(values) do
			deepChain[depth + valuesIndex] = value
		end
		local deepPath = lume.clone(path)
		deepPath.chain = deepChain
		if labelPrefix then
			deepPath.label = labelPrefix .. table.concat(deepChain, ".")
		end
		return deepPath
	end

	-- Iterate items

	for index = deepIndex or 1, #items do
		local item = items[index]
		local skip = false

		local itemType = enums.blockType.text
		if type(item) == "table" then
			if item.choice ~= nil then itemType = enums.blockType.choice
			elseif item.condition ~= nil then itemType = enums.blockType.condition
			elseif item.var ~= nil then itemType = enums.blockType.variable
			elseif item.alts ~= nil then itemType = enums.blockType.alts
			end
		end

		-- Go deep
		if index == deepIndex then
			if item.node ~= nil then
				-- Go deep to the choice node
				mode = enums.readMode.gathers
				mode = self:readItems(item.node, path, depth + 1) or mode
			elseif item.success ~= nil then
				-- Go deep to the condition node
				local chainValue = chain[depth + 2]
				local success = chainValue:sub(1, 1) == "t"

				local node = item.failure	
				if success then
					local successIndex = math.tointeger(chainValue:sub(2, 2)) or 0
					node = successIndex > 0 and item.success[successIndex] or item.success
				end
				mode = self:readItems(node, path, depth + 2, mode) or mode
			end

			mode = mode ~= enums.readMode.quit and enums.readMode.gathers or mode
			skip = true
		end

		-- Check the situation
		if mode == enums.readMode.choices and itemType ~= enums.blockType.choice then
			mode = enums.readMode.quit
			skip = true
		elseif mode == enums.readMode.gathers and itemType == enums.blockType.choice then
			skip = true
		end
		
		-- Read the item
		if skip then
			-- skip
		elseif itemType == enums.blockType.text then
			mode = enums.readMode.text
			local safeItem = type(item) == "string" and { text = item } or item
			mode = self:readText(safeItem) or mode
		elseif itemType == enums.blockType.alts then
			mode = enums.readMode.text
			local deepPath = makeDeepPath({ index }, "~")
			mode = self:readAlts(item, deepPath) or mode
		elseif itemType == enums.blockType.choice then
			mode = enums.readMode.choices
			local deepPath = makeDeepPath({ index }, ">")
			mode = self:readChoice(item, deepPath) or mode
			if index == #items and type(chain[#chain]) == "number" then
				mode = enums.readMode.quit
			end
		elseif itemType == enums.blockType.condition then
			local result, chainValue
			if type(item.condition) == "string" then	
				local success = self:checkCondition(item.condition)
				result = success and item.success or (item.failure or { })
				chainValue = success and "t" or "f"
			elseif type(item.condition) == "table" then
				local success = self:checkSwitch(item.condition)
				result = success > 0 and item.success[success] or (item.failure or { })
				chainValue = success > 0 and ("t" .. success) or "f"
			end
			if type(result) == "string" then
				mode = enums.readMode.text
				mode = self:readText({ text = result }) or mode
			elseif type(result) == "table" then
				local deepPath = makeDeepPath({ index, chainValue })
				mode = self:readItems(result, deepPath, depth + 2, mode) or mode
			end
		elseif itemType == enums.blockType.variable then
			self:assignValueTo(item.var, item.value, item.temp)
		end

		-- Read the label
		if item.label ~= nil and not skip then
			local labelPath = lume.clone(path)
			labelPath.label = item.label
			self:visit(labelPath)
		end

		if mode == enums.readMode.quit then
			break
		end
	end

	return mode
end

function Story:readText(item)
	local text = item.text or item.gather
	local tags = type(item.tags) == "string" and { item.tags } or item.tags

	if text ~= nil or tags ~= nil then
		local paragraph = { text = text or "<>", tags = tags or { } }
		local gluedByPrev = #self.paragraphs > 0 and self.paragraphs[#self.paragraphs].text:sub(-2) == "<>"
		local gluedByThis = text ~= nil and text:sub(1, 2) == "<>"
		
		paragraph.text = self:replaceExpressions(paragraph.text)

		if gluedByPrev then
			local prevParagraph = self.paragraphs[#self.paragraphs]
			prevParagraph.text = prevParagraph.text:sub(1, #prevParagraph.text - 2)
			self.paragraphs[#self.paragraphs] = prevParagraph
		end

		if gluedByThis then
			paragraph.text = paragraph.text:sub(3)
		end

		if gluedByPrev or (gluedByThis and #self.paragraphs > 0) then
			local prevParagraph = self.paragraphs[#self.paragraphs]
			prevParagraph.text = prevParagraph.text .. paragraph.text
			prevParagraph.tags = lume.concat(prevParagraph.tags, paragraph.tags)
			self.paragraphs[#self.paragraphs] = prevParagraph
		elseif #paragraph.tags > 0 or #paragraph.text > 0 then
			table.insert(self.paragraphs, #self.paragraphs + 1, paragraph)
		end
	end

	if item.divert ~= nil then
		self:read(item.divert)
		return enums.readMode.quit
	end
end

function Story:readAlts(item, path)
	assert(item.alts, "Alternatives can't be nil")
	local alts = lume.clone(item.alts)

	local seqType = item.seq or enums.seqType.stopping
	if type(seqType) == "string" then
		seqType = enums.seqType[item.seq] or seqType
	end

	self:visit(path)
	local visits = self:visitsFor(path)
	local index = 0

	if item.shuffle then
		local seedKey = (path.knot or "_") .. "." .. (path.stitch or "_") .. ":" .. path.label
		local seed = visits % #alts == 1 and os.time() or self.seeds[seedKey]
		self.seeds[seedKey] = seed

		for index, alt in ipairs(alts) do
			math.randomseed(seed + index)
			local pairIndex = index < #alts and math.random(index + 1, #alts) or index
			alts[index] = alts[pairIndex]
			alts[pairIndex] = alt
		end
	end

	if seqType == enums.seqType.cycle then
		index = visits % #alts
		index = index > 0 and index or #alts
	elseif seqType == enums.seqType.stopping then
		index = visits < #alts and visits or #alts
	elseif seqType == enums.seqType.once then
		index = visits
	end

	local textItem = alts[index] or ""
	local safeItem = type(textItem) == "string" and { text = textItem } or textItem
	return self:readText(safeItem)
end

function Story:readChoice(item, path)
	local isFallback = item.choice == 0

	if isFallback then
		-- Works correctly only when a fallback is the last choice
		if #self.choices == 0 then
			self:read(item.divert or path)
		end
		return enums.readMode.quit
	end

	local choice = {
		title = self:replaceExpressions(item.choice),
		text = item.text ~= nil and self:replaceExpressions(item.text) or title,
		divert = item.divert,
		path = path
	}

	if item.sticky or self:visitsFor(path) == 0 then
		table.insert(self.choices, #self.choices + 1, choice)
	end
end


-- Expressions

function Story:replaceExpressions(text)
	return text:gsub("(%b%%)", function(match)
		if #match == 2 then
			return "%"
		else
			local result = self:doExpression(match:sub(2, #match-1)) 
			if type(result) == "boolean" then result = result and 1 or 0 end
			if result == nil then result = "" end
			return result
		end
	end)
end

function Story:checkSwitch(conditions)
	for index, condition in ipairs(conditions) do
		if self:checkCondition(condition) then
			return index
		end
	end
	return 0
end

function Story:checkCondition(condition)
	local result = self:doExpression(condition)
	return result ~= nil and result ~= false
end

function Story:doExpression(expression)
	assert(type(expression) == "string", "Expression must be a string")
	
	expression = expression:gsub("!=", "~=")
	expression = expression:gsub("%s*||%s*", " or ")	
	expression = expression:gsub("%s*%&%&%s*", " and ")
	expression = expression:gsub("([%a][%w_]*)%s*([%+%-])[%+%-]", "%1 = %1 %2 1")
	expression = expression:gsub("([%a][%w_]*)%s*([%+%-])=%s*([%w_]*)", "%1 = %1 %2 %3")
	
	-- Check for functions
	expression = expression:gsub("[%a][%w_]*%(.*%)", function(match)
		local functionName = match:match("([%a][%w_]*)%(")
		local paramsString = match:match("[%a][%w_]*%((.+)%)")
		local params = paramsString ~= nil and lume.map(lume.split(paramsString, ","), lume.trim) or nil

		for index, param in ipairs(params or { }) do
			params[index] = self:doExpression(param)
		end

		local func = self.functions[functionName]
		if func ~= nil then
			local result = func(table.unpack(params or { }))
			return lume.serialize(result)
		end
		return "nil"
	end)

	-- Check for variables
	expression = expression:gsub("[\"\'%a][%w_%.\"\']*", function(match)
		local exceptions = { "and", "or", "true", "false"}
		if lume.find(exceptions, match) ~= nil or match:match("[\"\'].*[\"\']") ~= nil then
			return match
		else
			local value = self:getValueFor(match)
			return lume.serialize(value)
		end
	end)

	-- Check for match operation
	expression = expression:gsub("[\"\'%a][%w_%.\"\']*[%s]*[%?!]+[%s]*[\"\'%a][%w_%.\"\']*", function(match)
		local string, operator, sub = match:match("([\"\'%a][%w_%.\"\']*)[%s]*([%?!]+)[%s]*([\"\'%a][%w_%.\"\']*)")
		return string .. ":match(" .. sub .. ")" .. (operator == "?!" and " == nil" or " ~= nil")
	end)

	return lume.dostring("return " .. expression)
end

function Story:assignValueTo(variable, expression, temp)
	if self.constants[variable] ~= nil then return end
	
	local value = self:doExpression(expression)
	if temp then self.temp[variable] = value
	else self.variables[variable] = value end

	local observer = self.observers[variable]
	if observer ~= nil then observer(value) end
end

function Story:getValueFor(variable)
	local value = self.temp[variable]
	if value == nil then value = self.variables[variable] end
	if value == nil then value = self.constants[variable] end
	if value == nil then
		local path = self:pathFromString(variable, self.currentPath)
		local visitsCount = self:visitsFor(path)
		value = visitsCount > 0 and visitsCount or nil
	end
	return value
end


-- Visits

function Story:visit(path)
	local pathIsChanged = self.currentPath == nil or path.knot ~= self.currentPath.knot or path.stitch ~= self.currentPath.stitch

	if pathIsChanged then
		if self.currentPath == nil or path.knot ~= self.currentPath.knot then
			local knot = path.knot or "_"
			local visits = self.visits[knot] or { _root = 0 }
			visits._root = visits._root + 1
			self.visits[knot] = visits
		end
	
		local knot, stitch = path.knot or "_", path.stitch or "_"
		local visits = self.visits[knot][stitch] or { _root = 0 }
		visits._root = visits._root + 1
		self.visits[knot][stitch] = visits
	end

	if path.label ~= nil then
		local knot, stitch, label = path.knot or "_", path.stitch or "_", path.label
		self.visits[knot] = self.visits[knot] or { _root = 1, _ = { _root = 1 } } 
		self.visits[knot][stitch] = self.visits[knot][stitch] or { _root = 1 }
		local visits = self.visits[knot][stitch][label] or 0
		visits = visits + 1
		self.visits[knot][stitch][path.label] = visits
	end

	self.currentPath = lume.clone(path)
	self.currentPath.label = nil
	self.temp = pathIsChanged and { } or self.temp
end

function Story:visitsFor(path)
	if path == nil then return 0 end
	local knot, stitch, label = path.knot or "_", path.stitch or "_", path.label

	local knotVisits = self.visits[knot]
	if knotVisits == nil then return 0
	elseif stitch == nil then return knotVisits._root or 0 end

	local stitchVisits = knotVisits[stitch]
	if stitchVisits == nil then return 0
	elseif label == nil then return stitchVisits._root or 0 end

	local labelVisits = stitchVisits[label]
	return labelVisits or 0
end

function Story:pathFromString(pathString, context)
	local part1, part2, part3 = pathString:match("([%w_]+)%.([%w_]+)%.([%w_]+)")
	if part1 == nil then
		part1, part2 = pathString:match("([%w_]+)%.([%w_]+)")
		part1 = part1 or pathString
	end

	if part3 ~= nil or context == nil then 
		return { knot = part1, stitch = part2, label = part3 }
	end

	local path = lume.clone(context)
	local rootNode = self.root[path.knot or "_"]
	local knotNode = part1 ~= nil and self.root[part1] or nil

	if part2 ~= nil then
		if knotNode ~= nil then
			path.knot = part1
			if knotNode[part2] ~= nil then path.stitch = part2
			else path.label = part2 end
		elseif rootNode ~= nil and rootNode[part1] ~= nil then
			path.stitch = part1
			path.label = part2
		else
			path.label = part2
		end
	elseif part1 ~= nil then
		if knotNode ~= nil then
			path.knot = part1
		elseif rootNode ~= nil and rootNode[part1] ~= nil then
			path.stitch = part1
		else
			path.label = part1
		end
	end
	
	return path
end

-- Tags

function Story:tagsFor(knot, stitch)
	local items = self:itemsFor(knot, stitch)
	local tags = { }

	for _, item in ipairs(items) do
		if lume.count(item) > 1 or item.tags == nil then break end
		local itemTags = type(item.tags) == "string" and { item.tags } or item.tags
		tags = lume.concat(tags, itemTags)
	end

	return tags
end


-- States

function Story:saveState()
	local state = {
		temp = self.temp,
		seeds = self.seeds,
		variables = self.variables,
		visits = self.visits,
		currentPath = self.currentPath,
		paragraphs = self.paragraphs,
		choices = self.choices,
		output = self.output
	}
	return state
end

function Story:loadState(state)
	self.temp = state.temp
	self.seeds = state.seeds
	self.variables = state.variables
	self.visits = state.visits
	self.currentPath = state.path
	self.paragraphs = state.paragraphs
	self.choices = state.choices
	self.output = output
end


-- Reactive

function Story:observe(variable, observer)
	self.observers[variable] = observer
end

function Story:bind(name, func)
	self.functions[name] = func
end


-- Ink functions

function Story:inkFunctions()
	return {
		CHOICE_COUNT = function() return #self.choices end,
		SEED_RANDOM = function(seed) math.randomseed(seed) end,
		POW = function(x, y) return math.pow(x, y) end,
		RANDOM = function(x, y) return math.random(x, y) end,
		INT = function(x) return math.floor(x) end,
		FLOOR = function(x) return math.floor(x) end,
		FLOAT = function(x) return x end

		-- TURNS = function() return nil end -- TODO
		-- TURNS_SINCE = function(path) return nil end -- TODO	

		-- LIST_VALUE = function(list) return nil end -- TODO
		-- LIST_COUNT = function(list) return nil end -- TODO
		-- LIST_MIN = function(list) return nil end -- TODO
		-- LIST_MAX = function(list) return nil end -- TODO
		-- LIST_RANDOM = function(list) return nil end -- TODO
		-- LIST_ALL = function(list) return nil end -- TODO
		-- LIST_RANGE = function(list) return nil end -- TODO
		-- LIST_INVERT = function(list) return nil end -- TODO
	}
end

return Story