--fitness.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--calculates the fitness of the current player

require "constants"

fitness = 0
furthest = 0

--perform final operations on fitness, return the stored fitness value, and reset it to 0
function returnFitness()
	local f = fitness
	fitness = 0
	furthest = 0
	if f == 0 then return 0.001 end
	return FITNESS_BASE ^ (f  / FITNESS_MODIFIER)
end

--return the stored fitness value (unmodified)
function checkFitness()
	return fitness
end

--return the modified fitness value
function checkModFitness()
	return FITNESS_BASE ^ (fitness  / FITNESS_MODIFIER) 
end

--find and increment the current fitness value based on the game state
function setFitness()
	local stage = memory.readbyte(CURRENT_STAGE)
	local screen = memory.readbyte(CURRENT_SCREEN)
	local hp = memory.readbyte(PLAYER_HP)
	local pixelProgress = 0
	if stage == 1 then
		--Air Man's stage
		if screen == 10 then
			--midway room
			local mx = memory.readbyte(PLAYER_X)
			pixelProgress = (screen * 255) + (255 - mx)
		elseif screen == 21 then
			--boss room
			local bhp = memory.readbyte(BOSS_HP)
			pixelProgress = (screen * 255) + ((28 - bhp) * 10)
		else
			--either of the scrolling rooms, or boss hallway
			local mx = memory.readbyte(PLAYER_X)
			pixelProgress = (screen * 255) + mx
		end
	end
	pixelProgress = pixelProgress - FITNESS_OFFSET
	if pixelProgress > furthest then
		--each pixel of progress is worth (current hp + 28) / 56
		local addFit = (pixelProgress - furthest) * ((hp + MAX_HP)/(MAX_HP * 2))
		furthest = pixelProgress
		fitness = fitness + addFit
	end
end