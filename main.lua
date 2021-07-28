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

--create genetic algorithm controller
ga = GeneticAlgorithmController:new{}


-----MAIN PROGRAM LOOP----
local frameCounter = 1
--loop once per frame
while true do
	--do neural network calculation for this frame
	local out = ga.passInputs(ga, getInputValues())
	
	--set player controls according to output of calculation
	joypad.set(1, {["up"]=(out[1] > 0),["down"]=(out[2] > 0),
					["left"]=(out[3] > 0),["right"]=(out[4] > 0),
					["A"]=(out[5] > 0),["B"]=(out[6] > 0)})
					
	--show information on screen
	local outString = ""
	for i=1,6 do
		if out[i] > 0 then
			outString = outString .. "on "
		else
			outString = outString .. "off "
		end
	end
	
	gui.text(10, 209, outString, "white", "black")
	gui.text(10, 218, ga.getIndividualInfo(ga), "white", "black")
	gui.text(211, 218, frameCounter, "white", "black")
	
	--set fitness as of this frame
	setFitness()
	
	--check to see if current run is over
	local val = memory.readbyte(0x01FE)
	if val == 195 or frameCounter == TOTAL_FRAME_TIMEOUT then
		--assign final fitness to current brain
		local fit = returnFitness()
		emu.print(fit)
		ga.assignFitness(ga,fit)
		
		--prepare next brain
		--if no brains remain, create next generation
		if ga.nextBrain(ga) then
			ga.makeNextGeneration(ga)
		end
		
		--reset run
		savestate.load(save)
		frameCounter = 1
	end
	
	--advance to next frame
	frameCounter = frameCounter + 1
	emu.frameadvance()
end