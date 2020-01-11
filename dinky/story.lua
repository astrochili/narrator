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
	self.model = model -- passive model of story
	-- self.visits = { } -- dictionary of visits [knot [stitch = 3]]
	-- self.variables = { } -- dictionary of variables (saved to state)
	-- self.constants = model.constants-- dictionary of constants (not saved to state)

	-- self.currentTags = { }
	self.choices = { }
	self.paragraphs = { }

	local rootPath = { knot = "_" }
	self:read(rootPath)
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

	table.insert(self.paragraphs, choice.text)
	self:read(choice.path)
end

function Story:read(path)
	if path.knot == "END" or path.knot == "DONE" then return end
	assert(path, "Path can't be nil")

	local knotItems = self.model.knots[path.knot]
	assert(knotItems, "The knot '" .. path.knot .. "' not found")

	local stitchItems = path.stitch ~= nil and knotItems[path.stitch] or nil
	local nodeItems = stitchItems or knotItems

	self:readItems(nodeItems, path)
end	

function Story:readItems(items, targetPath, currentPath) 
	assert(items, "Items can't be nil")
	assert(targetPath, "Path can't be nil")

	if currentPath == nil then
		currentPath = lume.clone(targetPath)
		currentPath.choices = { }
	end

	local canContinue = true
	local needToDive = targetPath.choices ~= nil and #currentPath.choices ~= #targetPath.choices
	local choicesIsPassed = not needToDive
	local choicesIsReached = false

	local deepChoice = needToDive and targetPath.choices[#currentPath.choices + 1] or nil
	
	for index = deepChoice or 1, #items do
		local item = items[index]
		local itemIsChoice = item.type == enums.BLOCK_TYPE_CHOICE
		local deepChoiceIsWrong = deepChoice ~= nil and not itemIsChoice
		local choicesOver = choicesIsReached and not itemIsChoice

		canContinue = not deepChoiceIsWrong and not choicesOver
		if not canContinue then break end

		-- Go deep to the node
		if index == deepChoice then
			if item.node ~= nil then
				local choicePath = lume.clone(currentPath)
				choicePath.choices = lume.clone(currentPath.choices)
				table.insert(choicePath.choices, deepChoice)
				canContinue = self:readItems(item.node, targetPath, choicePath)
				if not canContinue then break end
			end
			deepChoice = nil
			choicesIsPassed = false
		end

		-- Just read the item
		if item.type == enums.BLOCK_TYPE_CHOICE and index ~= deepChoice and choicesIsPassed then
			choicesIsReached = true
			local choicePath = lume.clone(currentPath)
			choicePath.choices = lume.clone(currentPath.choices)
			table.insert(choicePath.choices, index)
			self:readChoice(item, choicePath)
			canContinue = index < #items
			if not canContinue then break end
		elseif item.type == enums.BLOCK_TYPE_TEXT then
			choicesIsPassed = true
			canContinue = self:readText(item)
			if not canContinue then break end
		end
	end

	return canContinue
end

function Story:readText(item)
	local text = item.text or item.gather
	local canContinue = true

	if text ~= nil then
		local paragraph = text
		local gluedByPrev = #self.paragraphs > 0 and self.paragraphs[#self.paragraphs]:sub(-2) == "<>"
		local gluedByThis = paragraph:sub(1, 2) == "<>"

		if gluedByPrev then
			local prevParagraph = self.paragraphs[#self.paragraphs]
			prevParagraph = prevParagraph:sub(1, #prevParagraph - 2)
			self.paragraphs[#self.paragraphs] = prevParagraph
		end

		if gluedByThis then
			paragraph = paragraph:sub(3)
		end

		if gluedByPrev or gluedByThis then
			local prevParagraph = self.paragraphs[#self.paragraphs]
			prevParagraph = prevParagraph .. paragraph
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

-- function Story:globalTags()
-- 	return self.model.globalTags
-- end

-- function Story:currentTags()
-- 	return self.currentTags
-- end

-- function Story:pathTags(path)
-- 	-- TODO: Return knot or stitch tags
-- 	return { "tag1" }
-- end


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