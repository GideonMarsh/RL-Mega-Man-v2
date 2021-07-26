--main.lua
--created by Gideon Marsh

--The main driver for the RL-Mega-Man-v2 project scripts

require "constants"
require "nn_vision"

while true do
	
	vals = getInputValues()
	gui.pixel(20,20,"white")
	gui.text(100, 100, vals[(256 * 12) + 21], "white", "black")
	
	
	emu.frameadvance()
end