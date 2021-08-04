
require "constants"
require "menu"
require "brain"


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

--testbrain = Brain:new()
--for i=1,10 do
--	testbrain.mutateStructure(testbrain)
--end
--emu.print(testbrain.getAllConnections(testbrain))

savestate.load(save)
local frameCounter = 1

while true do
	
	local stage = memory.readbyte(CURRENT_STAGE)
	local screen = memory.readbyte(CURRENT_SCREEN)
	local mx = memory.readbyte(PLAYER_X)
	local my = memory.readbyte(PLAYER_Y)
	gui.text(211, 218, frameCounter, "white", "black")
	gui.text(10, 209, "Stage " .. stage .. "; Screen " .. screen, "white", "black")
	gui.text(10, 218, "X " .. mx .. "; Y " .. my, "white", "black")

	
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