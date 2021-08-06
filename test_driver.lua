
require "constants"
require "menu"
require "brain"
require "display_brain"
require "save_progress"
require "nn_vision"
require "fitness"

SPECIES_TO_TRACK = 218
TRACK_SUBSPECIES = true

--restart game and navigate to stage select
emu.poweron()
menuWait(20)
menuStart()
menuDown()
menuStart()
menuWait(135)
menuStart()
menuWait(10)
--select Metal Man first
menuDown()
menuLeft()
menuStart()
--wait until game is playable
while memory.readbyte(0x01FE) ~= STATE_PLAYING do
	emu.frameadvance()
end
--create save state 
save = savestate.object()
savestate.save(save)
emu.print("save state created")

local genCounter = 0
local genWatch = {[SPECIES_TO_TRACK] = true}
local moreToWatch = true
local pop = {count = 0}

repeat
	genCounter = genCounter + 1
	if fileExists(HISTORY_FILE .. genCounter .. HISTORY_FILE_EXT) then
		local tempObj = loadFromFile(HISTORY_FILE .. genCounter .. HISTORY_FILE_EXT)
		for i,v in ipairs(tempObj.ga.population) do
			if genWatch[v.species] then
				pop.count = pop.count + 1
				pop[pop.count] = Brain:new(v)
			end
		end
		emu.print("population loaded")
	else
		moreToWatch = false
	end
until pop.count ~= 0

savestate.load(save)

local currentPop = 1
doDraw = true
inControl = true
local frameCounter = 1
local lastFitness = 0
local lastFitnessChange = 0

