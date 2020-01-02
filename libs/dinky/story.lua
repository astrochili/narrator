require("utils")
local localFolder = (...):match("(.-)[^%.]+$") or (...)
local Class = require(localFolder .. "classic")
local Story = Class:extend()

function Story:new(model)
	self.model = model -- passive model of story
	self.visits = { } -- dictionary of visits [knot.stitch = 3]
	self.variables = { } -- dictionary of variables and constants

	self.currentPath = "_"
	self.currentTags = { }
	self.choices = { } -- array of { title = "title", text = "text", path = "knot.stitch:3.2" }
	self.queue = { } -- array of "text"

	self:process(self.currentPath)
end

function Story:canContinue()
	return #self.queue
end

function Story:continue(steps)
	if not self:canContiinue() then return end
	local steps = steps or #self.queue

	local lines
	for _ = 1, steps do
		table.insert(lines, 1, self.queue[i])
		table.remove(self.queue, 1)
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
	self.currentPath = path
	self:process(path)
end

function Story:process(path)
	self.queue = { }
	self.choices = { }
	-- TODO
end


-- Tags

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