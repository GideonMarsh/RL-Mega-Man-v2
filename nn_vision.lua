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

--Display what the program sees, for testing purposes
function testVision()
	for i = SCREEN_Y_MIN + Y_SHIFT, SCREEN_Y_MAX, Y_OFFSET do
		for j = SCREEN_X_MIN, SCREEN_X_MAX, X_OFFSET do
			local r, g, b, p = emu.getscreenpixel(j, i, true)
			local g = math.floor((r + g + b) / 3)
			gui.pixel(math.floor(j / X_OFFSET), math.floor(i / Y_OFFSET) + 8, {g,g,g})
		end
	end
end