while moreToWatch do
	if input.get()["space"] then
		if inControl then
			if drawDisabled and doDraw then
				drawDisabled = false
			elseif doDraw then
				doDraw = false
			else
				doDraw = true
				drawDisabled = true
			end
			inControl = false
		end
	else
		inControl = true
	end
	
	----Code for testing distance----
	--local stage = memory.readbyte(CURRENT_STAGE)
	--local screen = memory.readbyte(CURRENT_SCREEN)
	--local mx = memory.readbyte(PLAYER_X)
	--local my = memory.readbyte(PLAYER_Y)
	--gui.text(211, 218, frameCounter, "white", "black")
	--gui.text(10, 209, "Stage " .. stage .. "; Screen " .. screen, "white", "black")
	--gui.text(10, 218, "X " .. mx .. "; Y " .. my, "white", "black")

	
	--local val = memory.readbyte(GAME_STATE)
	--if (val == STATE_LEVEL_COMPLETE) then 
	--	emu.print(frameCounter)
	--	break
	--end
	--if (val == STATE_RESPAWNING) or 
	--	(frameCounter == TOTAL_FRAME_TIMEOUT) then
	--	
		--reset run
	--	savestate.load(save)
	--	frameCounter = 1
	--else
		--advance to next frame
	--	frameCounter = frameCounter + 1
	--	emu.frameadvance()
	--end
	----end of block----
	
	--do neural network calculation for this frame
	local out = pop[currentPop].think(pop[currentPop], getInputValues())
	
	--set player controls according to output of calculation
	joypad.set(1, {["up"]=(out[1] > 0),["down"]=(out[2] > 0),
					["left"]=(out[3] > 0),["right"]=(out[4] > 0),
					["A"]=(out[5] > 0),["B"]=(out[6] > 0)})
					
	--set fitness as of this frame
	setFitness(frameCounter)
	
	if checkFitness() ~= lastFitness then
		lastFitnessChange = frameCounter
		lastFitness = checkFitness()
	end
	
	--show information on screen
	if not doDraw then
		local outString = ""
		for i=1,6 do
			if out[i] > 0 then
				outString = outString .. "on "
			else
				outString = outString .. "off "
			end
		end
		if out[7] < -100 then
			outString = outString .. "Atomic Fire"
		elseif out[7] < -80 then
			outString = outString .. "Air Shooter"
		elseif out[7] < -60 then
			outString = outString .. "Leaf Shield"
		elseif out[7] < -40 then
			outString = outString .. "Bubble Lead"
		elseif out[7] < -20 then
			outString = outString .. "Quick Boomerang"
		elseif out[7] < 0 then
			outString = outString .. "Time Stopper"
		elseif out[7] > 100 then
			outString = outString .. "Metal Blade"
		elseif out[7] > 80 then
			outString = outString .. "Crash Bomb"
		elseif out[7] > 60 then
			outString = outString .. "Item 1"
		elseif out[7] > 40 then
			outString = outString .. "Item 2"
		elseif out[7] > 20 then
			outString = outString .. "Item 3"
		else
			outString = outString .. "Mega Buster"
		end

		gui.text(10, 12, outString, "white", "black")
	end
	gui.text(10, 209, "Generation " .. genCounter .. "; Species " .. pop[currentPop].species, "white", "black")
	gui.text(10, 218, "Individual " .. currentPop .. "(" .. pop.count .. "); Fitness: " .. math.floor(checkFitness() + 0.5), "white", "black")
	gui.text(211, 218, frameCounter, "white", "black")
	gui.text(211, 209, NO_PROGRESS_TIMEOUT - (frameCounter - lastFitnessChange), "white", "black")
	
	--check to see if current run is over
	--run ends if any of these conditions are true:
	--player died
	--one second has passed since starting, and no progress was made
	--thirty seconds has passed without any progress
	--ten minutes have passed since starting
	local val = memory.readbyte(GAME_STATE)
	if (val == STATE_LEVEL_COMPLETE) then 
		--WIP
	end
	if (val == STATE_RESPAWNING) or 
		(frameCounter == TOTAL_FRAME_TIMEOUT) or 
		(frameCounter - lastFitnessChange == NO_PROGRESS_TIMEOUT) or 
		(frameCounter == QUICK_TIMEOUT and lastFitnessChange <= 1) then
		--assign final fitness to current brain
		local fit = returnFitness()
		--if val == STATE_RESPAWNING then
		--	emu.print("Player died; fitness = " .. fit)
		--end
		--if frameCounter == TOTAL_FRAME_TIMEOUT then
		--	emu.print("Out of time; fitness = " .. fit)
		--end
		--if frameCounter - lastFitnessChange == NO_PROGRESS_TIMEOUT then
		--	emu.print("Stopped progressing; fitness = " .. fit)
		--end
		--if frameCounter == QUICK_TIMEOUT and lastFitnessChange <= 1 then
		--	emu.print("No progress at start; fitness = " .. fit)
		--end
		
		--prepare next brain
		currentPop = currentPop + 1
		if currentPop > pop.count then
			if TRACK_SUBSPECIES then
				--find subspecies of all watched species
				if fileExists(LOG_FILE .. genCounter .. LOG_FILE_EXT) then
					io.input(LOG_FILE .. genCounter .. LOG_FILE_EXT)
					local inLine = io.read("*line")
					for i in pairs(genWatch) do
						local startStr = "Species: " .. i .. " creates subspecies "
						while inLine do
							if string.sub(inLine,1,#startStr) == startStr then
								genWatch[tonumber(string.sub(inLine,#startStr + 1, #inLine))] = true
								emu.print("added " .. tonumber(string.sub(inLine,#startStr + 1, #inLine)) .. " to species watch list")
							end
							inLine = io.read("*line")
						end
					end
				end
			end
			
			repeat
				genCounter = genCounter + 1
				
				pop = {count = 0}
				if fileExists(HISTORY_FILE .. genCounter .. HISTORY_FILE_EXT) then
					local tempObj = loadFromFile(HISTORY_FILE .. genCounter .. HISTORY_FILE_EXT)
					for i,v in ipairs(tempObj.ga.population) do
						if genWatch[v.species] then
							pop.count = pop.count + 1
							pop[pop.count] = Brain:new(v)
						end
					end
					emu.print("population loaded")
				else
					moreToWatch = false
				end
			until pop.count ~= 0
			
			currentPop = 1
		end
		
		--reset run
		savestate.load(save)
		frameCounter = 1
		lastFitness = 0
		lastFitnessChange = 0
	else
		--advance to next frame
		frameCounter = frameCounter + 1
		emu.frameadvance()
	end
end

emu.print("end of logs")