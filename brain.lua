--brain.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--the neural network brains that form the population of the genetic algorithm

require "constants"
require "inum_tracker"
require "display_brain"

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
		if not nodes[self.inNode] then
			error("ERROR: " .. self.inNode .. " is not a valid node")
		end
		if nodes[self.outNode] then
			nodes[self.outNode] = nodes[self.outNode] + (nodes[self.inNode] * self.weight)
		else
			nodes[self.outNode] = nodes[self.inNode] * self.weight
		end
	end
	if self.nextConnection then
		self.nextConnection.calculateValue(self.nextConnection, nodes)
	end
end

function ConnectionGene:new(o)
	o = o or {}
	if o.inum == 0 then
		connectionCount = connectionCount + 1
		o.inum = connectionCount
	end
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
	self.mutateAddConnection(self)
end

--make this brain the offspring of two other brains
--if there is a conflict, priority goes to parentA
function Brain.crossover(self, parentA, parentB)
	local parentAGenes = parentA.getAllConnections(parentA)
	local parentBGenes = parentB.getAllConnections(parentB)
	
	--make sure parent A has the higher fitness
	--if fitnesses are equal, make the smaller one parent A
	if parentB.fitness > parentA.fitness or (parentA.fitness == parentB.fitness and parentAGenes.length > parentBGenes.length) then
		local temp = parentAGenes
		parentAGenes = parentBGenes
		parentBGenes = temp
	end
	
	--inherit all genes from parentA
	for i,v in ipairs(parentAGenes) do
		if i ~= length then
			self.addNewConnection(self,v.inNode,v.outNode,v.weight,v.inum,v.enabled)
		end
	end
	
	--if any gene is shared between both parents, choose randomly between their weights
	local currentGenes = self.getAllConnections(self)
	for ib,vb in ipairs(parentBGenes) do
		if ib ~= length then
			local matched = false
			for ic,vc in ipairs(currentGenes) do
				if ic ~= length then
					if vb.inum == vc.inum then
						--matching gene, choose randomly between their weights
						if math.random() < 0.5 then vc.weight = vb.weight end
						matched = true
						break
					end
				end
			end
		end
	end
end

--check how similar this brain is to another
function Brain.compare(self, otherBrain)
	--compare the connection genome of both genes using the following function
	--d = (c1 * D) / N + c2 * W
	--c1, c2 = importance coefficients
	--d = compatibility distance
	--D = number of excess and disjoint genes
	--W = average weight differences of matching genes
	--N = number of genes in the larger genome
	
	local c1 = GENE_IMPORTANCE_COEFFICIENT
	local c2 = WEIGHT_IMPORTANCE_COEFFICIENT
	
	local allGenes1 = self.getAllConnections(self)
	local allGenes2 = otherBrain.getAllConnections(otherBrain)
	
	local N = (allGenes1.length > allGenes2.length) and allGenes1.length or allGenes2.length
	
	local matchedWeights = {length = 0}
	--for every gene in allGenes1, try to find a match in allGenes2
	for i,v in ipairs(allGenes1) do
		if i ~= "length" then
			for j,w in ipairs(allGenes2) do
				if j ~= "length" then
					if v.inum == w.inum then
						--genes matched
						matchedWeights.length = matchedWeights.length + 1
						matchedWeights[matchedWeights.length] = math.abs(v.weight - w.weight)
						break
					end
				end
			end
		end
	end
	
	--number of mismatched genes == total number of genes - matched gene pairs
	local D = allGenes1.length + allGenes2.length - (matchedWeights.length * 2)
	
	--find average weight difference of matched genes
	local W = 0
	if matchedWeights.length > 0 then
		for i,v in ipairs(matchedWeights) do
			if i ~= "length" then
				W = W + v
			end
		end
		W = W / matchedWeights.length
	end
	
	local d = math.max(((c1 * D) / N),D) + (c2 * W)
	return d
end

--calculate the outputs based on the given inputs
function Brain.think(self, inputs)
	local nodes = {}
	
	--set input nodes
	for i=1,INPUT_NODES do
		nodes[i] = inputs[i]
	end
	
	--forward propagate
	local n = 1
	while self.nodeOrder[n] do
		local con = self.connections[self.nodeOrder[n]]
		if con then
			con.calculateValue(con, nodes)
		end
		n = n + 1
	end
	
	drawBrain(nodes, self.getAllConnections(self), self)
	
	--return outputs
	local outputs = {}
	for i=1,OUTPUT_NODES do
		if nodes[i + INPUT_NODES] then
			outputs[i] = nodes[i + INPUT_NODES]
		else
			outputs[i] = 0
		end
	end
	
	return outputs
end

