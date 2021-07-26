--fitness.lua
--created by Gideon Marsh

--calculates the fitness of the current player

require "constants"

fitness = 0

function returnFitness()
	local f = fitness
	fitness = 0
	return f
end

function setFitness()
	local f = findFitness()
	if f > fitness then fitness = f end
end

function findFitness()
	local stage = memory.readbyte(CURRENT_STAGE)
	local screen = memory.readbyte(CURRENT_SCREEN)
	if stage == 1 then
		--Air Man's stage
		if screen == 10 then
			--midway room
			local mx = memory.readbyte(PLAYER_X)
			return (screen * 255) + (255 - mx)
		elseif screen == 21 then
			--boss room
			local bhp = memory.readbyte(BOSS_HP)
			return (screen * 255) + ((28 - bhp) * 10)
		else
			--either of the scrolling rooms, or boss hallway
			local mx = memory.readbyte(PLAYER_X)
			return (screen * 255) + mx
		end
	end
	return 0
end