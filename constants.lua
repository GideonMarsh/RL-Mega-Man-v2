--constants.lua
--created by Gideon Marsh
--github.com/GideonMarsh


--File names
WORKING_FILE = "saves/recent.txt"
HISTORY_FILE = "saves/Generation_"
HISTORY_FILE_EXT = ".txt"
LOG_FILE = "logs/Generation_Log_"
LOG_FILE_EXT = ".txt"

--Screen limits, in pixels
SCREEN_X_MIN = 0
SCREEN_X_MAX = 255
SCREEN_Y_MIN = 8
SCREEN_Y_MAX = 231

X_OFFSET = 4				--after reading a pixel, move over by the offset
Y_OFFSET = 4
Y_SHIFT = 1
--Note: screen height is 0-239, but emulator only displays the range of 8-231
--offset 3 -> 6450 input pixels
--offset 4 -> 3584 input pixels

--Number of player controls
CONTROLLER_OUTPUTS = 7		--up, down, left, right, A, B, weapon selection

--Memory Addresses
CURRENT_STAGE = 0x002A
CURRENT_SCREEN = 0x0440		--scrolling rooms are made up of several screens stitched together
SCREEN_SCROLL_X = 0x001F	--there are no vertically scrolling screens in Mega Man 2, so this is sufficient
PLAYER_X = 0x0460			--player internal x location. not relative to the screen
PLAYER_SCREEN_X = 0x002D	--player x location relative to the screen
PLAYER_Y = 0x04A0
GAME_STATE = 0x01FE
STATE_PLAYING = 178			--GAME_STATE value while player is in control
STATE_TRANSITION = 156		--GAME_STATE value during screen transition/death by pit
STATE_RESPAWNING = 195		--one of the GAME_STATE values used while respawning
STATE_LEVEL_COMPLETE = 143	--GAME_STATE value for completed level
STATE_STAGE_SELECT = 120	--GAME_STATE value on stage select screen
STATE_GAME_OVER = 197		--GAME_STATE value for game over
BOSS_HP = 0x06C1
PLAYER_HP = 0x06C0
MAX_HP = 28					--maximum hp of player and bosses

--Neural Network
STATIC_INPUTS = 12
--the number of input nodes for each neural network
INPUT_NODES = STATIC_INPUTS + math.ceil((SCREEN_X_MAX - SCREEN_X_MIN + 1) / X_OFFSET) * math.ceil((SCREEN_Y_MAX - SCREEN_Y_MIN + 1) / Y_OFFSET)
--the number of output nodes for each neural network
OUTPUT_NODES = CONTROLLER_OUTPUTS

--Genetic algorithm
GENE_IMPORTANCE_COEFFICIENT = 5		--coefficients used in Brain.compare()
WEIGHT_IMPORTANCE_COEFFICIENT = 2

POPULATION_SIZE = 200
NODE_MUTATION_CHANCE = 0.05
CONNECTION_MUTATION_CHANCE = 0.3
CONNECTION_MUTATION_IN_BIAS = 0.05
CONNECTION_MUTATION_OUT_BIAS = 0.2
WEIGHT_MUTATION_CHANCE = 0.5
WEIGHT_NEGATION_CHANCE = 0.25
DISABLE_MUTATION_CHANCE = 0.05
BRAIN_DIFFERENCE_DELTA = 6
STALE_SPECIES_CUTOFF = 20			--number of generations without improvement until a species is removed
SIZE_PER_ELITE = 10


--Miscellaneous
TOTAL_FRAME_TIMEOUT = 25200	--max number of frames a brain is allowed to run for (game is 60fps)
NO_PROGRESS_TIMEOUT = 1800	--if fitness does not change after this many frames, the current run ends
QUICK_TIMEOUT = 60			--if no progress is made in the first this many frames, the run ends

FITNESS_OFFSET = 128		--fitness starts at this value + 1, subtract this for actual starting fitness
FITNESS_BASE = 4			--the priority to give one brain over another if the difference between their fitnesses equals FITNESS_MODIFIER
FITNESS_MODIFIER = 256		