local localFolder = (...):match("(.-)[^%.]+$") or (...)
local Class = require(localFolder .. "classic")
local Story = Class:extend()

function Story:new(model)
	self.model = model
	self.currentPath = nil
	self.visits = { }
	self.variables = { }
	self.queue = { }
end

function Story:canContinue()
	return #self.queue
end

function Story:continue(byStep)
	if not self:canContiinue() then return end
	local step = byStep or true

	local text
	if step then
		text = self.queue[1]
		table.remove(self.queue, 1)
	else
		-- TODO: вернуть всю очередь с переносами 
		text = "paragraph\nparagraph\nparagraph"
		for i, _ in pairs(self.queue) do self.queue[i] = nil end
	end

	return text
end

function Story:choices()
	if self:canContiinue() then return nil end
	-- TODO: Return current choices
	local choice1 = { title = "Choice 1", text = "Choice 1 full" }
	local choice2 = { title = "Choice 2", text = "Choice 2 full" }
	return { choice1, choice2 }
end

function Story:choose(index)
	-- TODO: Make a choice
	local choices = self:choices()
	local index = index or 1
	index = (index <= #choices and index > 0) and index or 1

	local text = choices[index].text
	return text
end

function Story:moveTo(path)
	-- TODO: Go to the knot or the stitch
end

function Story:globalTags()
	return self.model.globalTags
end

function Story:currentTags()
	return self:pathTags(self.currentPath)
end

function Story:pathTags(path)
	-- TODO: Return knot or stitch tags
	return { "tag1" }
end

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

function Story:observe(variable, func)
	-- TODO: Observe variable changes and call the function
end

function Story:bind(name, func)
	-- TODO: Bind an external function to the Ink function call
end

return Story