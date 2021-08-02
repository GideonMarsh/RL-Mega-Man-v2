
require "constants"
require "menu"


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

savestate.load(save)
local frameCounter = 1

while true do

	gui.text(211, 218, frameCounter, "white", "black")
	
	local val = memory.readbyte(GAME_STATE)
	if (val == STATE_LEVEL_COMPLETE) then 
		emu.print(frameCounter)
		break
	end
	if (val == STATE_RESPAWNING) or 
		(frameCounter == TOTAL_FRAME_TIMEOUT) then
		
		--reset run
		savestate.load(save)
		frameCounter = 1
	else
		--advance to next frame
		frameCounter = frameCounter + 1
		emu.frameadvance()
	end
end