--check if a node is later in the tree than the given node
function Brain.isNodeLaterOnPath(self, startNodeInum, locateInum)
	local q = {top = 1, bottom = 2}
	q[1] = startNodeInum
	while q.top < q.bottom do
		if q[q.top] == locateInum then return true end
		local con = self.connections[q[q.top]]
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
function Brain.addNewConnection(self, inNode, outNode, weight, inum, enabled)
	--connection is illegal if it ends at an input node
	if outNode <= INPUT_NODES then return false end
	
	--connection is illegal if it starts at an output node
	if inNode > INPUT_NODES then
		if inNode <= INPUT_NODES + OUTPUT_NODES then return false end
	end

	--connection is illegal if it creates a cycle
	if self.isNodeLaterOnPath(self, outNode, inNode) then return false end

	local newConnection = ConnectionGene:new{weight=weight,inNode=inNode,outNode=outNode,inum=inum,enabled=enabled}
	if self.connections[inNode] then
		self.connections[inNode].addNewConnection(self.connections[inNode], newConnection)
	else
		self.connections[inNode] = newConnection
	end
	return true
end

--add a new node in the middle of an existing connection
function Brain.addNewNode(self, oldConnection)
	nodeCount = nodeCount + 1
	
	oldConnection.enabled = false
	
	local w = (math.random(2001) - 1001) / 1000
	
	local a = true
	local b = true
	a = self.addNewConnection(self, oldConnection.inNode, nodeCount, oldConnection.weight, 0, true)
	b = self.addNewConnection(self, nodeCount, oldConnection.outNode, w, 0, true)
	if not a or not b then error("error with node creation") end
end

--get a table of all connections indexed like an array, with a length
function Brain.getAllConnections(self)
	local allConnections = {length = 0}
	for i in pairs(self.connections) do
		local c = self.connections[i]
		repeat
			allConnections.length = allConnections.length + 1
			allConnections[allConnections.length] = c
			c = c.nextConnection
		until not c
	end
	return allConnections
end

--get a table of all nodes indexed like an array, with a length
function Brain.getAllNodes(self)
	local allConnections = self.getAllConnections(self)
	local allNodes = {length = 0}
	for i=1,(INPUT_NODES + OUTPUT_NODES) do
		allNodes.length = allNodes.length + 1
		allNodes[i] = allNodes.length
	end
	for i=1,allConnections.length do
		local c = allConnections[i]
		if not allNodes[c.inNode] then
			allNodes.length = allNodes.length + 1
			allNodes[c.inNode] = allNodes.length
		end
		if not allNodes[c.outNode] then
			allNodes.length = allNodes.length + 1
			allNodes[c.outNode] = allNodes.length
		end
	end
	
	local allNodesRev = {length = allNodes.length}
	for i in pairs(allNodes) do
		if i ~= "length" then
			allNodesRev[allNodes[i]] = i
		end
	end
	
	return allNodesRev
end

--add a connection to the network, if possible
function Brain.mutateAddConnection(self)
	local w = (math.random(2001) - 1001) / 1000	--the weight of the new connection
	
	--a random connection is made following these steps:
	--1. pick a node at random to be the start node
	--2. pick a node at random to be the end node (can be the same as the start node)
	--3. check to see if the connection already exists
	--	a. if it does and it's disabled, enable it and give it a new weight, and return
	--	b. if it does and it's enabled, return to step 2 and pick a new end node without replacement
	--	c. if it doesn't, go to step 4
	--4. attempt to make a new connection between the nodes
	--	a. if the new connection is successful, return
	--	b. if not, return to step 2 and pick a new end node without replacement
	--5. if all end nodes have been tried, return to step 1 and pick a new node without replacement
	--with this system all potential connections will be tried, even illegal ones
	--if the outer loop ends without returning, there are no valid connections
	
	local startNodes = self.getAllNodes(self)
	while startNodes.length > 0 do
		--step 1
		local s = math.random(startNodes.length)
		local endNodes = self.getAllNodes(self)
		while endNodes.length > 0 do
			--step 2
			local e = math.random(endNodes.length)
			--step 3
			local valid = true
			local allcons = self.getAllConnections(self)
			for i in pairs(allcons) do
				if i ~= "length" then
					if allcons[i].inNode == startNodes[s] and allcons[i].outNode == endNodes[e] then
						if allcons[i].enabled then
							valid = false
							break
						else
							--step 3a
							allcons[i].enabled = true
							allcons[i].weight = w
							--emu.print("enable connection between " .. allcons[i].inNode .. " and " .. allcons[i].outNode)
							return
						end
					end
				end
			end
			--step 3c
			if valid then
				--step 4
				valid = self.addNewConnection(self, startNodes[s], endNodes[e], w, 0, true)
				--step 4a
				if valid then 
					--emu.print("add connection between " .. startNodes[s] .. " and " .. endNodes[e])
					return 
				end
			end
			--step 3b and 4b (back to start of inner while loop)
			endNodes[e] = endNodes[endNodes.length]
			endNodes.length = endNodes.length - 1
		end
		--step 5 (back to start of outer while loop)
		startNodes[s] = startNodes[startNodes.length]
		startNodes.length = startNodes.length - 1
	end
	--if code gets here, no new connections are valid
	return
