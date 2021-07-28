--menu.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--helper functions for navigating the game menus

STANDARD_BUTTON_DELAY = 3

function menuUp()
	joypad.set(1,{["up"]=true,["down"]=false,["left"]=false,["right"]=false,
					["A"]=false,["B"]=false,["start"]=false,["select"]=false})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuDown()
	joypad.set(1,{["up"]=false,["down"]=true,["left"]=false,["right"]=false,
					["A"]=false,["B"]=false,["start"]=false,["select"]=false})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuLeft()
	joypad.set(1,{["up"]=false,["down"]=false,["left"]=true,["right"]=false,
					["A"]=false,["B"]=false,["start"]=false,["select"]=false})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuRight()
	joypad.set(1,{["up"]=false,["down"]=false,["left"]=false,["right"]=true,
					["A"]=false,["B"]=false,["start"]=false,["select"]=false})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuA()
	joypad.set(1,{["up"]=false,["down"]=false,["left"]=false,["right"]=false,
					["A"]=true,["B"]=false,["start"]=false,["select"]=false})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuB()
	joypad.set(1,{["up"]=false,["down"]=false,["left"]=false,["right"]=false,
					["A"]=false,["B"]=true,["start"]=false,["select"]=false})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuStart()
	joypad.set(1,{["up"]=false,["down"]=false,["left"]=false,["right"]=false,
					["A"]=false,["B"]=false,["start"]=true,["select"]=false})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuSelect()
	joypad.set(1,{["up"]=false,["down"]=false,["left"]=false,["right"]=false,
					["A"]=false,["B"]=false,["start"]=false,["select"]=true})
	menuWait(STANDARD_BUTTON_DELAY)
end

function menuWait(t)
	for i=1,t do
		emu.frameadvance()
	end
end