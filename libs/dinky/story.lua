local localFolder = (...):match("(.-)[^%.]+$") or (...)
local Class = require(localFolder .. "classic")
local Story = Class:extend()

function Story:new(tree)
	self.tree = tree
	self.currentPath = nil
	self.visits = { }
	self.variables = { }
end

function Story:canContinue()
	-- TODO: Can we continue?
	return false
end

function Story:continue(pause)
	-- TODO: Continue with pause or not
	local pause = pause or true
	if pause then
		return "text [pause]"
	else 
		return "text text text"
	end
end

function Story:choices()
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

function Story:teleport(path)
	-- TODO: Go to the knot or the stitch
	self.path = path
end

function Story:visitsForPath(path)
	return self.visits[path]
end

function Story:globalTags()
	-- TODO: Return global tags
	return { "tag1" }
end

function Story:pathTags(path)
	-- TODO: Return knot or stitch tags
	return { "tag1" }
end

function Story:currentTags()
	-- TODO: Return current tags
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
	self.variables = state.variables
	self.teleport(state.path)
end

function Story:observe(variable, func)
	-- TODO: Observe variable changes and call the function
end

function Story:bind(name, func)
	-- TODO: Bind an external function to the Ink function call
end

return Story