end

--add a node to the neural network, if possible
function Brain.mutateAddNode(self)
	local allConnections = self.getAllConnections(self)
	while allConnections.length > 0 do
		--choose a connection at random
		local i = math.random(allConnections.length)
		if allConnections[i].enabled then
			--if it's enabled, use it to add a node, then return
			self.addNewNode(self, allConnections[i])
			--emu.print("add node " .. nodeCount .. " between " .. allConnections[i].inNode .. " and " .. allConnections[i].outNode)
			return
		else
			--if it's disabled, skip it and remove it from the list
			allConnections[i] = allConnections[allConnections.length]
			allConnections.length = allConnections.length - 1
		end
	end
	--if code gets here, no connections are valid for adding a node
	return
end

--modify the weights of each connection in the network with a certain probability
--the chance to modify each connection is 1/number of connections or 5%, whichever is higher
--this means if there is only one connection, it is guaranteed to be modified
function Brain.mutateWeights(self)
	local allConnections = self.getAllConnections(self)
	
	for i,v in ipairs(allConnections) do
		if i ~= "length" then
			if (math.min(allConnections.length, 20) * math.random()) < 1 then
				if math.random() < WEIGHT_NEGATION_CHANCE then
					v.weight = v.weight * -1
				else
					v.weight = v.weight + (math.random(2001) - 1001) / 1000
				end
			end
		end
	end
end

--disable a connection, if possible
function Brain.mutateDisable(self)
	local allConnections = self.getAllConnections(self)
	while allConnections.length > 0 do
		local rand = math.random(allConnections.length)
		local inValid = false
		local outValid = false
		
		if allConnections[rand].inNode <= INPUT_NODES then 
			--inNode is input node
			inValid = true 
		else
			--inNode has another outgoing connection
			local con = self.connections[allConnections[rand].inNode]
			if con.outNode ~= allConnections[rand].outNode or con.nextConnection then
				inValid = true
			end
		end
		
		if inValid then
			if allConnections[rand].outNode > INPUT_NODES and allConnections[rand].outNode <= INPUT_NODES + OUTPUT_NODES then
				--outNode is output node
				outValid = true
			else
				--outNOde has another incoming connection
				local allCons = self.getAllConnections(self)
				for i in pairs(allCons) do
					if i ~= "length" then
						if allCons[i].inNode ~= allConnections[rand].inNode and allCons[i].outNode == allConnections[rand].outNode then
							outValid = true
							break
						end
					end
				end
			end
		end
		
		if inValid and outValid then
			allConnections[rand].enabled = false
			return
		else
			allConnections[rand] = allConnections[allConnections.length]
			allConnections.length = allConnections.length - 1
		end
	end
end

--determines the topological order of the neural network and sets it to nodeOrder
--this should be called after all modifications to the structure, but before think()
function Brain.prepareNodeTopology(self)
	self.nodeOrder = {}
	--create list forward with duplicates
	local list1 = {index = 0}
	function list1.add(node)
		list1.index = list1.index + 1
		list1[list1.index] = node
	end
	
	--only include input nodes that have a connection coming from them
	for i=1,INPUT_NODES do
		if self.connections[i] then
			list1.add(i)
		end
	end
	local counter = 1
	while counter <= list1.index do
		local c = self.connections[list1[counter]]
		while c do
			if c.outNode <= INPUT_NODES or c.outNode > INPUT_NODES + OUTPUT_NODES then
				if not pcall(function() list1.add(c.outNode) end) then
					emu.print(self.getAllConnections(self))
					error("node topology ran out of memory")
				end
			end
			c = c.nextConnection
		end
		counter = counter + 1
	end
	
	--create backwards list by removing duplicates
	local list2 = {}
	
	counter = 0
	while list1.index > 0 do
		if list2[list1[list1.index]] == nil then
			counter = counter + 1
			list2[list1[list1.index]] = counter
		end
		list1.index = list1.index - 1
	end
	
	--reverse list
	local list3 = {}
	for i in pairs(list2) do
		list3[counter - list2[i] + 1] = i
	end
	self.nodeOrder = list3
end

--sets the species this brain belongs in
function Brain.setSpecies(self,specie)
	self.species = specie
end

function Brain:new(o)
	if o then
		for j in pairs(o.connections) do
			local con = o.connections[j]
			while con do
				con = ConnectionGene:new(con)
				con = con.nextConnection
			end
		end
	else
		o = {}
		o.fitness = -1
		o.connections = {}
		o.nodeOrder = {}
		o.species = -1
	end
	setmetatable(o, self)
	self.__index = self
	return o
end