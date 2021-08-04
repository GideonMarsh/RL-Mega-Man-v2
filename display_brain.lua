--display_brain.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--displays one of the neural networks as it is running

require "constants"

function drawBrain(nodes, connections)
	local nodePositions = {}
	local pixelsInRow = math.floor((SCREEN_X_MAX - SCREEN_X_MIN + 1) / X_OFFSET)
	pixelsInRow = pixelsInRow + 1
	for i in pairs(nodes) do
		nodePositions[i] = {}
		if i <= INPUT_NODES then
			nodePositions[i].x = (i - 1) % pixelsInRow
			nodePositions[i].y = math.floor((i - 1) / pixelsInRow) + SCREEN_Y_MIN
		elseif i > INPUT_NODES and i <= INPUT_NODES + OUTPUT_NODES then
			nodePositions[i].x = SCREEN_X_MAX - 10
			nodePositions[i].y = ((i - INPUT_NODES) * 11) - 6 + SCREEN_Y_MIN
		else
			nodePositions[i].x = SCREEN_X_MAX - 13--math.floor((SCREEN_X_MAX - 10 - pixelsInRow) / 2) + pixelsInRow
			nodePositions[i].y = 34 + SCREEN_Y_MIN
		end
	end
	for i in pairs(connections) do
		if i ~= "length" and connections[i].enabled then
			local c1 = nodePositions[connections[i].inNode]
			local c2 = nodePositions[connections[i].outNode]
			if connections[i].inNode > INPUT_NODES + OUTPUT_NODES then
				c1.x = 0.75 * c1.x + 0.25 * c2.x
				if c1.x >= c2.x then c1.x = c1.x - 30 end
				if c1.x < (pixelsInRow + 2) then c1.x = (pixelsInRow + 2) end
				if c1.x > (SCREEN_X_MAX - 13) then c1.x = (SCREEN_X_MAX - 13) end
				c1.y = 0.75 * c1.y + 0.25 * c2.y
			end
			if connections[i].outNode > INPUT_NODES + OUTPUT_NODES then
				c2.x = 0.25 * c1.x + 0.75 * c2.x
				if c1.x >= c2.x then c2.x = c2.x + 30 end
				if c2.x < (pixelsInRow + 2) then c2.x = (pixelsInRow + 2) end
				if c2.x > (SCREEN_X_MAX - 13) then c2.x = (SCREEN_X_MAX - 13) end
				c2.y = 0.25 * c1.y + 0.75 * c2.y
			end
		end
	end
	gui.box(0,8,255,82,{200,200,200,64},{200,200,200,64})
	for i=1,INPUT_NODES do
		local color = math.floor(nodes[i])
		if color > 0 then 
			color = color * 2
			gui.pixel(nodePositions[i].x, nodePositions[i].y, {0,color,0,180})
		else
			color = (-2 * color) - 1
			gui.pixel(nodePositions[i].x, nodePositions[i].y, {color,0,0,180})
		end
	end
	for i in pairs(connections) do
		if i ~= "length" and connections[i].enabled and connections[i].weight ~= 0 then
			local inN = nodePositions[connections[i].inNode]
			local outN = nodePositions[connections[i].outNode]
			--local color = math.floor(connections[i].weight * 100)
			if connections[i].weight > 0 then
				gui.line(inN.x,inN.y,outN.x,outN.y,{0,0,255,180},(connections[i].inNode < INPUT_NODES))
			else
				gui.line(inN.x,inN.y,outN.x,outN.y,{0,0,0,180},(connections[i].inNode < INPUT_NODES))
			end
		end
	end
	for i in pairs(nodePositions) do
		if i > INPUT_NODES then
			local color = math.floor(nodes[i])
			if color > 0 then 
				color = color * 2
				gui.box(nodePositions[i].x - 1, nodePositions[i].y - 1, nodePositions[i].x + 1, nodePositions[i].y + 1, {0,color,0,180})
			else
				color = (-2 * color) - 1
				gui.box(nodePositions[i].x - 1, nodePositions[i].y - 1, nodePositions[i].x + 1, nodePositions[i].y + 1, {color,0,0,180})
			end
		end
	end
end