--
-- Dependencies

local lume = require("lume")
local Object = require("classic")

local localFolder = (...):match('(.-)[^%.]+$') or (...)
local enums = require(localFolder .. ".enums")

--
-- Story

local Story = Object:extend()

function Story:new(model)
	self.model = model
	
	-- self.variables = { } -- dictionary of variables (saved to state)
	-- self.constants = model.constants -- dictionary of constants (not saved to state)
	
	self.currentPath = { }
	self.choices = { }
	self.paragraphs = { }
	self.globalTags = self:tagsFor(self.currentPath)
	self.visits = { _ = { _count = 1, _ = { _count = 1 } } }
	self:read(self.currentPath)
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
		table.insert(lines, 1, self.paragraphs[index])
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

	table.insert(self.paragraphs, { text = choice.text })
	self:read(choice.path)
end

function Story:visit(path, label)
	if path.knot ~= self.currentPath.knot then
		local knot = path.knot or "_"
		local visits = self.visits[knot] or { _count = 0 }
		visits._count = visits._count + 1
		self.visits[knot] = visits
	end

	if path.knot ~= self.currentPath.knot or path.stitch ~= self.currentPath.stitch then
		local knot, stitch = path.knot or "_", path.stitch or "_"
		local visits = self.visits[knot][stitch] or { _count = 0 }
		visits._count = visits._count + 1
		self.visits[knot][stitch] = visits
	end

	if label ~= nil then
		local knot, stitch = path.knot or "_", path.stitch or "_"
		self.visits[knot] = self.visits[knot] or { _count = 1, _ = { _count = 1 } } 
		self.visits[knot][stitch] = self.visits[knot][stitch] or { _count = 1 }
		local visits = self.visits[knot][stitch][label] or 0
		visits = visits + 1
		self.visits[knot][stitch][label] = visits
	end

	self.currentPath = path
end

function Story:itemsFor(path)
	local rootNode = self.model.root
	local knotNode = path.knot == nil and rootNode._ or rootNode[path.knot]
	assert(knotNode or path.knot == nil, "The knot '" .. (path.knot or "_") .. "' not found")
	local stitchNode = path.stitch == nil and knotNode._ or knotNode[stitch]
	assert(stitchNode or path.stitch == nil, "The stitch '" .. (path.stitch or "_") .. "' not found")
	return stitchNode or knotNode or rootNode
end

function Story:read(path)
	assert(path, "The path can't be nil")
	if path.knot == "END" or path.knot == "DONE" then return end

	local items = self:itemsFor(path)	
	self:visit(path)
	self:readItems(items, path)
end	

function Story:readItems(items, targetPath, transitPath) 
	assert(items, "Items can't be nil")
	assert(targetPath, "Path can't be nil")

	if transitPath == nil then
		transitPath = lume.clone(targetPath)
		transitPath.choices = { }
	end

	local canContinue = true
	local needToDive = targetPath.choices ~= nil and #transitPath.choices ~= #targetPath.choices
	local choicesIsPassed = not needToDive
	local choicesIsReached = false

	local deepIndex = needToDive and targetPath.choices[#transitPath.choices + 1] or nil
	
	for index = deepIndex or 1, #items do
		local item = items[index]
		local itemType = item.choice ~= nil and enums.BLOCK_TYPE_CHOICE or enums.BLOCK_TYPE_TEXT
		local choicesOver = choicesIsReached and itemType ~= enums.BLOCK_TYPE_CHOICE

		canContinue = not choicesOver
		if not canContinue then break end

		-- Go deep to the node
		if index == deepIndex then
			if item.node ~= nil then
				local choicePath = lume.clone(transitPath)
				choicePath.choices = lume.clone(transitPath.choices)
				table.insert(choicePath.choices, deepIndex)
				canContinue = self:readItems(item.node, targetPath, choicePath)
				if not canContinue then break end
			end
			deepIndex = nil
			choicesIsPassed = false
		end

		-- Just read the item
		local itemIsSkipped = false
		if itemType == enums.BLOCK_TYPE_CHOICE and index ~= deepIndex and choicesIsPassed then
			choicesIsReached = true
			local choicePath = lume.clone(transitPath)
			choicePath.choices = lume.clone(transitPath.choices)
			table.insert(choicePath.choices, index)
			self:readChoice(item, choicePath)
			canContinue = index < #items
			if not canContinue then break end
		elseif itemType == enums.BLOCK_TYPE_TEXT then
			choicesIsPassed = true
			canContinue = self:readText(item)
			if not canContinue then break end
		else
			itemIsSkipped = true
		end

		if not itemIsSkipped and item.label ~= nil then
			self:visit(targetPath, item.label)
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
	local choice = {
		title = item.choice,
		text = item.text or item.choice,
		path = item.divert or path
	}
	
	table.insert(self.choices, #self.choices + 1, choice)
end


-- Tags

function Story:tagsFor(path)
	local items = self:itemsFor(path)
	local tags = { }

	for _, item in ipairs(items) do
		if lume.count(item) > 1 or item.tags == nil then break end
		local itemTags = type(item.tags) == "string" and { item.tags } or item.tags
		tags = lume.concat(tags, itemTags)
	end

	return tags
end


-- States

-- function Story:saveState()
-- 	local state = {
-- 		variables = self.variables,
-- 		path = self.path,
-- 		visits = self.visits
-- 	}
-- 	return state
-- end

-- function Story:loadState(state)
-- 	-- TODO: Load state
-- end


-- Reactive

-- function Story:observe(variable, func)
-- 	-- TODO: Observe variable changes and call the function
-- end

-- function Story:bind(name, func)
-- 	-- TODO: Bind an external function to the Ink function call
-- end

return Story