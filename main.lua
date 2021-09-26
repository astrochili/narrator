--[[
Example of using Narrator with love game framework
- @flamendless
tested to work with love version 11.3 (or higher may also work out of the box)
Please let the author know if other versions work fine
--]]

local love = require("love")
assert(love ~= nil, "love must be installed. See https://love2d.org")

local major, minor = love.getVersion()
if major ~= 11 and minor ~= 3 then
	print("This demo might not work with love version not 11.3")
end

local narrator = require("narrator.narrator")
local book, story
local font = love.graphics.newFont(14)
local ww, wh = love.graphics.getDimensions()
local outer_gap, inner_gap = 32, 8
local cur_text = ""
local cur_choices = {}
local widest
local current_choice = 1

local function proceed()
	if not story:canContinue() then return end

	local paragraphs = story:continue()
	for _, p in ipairs(paragraphs) do
		if p.tags then
			cur_text = cur_text .. " #" .. table.concat(p.tags, " #")
		end
		cur_text = p.text
	end
	widest = cur_text
	current_choice = 1

 	if not story:canChoose() then
 		choices = {}
		current_choice = 0
		return
	end

	choices = story:getChoices()
	for i, choice in ipairs(choices) do
		if #widest < #choice.text then
			widest = choice.text
		end
	end
end

function love.load()
	book = narrator.parseFile("stories.game")
	story = narrator.initStory(book)
	story:begin()
	proceed()
end

function love.draw()
	love.graphics.setFont(font)

	local rw = font:getWidth(widest) + outer_gap * 2
	local rh = font:getHeight(" ") + outer_gap * 2
	local rx = ww * 0.5 - rw * 0.5
	local ry = wh * 0.5 - rh * 0.5

	rw = #choices ~= 0 and rw + font:getWidth("> ") or rw
	rh = rh + font:getHeight(" ") * #choices

	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.rectangle("fill", rx, ry, rw, rh)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill",
		rx + inner_gap, ry + inner_gap,
		rw - inner_gap * 2, rh - inner_gap * 2)

	local tx = rx + outer_gap
	local ty = ry + outer_gap
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.print(cur_text, tx, ty)

	for i, choice in ipairs(choices) do
		cx = tx + inner_gap * 2
		cy = ty + inner_gap * 2 * i

		if current_choice == i then
			love.graphics.print("> ", tx, cy)
			love.graphics.setColor(1, 0, 0, 1)
		else
			love.graphics.setColor(0, 0, 0, 1)
		end

		love.graphics.print(choice.text, cx, cy)
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("Controls:", 32, 32)
	love.graphics.print("R - restart", 32, 48)
	love.graphics.print("Up, Down - navigate choices", 32, 64)
	love.graphics.print("Enter/Space - proceed", 32, 80)
end

function love.keypressed(key)
	if key == "r" then
		love.event.quit("restart")
	elseif key == "up" then
		current_choice = current_choice - 1
	elseif key == "down" then
		current_choice = current_choice + 1
	elseif key == "return" or key == "space" then
		if #choices ~= 0 then
			story:choose(current_choice)
		end
		if story:canContinue() then
			proceed()
		else
			cur_text = "THE END"
		end
	end

	if current_choice > #choices then
		current_choice = 1
	elseif current_choice <= 0 then
		current_choice = #choices
	end
end
