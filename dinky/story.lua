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
	self.choices = { } -- array of { title = "title", text = "text", path = "knot.stitch:3.2" }
	self.paragraphs = { } -- array of "text"

	self:read("_")
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
	-- assert(choice, "Choice index " .. index .. " out of bounds 1-" .. #self.choices)
	
	self.paragraphs = { }
	self.choices = { }

	table.insert(self.paragraphs, choice.text)
	self:read(choice.path)
end

function Story:read(path)
	assert(path, "Path can't be nil")
	
	local path = path
	if path == "END" or path == "DONE" then return end

	local pathRoute = path:match("([%w_.]+):*")
	local choiceRoute = path:match(":([%w_.]+)")
	local knot, stitch = pathRoute:match("([%w_]+)%.([%w_]+)"); knot = knot or pathRoute
	local choicesChain = choiceRoute ~= nil and lume.split(choiceRoute, ".") or nil
	choicesChain = choicesChain ~= nil and lume.map(choicesChain, function(x) return tonumber(x) end) or nil

	-- Read a path node
	local knotNode = self.model.knots[knot]
	assert(knotNode, "The knot '" .. knot .. "' not found")
	local stitchNode = stitch ~= nil and knotNode[stitch] or nil
	local currentNode = stitchNode or knotNode

	if choicesChain == nil then
		return self:readItems(currentNode, path)
	end

	-- Read a choice node
	local choiceNodes = { currentNode }
	local choiceItem = currentNode[choicesChain[1]]
	
	for index = 2, #choicesChain do
		table.insert(choiceNodes, choiceItem.node)
		choiceItem = choiceItem.node[choicesChain[index]]
	end

	if choiceItem.node ~= nil then
		return self:readItems(choiceItem.node, path)
	end

	-- Read gathers
	-- Вот это все надо бы вынести в отдельную функцию, которую можно было вызывывать как отсюда, так и из readItems()
	local gathers = { }
	local choicesReached = false
	local indexShift = 0
	
	for i = #choiceNodes, 1, -1 do
		if choicesReached then break end

		local choiceNode = choiceNodes[i]
		local choiceIndex = choicesChain[i]
		local slicedNode = lume.slice(choiceNode, choiceIndex + 1)
		local choicesPassed = false
		indexShift = choiceIndex

		for j, item in pairs(slicedNode) do
			if not choicesPassed then
				if item.type == enums.BLOCK_TYPE_CHOICE then
					indexShift = indexShift + 1
				else
					table.insert(gathers, item)
					choicesPassed = true
				end
			elseif choicesPassed and not choicesReached then
				table.insert(gathers, item)
				choicesReached = item.type == enums.BLOCK_TYPE_CHOICE
			elseif choicesPassed and choicesReached then
				if item.type == enums.BLOCK_TYPE_CHOICE then
					table.insert(gathers, item)
				else
					break
				end
			end
		end

		path = path:sub(1, #path - #("." .. tostring(choiceIndex)))
	end

	if #gathers > 0 then
		return self:readItems(gathers, path, indexShift)
	end
end

function Story:readItems(items, path, shift)
	assert(items, "Items can't be nil")

	local diverted = false
	local choicesReached = false

	for index, item in ipairs(items) do
		local isChoice = item.type == enums.BLOCK_TYPE_CHOICE
		if diverted or (choicesReached and not isChoice) then
			break
		end

		if item.type == enums.BLOCK_TYPE_TEXT then
			self:readText(item)
			diverted = item.divert ~= nil
		-- elseif item.type == enums.BLOCK_TYPE_CONDITION then
			-- self:readCondition(item)
		-- elseif item.type == enums.BLOCK_TYPE_EXPRESSION then
			-- self:readExpression(item)
		-- elseif item.type == enums.BLOCK_TYPE_FUNCTION then
			-- self:readFunction(item)
		elseif item.type == enums.BLOCK_TYPE_CHOICE then
			local separator = path:match(":.+") and "." or ":"
			local choiceIndex = index + (shift or 0)
			local choicePath = path .. separator .. choiceIndex
			self:readChoice(item, choicePath)
			choicesReached = true
		end
	end

	if not choicesReached then
		-- gathers?
		-- Чтение gathers возможно как после выбора, так и внутри ноды с айтемами когда они заканчиваются внутри результата выбора.
		-- Предлагаю создать функцию чтения items с указанием начального индекса, чтобы читать gathers после текущей ноды выбора
	end
end

function Story:readText(item)
	local text = item.text or item.gather

	if text ~= nil then
		local paragraph = text
		local gluedByPrev = #self.paragraphs > 0 and self.paragraphs[#self.paragraphs]:sub(-2) == "<>"
		local gluedByThis = paragraph:sub(1, 2) == "<>"

		if gluedByPrev then
			local prevParagraph = self.paragraphs[#self.paragraphs]
			prevParagraph = prevParagraph:sub(1, #paragraph - 2)
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
	end
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