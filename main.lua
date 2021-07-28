--main.lua
--created by Gideon Marsh

--The main driver for the RL-Mega-Man-v2 project scripts

require "constants"
require "nn_vision"
require "fitness"
require "menu"
require "brain"

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

brain1 = Brain:new{}
brain2 = Brain:new{}
emu.print("brains created")
brain1.initNewBrain(brain1)
brain2.initNewBrain(brain2)
emu.print("brains initialized")
for i=1,20 do
	brain1.mutateStructure(brain1)
	brain2.mutateStructure(brain2)
end
emu.print("brains mutated")
--emu.print("brain 1 connections")
--cs1 = brain1.getAllConnections(brain1)
--for i, v in ipairs(cs1) do
--	emu.print(v.inNode .. " to " .. v.outNode)
--end
--emu.print("brain 2 connections")
--cs2 = brain2.getAllConnections(brain2)
--for i, v in ipairs(cs2) do
--	emu.print(v.inNode .. " to " .. v.outNode)
--end
brain3 = Brain:new{}
emu.print("brain3 created")
brain3.crossover(brain3,brain1,brain2)
emu.print("brain3 initialized as child")
--emu.print("brain 3 connections")
--cs3 = brain3.getAllConnections(brain3)
--for i, v in ipairs(cs3) do
--	emu.print(v.inNode .. " to " .. v.outNode)
--end

brain3.prepareNodeTopology(brain3)
emu.print("topology prepared")
--for i,v in ipairs(brain.nodeOrder) do
--	emu.print(i .. " " .. v)
--end
emu.print("brain1 to brain2: " .. brain1.compare(brain1,brain2))
emu.print("brain1 to brain3: " .. brain1.compare(brain1,brain3))
emu.print("brain2 to brain3: " .. brain2.compare(brain1,brain3))

-----MAIN PROGRAM LOOP----
while true do
	
	--vals = getInputValues()
	--val = vals[(256 * 92) + 101]
	--gui.pixel(100,100,{val,val,val})
	--gui.text(20, 20, val, "white", "black")
	
	local out = brain3.think(brain3, getInputValues())
	
	local outString = ""
	for i=1,6 do
		if out[i] > 0 then
			outString = outString .. "on "
		else
			outString = outString .. "off "
		end
	end
	gui.text(10, 200, outString, "white", "black")
	joypad.set(1, {["up"]=(out[1] > 0),["down"]=(out[2] > 0),
					["left"]=(out[3] > 0),["right"]=(out[4] > 0),
					["A"]=(out[5] > 0),["B"]=(out[6] > 0)})
	
	setFitness()
	
	local val = memory.readbyte(0x01FE)
	if val == 195 then
		emu.print(returnFitness())
		savestate.load(save)
	end
	
	
	emu.frameadvance()
end