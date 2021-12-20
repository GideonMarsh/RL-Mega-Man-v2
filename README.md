# RL-Mega-Man-v2
Reinforcement Learning in Mega Man, Version 2

The goal of this project is to make a framework that can perform reinforcement learning using the NEAT algorithm on the game Mega Man 2 for the NES. The game is emulated using the [FCEUX](http://fceux.com/web/home.html) emulator, and the reinforcement learning is accomplished via [LUA](https://www.lua.org/home.html) scripting.

Version 1 can be found [here](https://github.com/GideonMarsh/RL-Mega-Man).

Press spacebar while script is running to show a display of the currently running brain. If you are using the speedup or turbo functions of the emulator, showing the brain will significantly reduce the emulator's performance.

### Program Input

The script reads the pixel values from the screen using the emulator function emu.getscreenpixel(). The value of each pixel is converted to a single value by averaging the rgb values together. After that, it is subtracted by 128; this is so the input values are not all positive values.

### Program Output

The script controls the game using the emulator function joypad.set(). Game menus are navigated using preset input scripts. The emulator will ignore all human input while the brains are running. Any human input while the script is runnning may disrupt the function of the script.

### Genetic Algorithm

The process of reinforcement learning is handled by the NEAT algorithm. A population of 100 "brains" are created and allowed to play the game sequentially. After a given brain's run terminates, the fitness of that run is determined and the next brain is selected to play. After all 100 brains are done playing, a new population of 100 brains is created using the previous generation as the parents. Only brains that score above average fitness (in their species) are chosen to be parents. This program follows the implementation of the NEAT algorithm as specified in the original NEAT paper, which can be found [here](http://nn.cs.utexas.edu/downloads/papers/stanley.cec02.pdf). Please read this paper for additional details that are not covered below.

*Brains*

Each brain consists of a collection of nodes and connections that form a simple neural network. The number of input nodes is set at the number of pixels read from the input screenshots, and the number of output nodes is set at the number of controller outputs. Each brain stores its connections and determines its nodes implicitely from the input and output nodes of its connections. Each connection has a real number weight which is determined at its creation (but can be modified by mutation).

Calculating the output of the brains follows these steps. First, the values of the input nodes are set based on the pixel values on the screen. Each node has an associated pixel position on the screen, which is the pixel it receives its input from. The values are then propogated forward using the connections. The order of the calcuations is determined by topological order (calculations are performed only after all prerequisite calculations are complete). Each connection takes the value of its input node, multiplies that value by the weight of the connection, then adds the resulting value to the output node. After these calculations are complete, the values of the output nodes are used to determine the controller inputs to the game. If the value of a node is greater than 0, the associated button is pressed. If the value is 0 or less, the button is not pressed (or released). Using this method, the brains can programmatically control the game using only the visual information of the game as input.

New nodes and connections are added by mutation, and new brains are created using "reproduction".

- New nodes are added by selecting an existing connection and bisecting it, creating a new (implicit) node with two new connections: one from the original connection's input node to the new node, and one from the new node to the original connection's output node. The original connection is then disabled. All brains are created with one default connection, so this process always succeeds.
- New connections are added by selecting two nodes at random and attempting to make a connection between them. If an enabled connection between the nodes already exists, the new connection is invalid. If a disabled connection exists, it is enabled. There are three additional situations in which a new connection can be invalid: if it starts at an output node, if it ends at an input node, or if it creates a cycle. Cycles are not allowed as they prevent calculations from ever completing when values are propogated forward. If the new connection is invalid, a different pair of nodes is selected and the process repeats. If all node combinations have been tried, no new connections are available in this brain.
- Reproduction is the combining of two brains to create a new brain. The connections of both brains are examined to determine if they should be included in the new brain (nodes don't need to be considered since they are implicit). If the connection exists in one brain but not the other and it doesn't create a cycle, the connection is added to the new brain. If it exists in both brains, the connection is added and chooses its weight randomly between the two source connections.

*Species*

The population of brains is split into categories called species based on their similarities to each other (see the NEAT paper for more information). The species are used to preserve innovation among the population, allowing for lots of different strategies to be considered. A global species list is maintained, containing the representatives from each species. When a new brain is created it is compared to each of the representatives in the species list. If the brain is within a certain similarity range to one of the representatives, it is placed as a member of that specie. If it isn't within the similarity range for any existing species, a new specie is created to contain it and it is added to the species list as that specie's representative.

*Fitness*

The fitness of each brain is calculated primarily from the distance progressed through the level and the health of the player. For each step of forward progress, a value is added to the brain's fitness score. This value is adjusted based on the health of the player, such that making lots of progress with very little health remaining is scored equivalently to making half as much progress with full health. This incentivizes both making lots of progress and playing well.


### Current Problems

As of right now, the algorithm is capable of progressing through the early parts of a level, learning to overcome each obstacle at a steady rate. However, the speed at which the algorithm learns to overcome obstacles decreases dramatically around 25% through the level. It is unclear exactly why this happens, but some theories I have are:
- There is some unseen bug or inefficiency in the current implementation that when found will solve the issue.
- The speed at which the population "learns" is inversely correlated to the complexity of each brain. The further it progresses, the slower it will continue to progress. The slowdown is expected behavior. 
- Due to my implementation of the algorithm, the speed at which it overcomes the earlier obstacles is exaggerated, and the eventual slowdown is the actual baseline progression speed. 
- I may have accidentally programmed the script in such a way that favors early progression at the cost of later progression. This might possibly be because it is much easier and faster to test the early parts of the genetic algorithm.
- The speed of the learning process is highly random for each new population, and I keep inadvertantly skipping the populations that progress slowly at the beginning.
- The levels are too long for the algorithm to work as expected. This is a limitation of the algorithm.

Regardless of why this is happening, this can be overcome by letting the script run for exponentially longer times. 
