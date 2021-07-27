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
brain.mutateStructure(brain)
brain.mutateStructure(brain)
brain.mutateStructure(brain)
cs = brain.getAllConnections(brain)
for i, v in ipairs(cs) do
	emu.print(v.inNode .. " to " .. v.outNode)
end

-----MAIN PROGRAM LOOP----
while true do
	
	--vals = getInputValues()
	--val = vals[(256 * 92) + 101]
	--gui.pixel(100,100,{val,val,val})
	--gui.text(20, 20, val, "white", "black")
	
	setFitness()
	
	local val = memory.readbyte(0x01FE)
	if val == 195 then
		emu.print(returnFitness())
		savestate.load(save)
	end
	
	
	emu.frameadvance()
end