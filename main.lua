--main.lua
--created by Gideon Marsh

--The main driver for the RL-Mega-Man-v2 project scripts

require "constants"
require "nn_vision"
require "fitness"

save = savestate.object()
savestate.save(save)

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