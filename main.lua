--main.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--The main driver for the RL-Mega-Man-v2 project scripts

require "constants"
require "nn_vision"
require "fitness"
require "menu"
require "brain"
require "ga"
require "save_progress"
require "log"
require "inum_tracker"
require "display_brain"

-----SETUP-----
--set the rng seed to the current time, effectively randomising it
math.randomseed(os.time())
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

--create new genetic algorithm controller or load from file
ga = {}	--the name of this variable is not allowed to change since it is saved to a file
if fileExists(WORKING_FILE) then
	local tempObj = loadFromFile(WORKING_FILE)
	ga = GeneticAlgorithmController:new(tempObj.ga)
	specieCount = tempObj.specieCount
	connectionCount = tempObj.connectionCount
	nodeCount = tempObj.nodeCount
	emu.print("population loaded")
else
	ga = GeneticAlgorithmController:new()
	emu.print("new population created")
end

openLogFile(ga.generation)
logFile:write("Generation ", ga.generation, "\n\n")

-----MAIN PROGRAM LOOP----
local inControl = true
savestate.load(save)
local frameCounter = 1
local lastFitness = 0
local lastFitnessChange = 0
--loop once per frame
while true do
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
	--do neural network calculation for this frame
	local inputs = getRelativeInputValues()
	inputs[INPUT_NODES - 11] = -128
	inputs[INPUT_NODES - 10] = 127
	inputs[INPUT_NODES - 9] = ((frameCounter % 2) * 255) - 128
	inputs[INPUT_NODES - 8] = (frameCounter % 4 < 2) and 127 or -128
	inputs[INPUT_NODES - 7] = (frameCounter % 8 < 4) and 127 or -128
	inputs[INPUT_NODES - 6] = (frameCounter % 16 < 8) and 127 or -128
	inputs[INPUT_NODES - 5] = (frameCounter % 32 < 16) and 127 or -128
	inputs[INPUT_NODES - 4] = (frameCounter % 64 < 32) and 127 or -128
	inputs[INPUT_NODES - 3] = (frameCounter % 128 < 64) and 127 or -128
	inputs[INPUT_NODES - 2] = (frameCounter % 256 < 128) and 127 or -128
	inputs[INPUT_NODES - 1] = (frameCounter % 512 < 256) and 127 or -128
	inputs[INPUT_NODES] = (frameCounter % 1024 < 512) and 127 or -128
	local out = ga.passInputs(ga, inputs)
	
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
	local info = ga.getIndividualInfo(ga)
	gui.text(10, 209, "Generation " .. info[1] .. "; Species " .. info[2], "white", "black")
	gui.text(10, 218, "Individual " .. info[3] .. "; Fitness: " .. math.floor(checkFitness() + 0.5), "white", "black")
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
		
		ga.assignFitness(ga,fit)
		
		--prepare next brain
		--if no brains remain, create next generation
		if ga.nextBrain(ga) then
			ga.currentBrain = POPULATION_SIZE
			local tempObj = {ga=ga,specieCount=specieCount,connectionCount=connectionCount,nodeCount=nodeCount}
			saveObject(WORKING_FILE, tempObj)
			saveObject(HISTORY_FILE .. ga.generation .. HISTORY_FILE_EXT, tempObj)
			emu.print("population saved")
			ga.makeNextGeneration(ga)
			emu.print("next generation created")
			logFile:flush()
			logFile:close()
			openLogFile(ga.generation)
			logFile:write("Generation ", ga.generation, "\n\n")
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