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

	self:read(choice.path)
	return choice.text
end

function Story:read(path)
	assert(path, "Path can't be nil")
	
	if path == "END" or path == "DONE" then return end

	local pathRoute = path:match("([%w_.]+):*")
	local choiceRoute = path:match(":([%w_.]+)")
	local knot, stitch = pathRoute:match("([%w_]+)%.([%w_]+)"); knot = knot or pathRoute
	local choicesChain = choiceRoute ~= nil and lume.split(choiceRoute, ".") or nil
	choicesChain = choicesChain ~= nil and lume.map(choicesChain, function(x) return tonumber(x) end) or nil

	local knotNode = self.model.knots[knot]
	assert(knotNode, "The knot '" .. knot .. "' not found")
	local stitchNode = stitch ~= nil and knotNode[stitch] or nil
	local items = stitchNode or knotNode

	if choicesChain ~= nil and #choicesChain then
		local choiceItem = items[choicesChain[1]]
		for index = 2, #choicesChain do
			choiceItem = choiceItem.node[index]
		end	
		if choiceItem.divert ~= nil then
			self:read(choiceItem.divert)
		else
			self:readItems(choiceItem.node, path)
		end
	else
		self:readItems(items, path)
	end

	-- local noChoices = false
	-- if the end hasn"t any choice -> get a gather from the parent level
	-- if noChoices then
	-- 	parentData = stitchData[3].node[4]
		-- if index++ is gather then do gather
		-- then go recursive to parent to looking foa a another gather
	-- end
end

function Story:readItems(items, path)
	assert(items, "Items can't be nil")

	for index, item in ipairs(items) do
		local separator = path:match(":.+") and "." or ":"
		local route = path .. separator .. index

		if item.type == enums.BLOCK_TYPE_TEXT then
			self:readText(item, route)
		elseif item.type == enums.BLOCK_TYPE_CHOICE then
			self:readChoice(item, route)
		-- elseif item.type == enums.BLOCK_TYPE_CONDITION then
			-- self:readCondition(item)
		-- elseif item.type == enums.BLOCK_TYPE_EXPRESSION then
			-- self:readExpression(item)
		-- elseif item.type == enums.BLOCK_TYPE_FUNCTION then
			-- self:readFunction(item)
		end
	end
end

function Story:readText(item, path)
	if item.text ~= nil then
		local paragraph = item.text
		local gluedByPrev = self.paragraphs[#self.paragraphs] == "<>"
		local gluedByThis = paragraph:sub(1, 2) == "<>"
		local glueNext = paragraph:sub(-2) == "<>"

		if gluedByPrev then
			table.remove(self.paragraphs, #self.paragraphs)
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
		
		if glueNext then
			local prevParagraph = self.paragraphs[#self.paragraphs]
			prevParagraph = prevParagraph:sub(1, #paragraph - 2)
			self.paragraphs[#self.paragraphs] = prevParagraph
			table.insert(self.paragraphs, #self.paragraphs + 1, "<>")
		end
	end
	
	if item.divert ~= nil then
		self:read(item.divert)
	end
end

function Story:readChoice(item, path)
	local choice = {
		title = item.choice,
		text = #item.text > 0 and item.text or nil,
		path = path
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