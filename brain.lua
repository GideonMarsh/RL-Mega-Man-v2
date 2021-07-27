--brain.lua
--created by Gideon Marsh

--the neural network brains that form the population of the genetic algorithm

require "constants"


--the number of input nodes for each neural network
inputNodes = (SCREEN_X_MAX - SCREEN_X_MIN) * (SCREEN_Y_MAX - SCREEN_Y_MIN)
--the number of output nodes for each neural network
outputNodes = CONTROLLER_OUTPUTS

--the innovation numbers for nodes and connections
--these ensure that no two nodes share the same id, same for connections
--nodes with innovation numbers 1-inputNodes are input nodes
--nodes with innovation numbers (inputNodes+1)-outputNodes are output nodes
--nodes with innovation numbers >outputNodes are hidden nodes
nodeCount = inputNodes + outputNodes
connectionCount = 0


--prototype for ConnectionGene objects
--ConnectionGene objects store the structure of the neural network
--each ConnectionGene represents a one-way connection between two nodes
--nodes in the neural network are implicitely defined by the input/output nodes of the network's connections
--ConnectionGene objects have the following properties:
--inum - the innovation number of the gene. Genes with the same inum are historically the same gene
--weight - the weight of the connection, used during forward propagation
--enabled - whether the gene is currently enabled or not
--inNode - the node the connection comes from
--outNode - the node the connection goes to
ConnectionGene = {weight=0,enabled=false,inNode=0,outNode=0}

function ConnectionGene.addNewConnection(self, newConnection)
	if self.nextConnection then
		self.nextConnection.addNewConnection(self.nextConnection, newConnection)
	else
		self.nextConnection = newConnection
	end
end

function ConnectionGene.calculateValue(self, nodes)
	if self.enabled then
		if nodes[self.outNode] then
			nodes[self.outNode] = nodes[self.outNode] + (nodes[self.inNode] * self.weight)
		else
			nodes[self.outNode] = nodes[self.inNode] * self.weight
		end
	end
	if self.nextConnection then
		self.nextConnection.calculateValue(nodes)
	end
end

function ConnectionGene:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end


--prototype for Brain objects
--Brain objects are the neural networks
--each Brain represents one neural network in the population
--Brain objects have the following properties
--fitness - the fitness of this brain
--connections - the list of ConnectionGene objects making up the structure of this neural network
--nodeOrder - the topological list of nodes, used during calculation
--species - the species of the Brain, used in the genetic algorithm
Brain = {fitness = -1,connections = {}, nodeOrder = {}, species = -1}

--initialize this brain from scratch
--should only be used when creating the initial population
function Brain.initNewBrain(self)
	self.mutateStructure(self)
end

--make this brain the offspring of two other brains
function Brain.crossover(self, parentA, parentB)

end

--check how similar this brain is to another
function Brain.compare(self, otherBrain)

end

--calculate the outputs based on the given inputs
function Brain.think(self, inputs)

end

--check if a node is later in the tree than the given node
function Brain.isNodeLaterOnPath(self, startNodeInum, locateInum)
	local q = {top = 1, bottom = 2}
	q[1] = startNodeInum
	while q.top < q.bottom do
		if q[q.top] == locateInum then return true end
		local con = self.connections[q.top]
		while con do
			q[q.bottom] = con.outNode
			q.bottom = q.bottom + 1
			con = con.nextConnection
		end
		q.top = q.top + 1
	end
	return false
end

--add a new connection between two nodes
function Brain.addNewConnection(self, inNode, outNode, weight)
	--connection is illegal if it ends at an input node
	if outNode <= inputNodes then return false end
	--connection is illegal if it starts at an output node
	if inNode > inputNodes then
		if inNode <= inputNodes + outputNodes then return false end
	end
	--connection is illegal if it creates a cycle
	if self.isNodeLaterOnPath(self, outNode, inNode) then return false end
	
	newConnection = ConnectionGene:new{weight=weight,enabled=true,inNode=inNode,outNode=outNode}
	if self.connections[inNode] then
		self.connections[inNode].addNewConnection(self.connections[inNode], newConnection)
	else
		self.connections[inNode] = newConnection
	end
end

--add a new node in the middle of an existing connection
function Brain.addNewNode(self, oldConnection)

end

--get a table of all connections separately
function Brain.getAllConnections(self)

end

--get a table of all nodes
function Brain.getAllNodes(self)

end

--make one random structural mutation to the neural network
--if there are no connections, a connection will be added
--otherwise, choose randomly between adding a connection or a node
function Brain.mutateStructure(self)

end

--modify the weights of each connection in the network with a certain probability
--the chance to modify each connection is 1/number of connections or 1%, whichever is higher
--this means if there is only one connection, it is guaranteed to be modified
function Brain.mutateWeights(self)

end

--determines the topological order of the neural network and sets it to nodeOrder
--this should be called after all modifications to the structure, but before think()
function Brain.prepareNodeTopology(self)

end

function Brain:new(o)
	o = o or {fitness = -1,connections = {}, nodeOrder = {}, species = -1}
	setmetatable(o, self)
	self.__index = self
	return o
end