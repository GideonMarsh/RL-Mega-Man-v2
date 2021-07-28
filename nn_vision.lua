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
	for i = SCREEN_Y_MIN, SCREEN_Y_MAX do
		for j = SCREEN_X_MIN, SCREEN_X_MAX do
			local r, g, b, p = emu.getscreenpixel(j, i, true)
			values[count] = ((r + g + b) / 3) - 128
			count = count + 1
		end
	end
	return values
end