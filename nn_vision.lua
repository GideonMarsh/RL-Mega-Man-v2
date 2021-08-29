--nn_vision.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--script for reading pixels on screen
--reads the pixels one row at a time, left to right (like words in a book)
--averages the three rgb values of each pixel together to create an approximate "grayscale" float value
--returns a table of these grayscale values

require "constants"

function getInputValues()
	local values = {}
	local count = 1
	for i = SCREEN_Y_MIN + Y_SHIFT, SCREEN_Y_MAX, Y_OFFSET do
		for j = SCREEN_X_MIN, SCREEN_X_MAX, X_OFFSET do
			local r, g, b, p = emu.getscreenpixel(j, i, true)
			values[count] = ((r + g + b) / 3) - 128
			count = count + 1
		end
	end
	return values
end

function getRelativeInputValues()
	local xpos = memory.readbyte(PLAYER_SCREEN_X)
	local ypos = memory.readbyte(PLAYER_Y)
	local values = {}
	local count = 1
	for i = SCREEN_Y_MIN, SCREEN_Y_MAX, Y_OFFSET do
		for j = SCREEN_X_MIN, SCREEN_X_MAX, X_OFFSET do
			local x = j + xpos - ((SCREEN_X_MAX - SCREEN_X_MIN)/ 2)
			local y = i + ypos - ((SCREEN_Y_MAX - SCREEN_Y_MIN) / 2)
			if x < SCREEN_X_MIN or x > SCREEN_X_MAX or y < SCREEN_Y_MIN or y > SCREEN_Y_MAX then
				values[count] = 0
			else
				local r, g, b, p = emu.getscreenpixel(x, y, true)
				values[count] = ((r + g + b) / 3) - 128
			end
			count = count + 1
		end
	end
	return values
end

--Display what the program sees, for testing purposes
function testVision()
	--[[for i = SCREEN_Y_MIN + Y_SHIFT, SCREEN_Y_MAX, Y_OFFSET do
		for j = SCREEN_X_MIN, SCREEN_X_MAX, X_OFFSET do
			local r, g, b, p = emu.getscreenpixel(j, i, true)
			local g = math.floor((r + g + b) / 3)
			gui.pixel(math.floor(j / X_OFFSET), math.floor(i / Y_OFFSET) + 8, {g,g,g})
		end
	end]]--
	local xpos = memory.readbyte(PLAYER_SCREEN_X)
	local ypos = memory.readbyte(PLAYER_Y)
	for i = SCREEN_Y_MIN, SCREEN_Y_MAX, Y_OFFSET do
		for j = SCREEN_X_MIN, SCREEN_X_MAX, X_OFFSET do
			local x = j + xpos - ((SCREEN_X_MAX - SCREEN_X_MIN)/ 2)
			local y = i + ypos - ((SCREEN_Y_MAX - SCREEN_Y_MIN) / 2)
			local l = 0
			if x < SCREEN_X_MIN or x > SCREEN_X_MAX or y < SCREEN_Y_MIN or y > SCREEN_Y_MAX then
				l = 0
			else
				local r, g, b, p = emu.getscreenpixel(x, y, true)
				l = math.floor((r + g + b) / 3)
			end
			gui.pixel(math.floor(j / X_OFFSET), math.floor(i / Y_OFFSET) + 8, {l,l,l})
		end
	end
	return values
end