--ga.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--the class for handling the genetic algorithm

require "constants"
require "brain"

--the table of species' representatives
--the brains in this table are used as the comparisons to determine which species another brain belongs to
--the name of this variable is not allowed to change since it is saved to a file
species = {}

--the prototype for GeneticAlgorithmController objects
--GeneticAlgorithmController objects maintain the population of brains being used in the genetic algorithm
--the main driver should not have access to brain objects directly

GeneticAlgorithmController = {population={},generation=0,currentBrain=0}

--pass the inputs to the current brain and return the output
function GeneticAlgorithmController.passInputs(self,inputs)
	local b = self.population[self.currentBrain]
	return b.think(b, inputs)
end

--assign a fitness value to the current brain
function GeneticAlgorithmController.assignFitness(self, fitness)
	self.population[self.currentBrain].fitness = fitness
end

--selects the next brain to be run
--returns true if all brains in this generation are done
function GeneticAlgorithmController.nextBrain(self)
	self.currentBrain = self.currentBrain + 1
	if self.currentBrain > POPULATION_SIZE then return true end
	return false
end

--finds the brain with the highest fitness and sets it as self.bestBrain
function GeneticAlgorithmController.setBestBrain(self)
	local best = self.population[1]
	for b=1,POPULATION_SIZE do
		if self.population[b].fitness > best.fitness then
			best = self.population[b]
		end
	end
	self.bestBrain = best
end

--create the next generation, using the current one as parents
function GeneticAlgorithmController.makeNextGeneration(self)
	--steps:
	--1. adjust fitness by species size
	--	adjustedFitness = fitness / speciesSize
	--2. apportion new species sizes of next generation
	--	newSpeciesSize = (sum of all adjusted fitnesses) / (mean adjusted fitness of entire population)
	--	limit the amount of new organisms to the max population size
	--3. create new generation
	--	for each species, select the highest r% of the species to breed
	--	randomly breed a number of offspring equal to the newSpeciesSize
	--	randomly mutate every individual with a certain probability
	--4. separate the new population into species
	--NOTE: this isn't designed to work with negative fitness values
	
	self.setBestBrain(self)
	
	--use species to separate population into lists
	local currentSpecies = {}
	
	for i=1,POPULATION_SIZE do
		local s = self.population[i].species
		if currentSpecies[s] then
			currentSpecies[s].length = currentSpecies[s].length + 1
			currentSpecies[s][currentSpecies[s].length] = self.population[i]
		else
			currentSpecies[s] = {length = 1, [1]=self.population[i]}
		end
	end
	
	--step 1
	local meanFitness = 0
	
	for i=1,POPULATION_SIZE do
		local speciesSize = currentSpecies[self.population[i].species].length
		self.population[i].fitness = self.population[i].fitness / speciesSize
		meanFitness = meanFitness + self.population[i].fitness
	end
	meanFitness = meanFitness / POPULATION_SIZE
	
	--step 2
	local newSizes = {}
	local totalPopulation = 0
	for i in pairs(currentSpecies) do
		local sumFitness = 0
		for j in pairs(currentSpecies[i]) do
			if j ~= "length" then
				sumFitness = sumFitness + currentSpecies[i][j].fitness
			end
		end
		newSizes[i] = math.ceil(sumFitness / meanFitness)
		totalPopulation = totalPopulation + newSizes[i]
	end
	
	--add or remove to the species' sizes to make the population exact
	--choose species to add/remove from at random
	--leave one space to carry over the best brain
	local excessPopulation = totalPopulation - (POPULATION_SIZE - 1)
	if excessPopulation ~= 0 then
		local ns = {length = 0}
		for i in pairs(newSizes) do
			ns.length = ns.length + 1
			ns[ns.length] = i
		end
		while excessPopulation > 0 do
			--population too high
			local s = math.random(ns.length)
			if newSizes[ns[s]] > 0 then
				newSizes[ns[s]] = newSizes[ns[s]] - 1
				excessPopulation = excessPopulation - 1
			end
		end
		
		while excessPopulation < 0 do
			--population too low
			local s = math.random(ns.length)
			if newSizes[ns[s]] > 0 then
				newSizes[ns[s]] = newSizes[ns[s]] - 1
				excessPopulation = excessPopulation - 1
			end
		end
	end
	
	--step 3
	local newPopulation = {}
	local popCounter = 1
	
	for s in pairs(currentSpecies) do
		if newSizes[s] > 0 then
			local avefit = 0
			for i=1,currentSpecies[s].length do
				avefit = avefit + currentSpecies[s][i].fitness
			end
			avefit = math.floor(avefit / currentSpecies[s].length)	--floor it to prevent rounding errors
			local eligibleParents = {length = 0}
			for i=1,currentSpecies[s].length do
				if currentSpecies[s][i].fitness >= avefit then
					eligibleParents.length = eligibleParents.length + 1
					eligibleParents[eligibleParents.length] = currentSpecies[s][i]
				end
			end
			
			for i=1,newSizes[s] do
				parent1 = eligibleParents[math.random(eligibleParents.length)]
				parent2 = eligibleParents[math.random(eligibleParents.length)]
				newBrain = Brain:new()
				newBrain.crossover(newBrain,parent1,parent2)
				newBrain.species = parent1.species
				newPopulation[popCounter] = newBrain
				popCounter = popCounter + 1
			end
		end
	end
	
	--mutate each new brain at random
	for i in pairs(newPopulation) do
		if math.random() < STRUCTURAL_MUTATION_CHANCE then
			newPopulation[i].mutateStructure(newPopulation[i])
		end
		if math.random() < WEIGHT_MUTATION_CHANCE then
			newPopulation[i].mutateWeights(newPopulation[i])
		end
		newPopulation[i].prepareNodeTopology(newPopulation[i])
	end
	
	--step 4
	for i,v in ipairs(newPopulation) do
		local found = false
		for j in pairs(species) do
			if v.compare(v,species[j]) <= BRAIN_DIFFERENCE_DELTA then
				v.species = j
				found = true
				break
			end
		end
		if not found then
			local newSpeciesCounter = 1
			local newSpecies = v.species .. "." .. newSpeciesCounter
			while species[newSpecies] do
				newSpeciesCounter = newSpeciesCounter + 1
				newSpecies = v.species .. "." .. newSpeciesCounter
			end
			species[newSpecies] = v
			v.species = newSpecies
		end
	end
	
	if self.bestBrain then
		newPopulation[popCounter] = self.bestBrain
	end
	
	self.currentBrain = 1
	self.generation = self.generation + 1
	
	self.population = newPopulation
