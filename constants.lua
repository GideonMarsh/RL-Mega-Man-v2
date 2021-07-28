--constants.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--Screen limits, in pixels
SCREEN_X_MIN = 0
SCREEN_X_MAX = 255
SCREEN_Y_MIN = 8
SCREEN_Y_MAX = 231
--Note: screen height is 0-239, but emulator only displays the range of 8-231

--Number of player controls
CONTROLLER_OUTPUTS = 6		--up, down, left, right, A, B

--Memory Addresses
CURRENT_STAGE = 0x002A
CURRENT_SCREEN = 0x0440		--scrolling rooms are made up of several screens stitched together
SCREEN_SCROLL_X = 0x001F	--there are no vertically scrolling screens in Mega Man 2, so this is sufficient
PLAYER_X = 0x0460			--player x location will be static while screen is scrolling
PLAYER_Y = 0x04A0
GAME_STATE = 0x01FE
STATE_PLAYING = 178			--GAME_STATE value while player is in control
STATE_TRANSITION = 156		--GAME_STATE value during screen transition/death by pit
STATE_RESPAWNING = 195		--one of the GAME_STATE values used while respawning
STATE_LEVEL_COMPLETE = 143	--GAME_STATE value for completed level
STATE_STAGE_SELECT = 120	--GAME_STATE value on stage select screen
STATE_GAME_OVER = 197		--GAME_STATE value for game over
BOSS_HP = 0x06C1

--Genetic algorithm
GENE_IMPORTANCE_COEFFICIENT = 10
WEIGHT_IMPORTANCE_COEFFICIENT = 5

POPULATION_SIZE = 100
STRUCTURAL_MUTATION_CHANCE = 0.2
WEIGHT_MUTATION_CHANCE = 0.4
BRAIN_DIFFERENCE_DELTA = 10