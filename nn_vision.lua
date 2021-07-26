--nn_vision.lua
--created by Gideon Marsh

--script for reading pixels on screen
--reads the pixels one row at a time, left to right
--averages the three rgb values of each pixel together to create an approximate "grayscale" float value
--returns a table of these grayscale values

require "constants"

function getInputValues()
	values = {}
	count = 1
	for i = screenyMin, screenyMax do
		for j = screenxMin, screenxMax do
			r, g, b, p = emu.getscreenpixel(j, i, true)
			values[count] = ((r + g + b) / 3)
			count = count + 1
		end
	end
	return values
end