end

--get basic info of current brain
function GeneticAlgorithmController.getIndividualInfo(self)
	local b = self.population[self.currentBrain]
	--return "Generation " .. self.generation .. "; Species " .. b.species .. "; Individual " .. self.currentBrain
	return {[1]=self.generation,[2]=b.species,[3]=self.currentBrain}
end

function GeneticAlgorithmController:new(o)
	if o then
		for i=1,POPULATION_SIZE do
			o.population[i] = Brain:new(o.population[i])
			for j in pairs(o.population[i].connections) do
				local con = o.population[i].connections[j]
				while con do
					con = ConnectionGene:new(con)
					con = con.nextConnection
				end
			end
		end
	else
		o = {}
		o.population={}
		o.generation=1
		o.currentBrain=1
		
		for i=1,POPULATION_SIZE do
			newBrain = Brain:new()
			newBrain.initNewBrain(newBrain)
			
			newBrain.prepareNodeTopology(newBrain)
			o.population[i] = newBrain
		end
		
		local initialSpeciesCounter = 1
		for i,v in ipairs(o.population) do
			local found = false
			for j in pairs(species) do
				if v.compare(v,species[j]) <= BRAIN_DIFFERENCE_DELTA then
					v.species = j
					found = true
					break
				end
			end
			if not found then
				species[initialSpeciesCounter .. ""] = v
				v.species = initialSpeciesCounter .. ""
				initialSpeciesCounter = initialSpeciesCounter + 1
			end
		end
	end
	
	setmetatable(o, self)
	self.__index = self
	return o
end

--helper function for reinstantiating species table from file
function reinstantiateSpecies()
	for i in pairs(species) do
		species[i] = Brain:new(species[i])
		for j in pairs(species[i].connections) do
			local con = species[i].connections[j]
			while con do
				con = ConnectionGene:new(con)
				con = con.nextConnection
			end
		end
	end
end