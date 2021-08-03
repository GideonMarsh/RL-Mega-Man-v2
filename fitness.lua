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
function setFitness(framesElapsed)
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
	elseif stage == 6 then
		--Metal Man's stage
		if screen == 1 then
			--first screen with overhang
			local mx = memory.readbyte(PLAYER_X)
			local my = memory.readbyte(PLAYER_Y)
			if mx > 160 then
				pixelProgress = (screen * 255) + mx - math.abs(110 - my)
			else
				pixelProgress = (screen * 255) + mx
			end
		elseif screen == 9 then
			--second screen with overhang
			local mx = memory.readbyte(PLAYER_X)
			local my = memory.readbyte(PLAYER_Y)
			if my < 100 then
				pixelProgress = (screen * 255) + mx - (100 - my)
			else
				pixelProgress = (screen * 255) + mx
			end
		elseif screen == 10 then
			--midway room
			local mx = memory.readbyte(PLAYER_X)
			pixelProgress = (screen * 255) + (255 - mx)
		elseif screen == 21 then
			--boss room
			local bhp = memory.readbyte(BOSS_HP)
			pixelProgress = (screen * 255) + ((28 - bhp) * 10)
		else
			--everywhere else
			local mx = memory.readbyte(PLAYER_X)
			pixelProgress = (screen * 255) + mx
		end
	end
	pixelProgress = pixelProgress - FITNESS_OFFSET
	if pixelProgress > furthest then
		--each pixel of progress is worth 1, which is split up as follows:
		--40% is earned no matter what
		--50% is based on the player's remaining hp
		--10% is based on the time remaining
		local addFit = (pixelProgress - furthest) * (0.4 + (0.5 * (hp/MAX_HP)) + (0.1 * (1 - (framesElapsed / TOTAL_FRAME_TIMEOUT))))
		furthest = pixelProgress
		fitness = fitness + addFit
	end
end