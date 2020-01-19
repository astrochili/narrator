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

	self.currentPath = { }
	self.choices = { }
	self.paragraphs = { }
	self.output = { }
	self.globalTags = self:tagsFor(nil)
	self.visits = { _ = { _root = 1, _ = { _root = 1 } } }
	self:read(self.currentPath)
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
	assert(knotNode or knot == nil, "The knot '" .. (knot or "_") .. "' not found")
	local stitchNode = stitch == nil and knotNode._ or knotNode[stitch]
	assert(stitchNode or stitch == nil, "The stitch '" .. (stitch or "_") .. "' not found")
	return stitchNode or knotNode or rootNode
end

function Story:read(path)
	assert(path, "The path can't be nil")
	if path.knot == "END" or path.knot == "DONE" then return end

	local items = self:itemsFor(path.knot, path.stitch)	
	self:visit(path)
	self:readItems(items, path)
end	

function Story:readItems(items, path, depth)
	assert(items, "Items can't be nil")
	assert(path, "Path can't be nil")
	local canContinue = true

	local chain = path.chain or { }
	local depth = depth or 0
	local deepIndex = (depth < #chain) and chain[depth + 1] or nil

	local choicesIsPassed = deepIndex == nil
	local choicesIsReached = false

	for index = deepIndex or 1, #items do
		local item = items[index]
		local itemType = item.choice ~= nil and enums.BLOCK_TYPE_CHOICE or enums.BLOCK_TYPE_TEXT
		local choicesOver = choicesIsReached and itemType ~= enums.BLOCK_TYPE_CHOICE

		canContinue = not choicesOver
		if not canContinue then break end

		-- Go deep to the node
		if index == deepIndex then
			if item.node ~= nil then
				canContinue = self:readItems(item.node, path, depth + 1)
				if not canContinue then break end
			end
			deepIndex = nil
			choicesIsPassed = false
		end

		-- Just read the item
		local skipItem = itemType == enums.BLOCK_TYPE_CHOICE and (index == deepIndex or not choicesIsPassed)

		if not skipItem and item.label ~= nil then
			local labelPath = lume.clone(path)
			labelPath.label = item.label
			self:visit(labelPath)
		end

		if skipItem then
			-- skip
		elseif itemType == enums.BLOCK_TYPE_CHOICE then
			choicesIsReached = true
			local nextChain = lume.clone(chain)
			nextChain[depth + 1] = index
			local nextPath = lume.clone(path)
			nextPath.chain = nextChain
			nextPath.label = ">" .. table.concat(nextChain, ".")
			canContinue = self:readChoice(item, nextPath) and index < #items
			if not canContinue then break end
		elseif itemType == enums.BLOCK_TYPE_TEXT then
			choicesIsPassed = true
			canContinue = self:readText(item)
			if not canContinue then break end
		end
	end

	return canContinue
end

function Story:readText(item)
	local text = item.text or item.gather
	local tags = type(item.tags) == "string" and { item.tags } or item.tags
	local canContinue = true

	if text ~= nil or tags ~= nil then
		local paragraph = { text = text or "<>", tags = tags or { } }
		local gluedByPrev = #self.paragraphs > 0 and self.paragraphs[#self.paragraphs].text:sub(-2) == "<>"
		local gluedByThis = text ~= nil and text:sub(1, 2) == "<>"
		
		paragraph.text = paragraph.text:gsub("(%%[%w_.]+%%)", function(match)
			return self:getValueFor(match:sub(2, #match-1)) or match
		end)

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
		else
			table.insert(self.paragraphs, #self.paragraphs + 1, paragraph)
		end
	end

	if item.divert ~= nil then
		self:read(item.divert)
		canContinue = false
	end

	return canContinue
end

function Story:readChoice(item, path)
	local isFallback = item.choice == 0
	local canContinue = true

	if isFallback then
		if #self.choices == 0 then
			-- TODO: A fallback isn't the last choice
			self:read(item.divert or path)
		end
		canContinue = false
	else
		local choice = {
			title = item.choice,
			text = item.text or item.choice,
			divert = item.divert,
			path = path
		}

		if item.sticky or self:visitsFor(path) == 0 then
			table.insert(self.choices, #self.choices + 1, choice)
		end
	end

	return canContinue
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


-- Variables

function Story:getValueFor(variable)
	local value = self.variables[variable] or self.constants[variable]
	if value == nil then
		local path = self:pathFromString(variable, self.currentPath)
		local visitsCount = self:visitsFor(path)
		value = visitsCount > 0 and visitsCount or nil
	end
	return value
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


-- Visits

function Story:visit(path)
	if path.knot ~= self.currentPath.knot then
		local knot = path.knot or "_"
		local visits = self.visits[knot] or { _root = 0 }
		visits._root = visits._root + 1
		self.visits[knot] = visits
	end

	if path.knot ~= self.currentPath.knot or path.stitch ~= self.currentPath.stitch then
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
		path.label = nil
	end

	self.currentPath = path
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


-- States

function Story:saveState()
	local state = {
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
	self.variables = state.variables
	self.visits = state.visits
	self.currentPath = state.path
	self.paragraphs = state.paragraphs
	self.choices = state.choices
	self.output = output
end


-- Reactive

-- function Story:observe(variable, func)
-- 	-- TODO: Observe variable changes and call the function
-- end

-- function Story:bind(name, func)
-- 	-- TODO: Bind an external function to the Ink function call
-- end

return Story