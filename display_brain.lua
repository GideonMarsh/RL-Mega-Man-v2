--display_brain.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--displays one of the neural networks as it is running

require "constants"

function drawBrain(nodes)
	local pixelsInRow = math.floor((SCREEN_X_MAX - SCREEN_X_MIN + 1) / X_OFFSET)
	pixelsInRow = pixelsInRow + 1
	for i in pairs(nodes) do
		if i <= INPUT_NODES then
			local x = (i - 1) % pixelsInRow
			local y = math.floor((i - 1) / pixelsInRow) + SCREEN_Y_MIN
			local color = math.floor(nodes[i])
			if color > 0 then 
				color = color * 2
				gui.pixel(x, y, {0,color,0})
			else
				color = (-2 * color) - 1
				gui.pixel(x, y, {color,0,0})
			end
		end
	end
end