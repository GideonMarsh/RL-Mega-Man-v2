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

brain = Brain:new{}
emu.print("brain created")
brain.initNewBrain(brain)
emu.print("brain initialized")
for i=1,20 do
	brain.mutateStructure(brain)
end
emu.print("brain mutated")
--cs = brain.getAllConnections(brain)
--for i, v in ipairs(cs) do
--	emu.print(v.inNode .. " to " .. v.outNode)
--end
brain.prepareNodeTopology(brain)
emu.print("topology prepared")
--for i,v in ipairs(brain.nodeOrder) do
--	emu.print(i .. " " .. v)
--end

-----MAIN PROGRAM LOOP----
while true do
	
	--vals = getInputValues()
	--val = vals[(256 * 92) + 101]
	--gui.pixel(100,100,{val,val,val})
	--gui.text(20, 20, val, "white", "black")
	
	local out = brain.think(brain, getInputValues())
	
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