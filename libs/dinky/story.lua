--
-- Dependencies

local lume = require("lume")
local Object = require("classic")

--
-- Story

local Story = Object:extend()

function Story:new(model)
	self.model = model -- passive model of story
	self.visits = { } -- dictionary of visits [knot [stitch = 3]]
	self.variables = { } -- dictionary of variables (saved to state)
	self.constants = model.constants-- dictionary of constants (not saved to state)

	self.currentTags = { }
	self.choices = { } -- array of { title = 'title', text = 'text', path = 'knot.stitch:3.2' }
	self.pragraphs = { } -- array of 'text'

	self:process('_')
end

function Story:canContinue()
	return #self.pragraphs
end

function Story:continue(steps)
	if not self:canContiinue() then return nil end
	local steps = steps or #self.pragraphs

	local lines
	for _ = 1, steps do
		table.insert(lines, 1, self.pragraphs[i])
		table.remove(self.pragraphs, 1)
	end

	return lines
end

function Story:choices()
	if self:canContiinue() then return nil end
	return self.choices
end

function Story:choose(index)
	local choices = self:choices()
	local index = index or 1
	index = index > 0 and index or 1
	index = index <= #choices and index or #choices

	local choice = choices[index]
	self:process(choice.path)
	return choice.text
end

function Story:moveTo(path)
	self:process(path)
end

function Story:process(path)
	self.pragraphs = { }
	self.choices = { }

	local knot, stitch = string.match(path, '([%w_]+)%.([%w_]+):')
	local choicesChain = lume.split(string.match(path, ':(.+)'), '.')

	local knotNode = self.model.knots[knot]
	stitchNode = knotNode[stitch] or knotNode
	local node = stitchNode

	if #choicesChain then
		node = stitchNode[choiceIndex]
	end
	if #choicesChain > 1 then
		for index = 2, #choicesChain do
			node = node.node[index]
		end	
	end

	-- TODO	

	for block in node do
		if block.type == STORY_BLOCK_TYPES.text then

		elseif block.type == STORY_BLOCK_TYPES.gather then

		elseif block.type == STORY_BLOCK_TYPES.choice then

		elseif block.type == STORY_BLOCK_TYPES.condition then

		elseif block.type == STORY_BLOCK_TYPES.var then

		elseif block.type == STORY_BLOCK_TYPES.external then

		end
	end

	local noChoices = false
	-- if the end hasn't any choice -> get a gather from the parent level
	if noChoices then
		parentData = stitchData[3].node[4]
		-- if index++ is gather then do gather
		-- then go recursive to parent to looking foa a another gather
	end
	
end


-- Tags

function Story:globalTags()
	return self.model.globalTags
end

function Story:currentTags()
	return self.currentTags
end

function Story:pathTags(path)
	-- TODO: Return knot or stitch tags
	return { 'tag1' }
end


-- States

function Story:saveState()
	local state = {
		variables = self.variables,
		path = self.path,
		visits = self.visits
	}
	return state
end

function Story:loadState(state)
	-- TODO: Load state
end


-- Reactive

function Story:observe(variable, func)
	-- TODO: Observe variable changes and call the function
end

function Story:bind(name, func)
	-- TODO: Bind an external function to the Ink function call
end

return Story