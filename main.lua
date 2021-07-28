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

-----SETUP-----
--restart game and navigate to stage select
emu.poweron()
menuWait(20)
menuStart()
menuDown()
menuStart()
menuWait(135)
menuStart()
menuWait(10)
--select Air Man first
menuUp()
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
gaFile = "saves/recent.txt"
spFile = "saves/recent_species.txt"
ga = {}	--the name of this variable is not allowed to change since it is saved to a file
if fileExists(gaFile) and fileExists(spFile) then
	ga = GeneticAlgorithmController:new(loadFromFile(gaFile))
	emu.print("population loaded")
	species = loadFromFile(spFile)
	reinstantiateSpecies()
	emu.print("species list loaded")
	emu.print(species[90].connections[18609].weight)
else
	ga = GeneticAlgorithmController:new()
	emu.print("new population created")
	saveObject(gaFile, ga)
	emu.print("population saved")
	saveObject(spFile, species)
	emu.print("species list saved")
end

-----MAIN PROGRAM LOOP----
savestate.load(save)
local frameCounter = 1
local lastFitness = 0
local lastFitnessChange = 0
--loop once per frame
while true do
	--do neural network calculation for this frame
	local out = ga.passInputs(ga, getInputValues())
	
	--set player controls according to output of calculation
	joypad.set(1, {["up"]=(out[1] > 0),["down"]=(out[2] > 0),
					["left"]=(out[3] > 0),["right"]=(out[4] > 0),
					["A"]=(out[5] > 0),["B"]=(out[6] > 0)})
					
	--set fitness as of this frame
	setFitness()
	
	if checkFitness() ~= lastFitness then
		lastFitnessChange = frameCounter
		lastFitness = checkFitness()
	end
	
	--show information on screen
	local outString = ""
	for i=1,6 do
		if out[i] > 0 then
			outString = outString .. "on "
		else
			outString = outString .. "off "
		end
	end
	
	gui.text(10, 12, outString, "white", "black")
	gui.text(10, 209, ga.getIndividualInfo(ga), "white", "black")
	gui.text(10, 218, "Fitness: " .. checkFitness(), "white", "black")
	gui.text(211, 218, frameCounter, "white", "black")
	gui.text(211, 209, NO_PROGRESS_TIMEOUT - (frameCounter - lastFitnessChange), "white", "black")
	
	--check to see if current run is over
	--run ends if any of these conditions are true:
	--player died
	--one second has passed since starting, and no progress was made
	--thirty seconds has passed without any progress
	--ten minutes have passed since starting
	local val = memory.readbyte(0x01FE)
	if (val == 195) or 
		(frameCounter == TOTAL_FRAME_TIMEOUT) or 
		(frameCounter - lastFitnessChange == NO_PROGRESS_TIMEOUT) or 
		(frameCounter == QUICK_TIMEOUT and lastFitnessChange == 1) then
		--assign final fitness to current brain
		local fit = returnFitness()
		if val == 195 then
			emu.print("Player died; fitness = " .. fit)
		end
		if frameCounter == TOTAL_FRAME_TIMEOUT then
			emu.print("Out of time; fitness = " .. fit)
		end
		if frameCounter - lastFitnessChange == NO_PROGRESS_TIMEOUT then
			emu.print("Stopped progressing; fitness = " .. fit)
		end
		if frameCounter == QUICK_TIMEOUT and lastFitnessChange == 1 then
			emu.print("No progress at start; fitness = " .. fit)
		end
		
		ga.assignFitness(ga,fit)
		
		--prepare next brain
		--if no brains remain, create next generation
		if ga.nextBrain(ga) then
			ga.makeNextGeneration(ga)
			emu.print("next generation created")
			saveGeneration("saves/recent.txt", ga)
			emu.print("population saved")
			saveSpecies("saves/recent_species.txt", species)
			emu.print("species list saved")
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