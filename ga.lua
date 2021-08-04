--ga.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--the class for handling the genetic algorithm

require "constants"
require "brain"
require "log"
require "inum_tracker"

--the prototype for GeneticAlgorithmController objects
--GeneticAlgorithmController objects maintain the population of brains being used in the genetic algorithm
--the main driver should not have access to brain objects directly

GeneticAlgorithmController = {population={},generation=0,currentBrain=0,averagePerformance=0,staleness=0}

--pass the inputs to the current brain and return the output
function GeneticAlgorithmController.passInputs(self,inputs)
	local b = self.population[self.currentBrain]
	return b.think(b, inputs)
end

--assign a fitness value to the current brain
function GeneticAlgorithmController.assignFitness(self, fitness)
	self.population[self.currentBrain].fitness = fitness
	if not self.bestBrain or fitness > self.bestBrain.fitness then
		self.bestBrain = self.population[self.currentBrain]
		self.staleness = 0
		emu.print("New Best!")
		logFile:write("New highest fitness: ", fitness, "\n")
	end
end

--selects the next brain to be run
--returns true if all brains in this generation are done
function GeneticAlgorithmController.nextBrain(self)
	self.currentBrain = self.currentBrain + 1
	if self.currentBrain > POPULATION_SIZE then return true end
	return false
end

--create the next generation, using the current one as parents
function GeneticAlgorithmController.makeNextGeneration(self)
	--steps:
	--1. adjust fitness by species size
	--	adjustedFitness = fitness / speciesSize
	--2. apportion new species sizes of next generation
	--	newSpeciesSize = (sum of all adjusted fitnesses of this species) / (mean adjusted fitness of entire population)
	--	do staleness check
	--	force the amount of new organisms to be the max population size
	--3. create new generation
	--	for each species, select the highest r% of the species to breed
	--	randomly breed a number of offspring equal to the newSpeciesSize
	--	randomly mutate every individual with a certain probability
	--4. separate the new population into species
	--NOTE: this isn't designed to work with negative fitness values, or when every fitness is 0
	
	
	local bestFit = self.bestBrain.fitness
	--use species to separate population into lists
	local currentSpecies = {}
	local aveUnalteredFit = 0
	local aveAlteredFit = 0
	for i=1,POPULATION_SIZE do
		local s = self.population[i].species
		if currentSpecies[s] then
			currentSpecies[s].length = currentSpecies[s].length + 1
			currentSpecies[s][currentSpecies[s].length] = self.population[i]
		else
			currentSpecies[s] = {length = 1, [1]=self.population[i]}
		end
		aveAlteredFit = aveAlteredFit + self.population[i].fitness
		aveUnalteredFit = aveUnalteredFit + (math.log10(self.population[i].fitness)/math.log10(FITNESS_BASE)) * FITNESS_MODIFIER
	end
	aveAlteredFit = aveAlteredFit / POPULATION_SIZE
	aveUnalteredFit = aveUnalteredFit / POPULATION_SIZE
	logFile:write("Population average fitness: ", aveUnalteredFit, "\nPopulation average modified fitness: ", aveAlteredFit, "\n")
	
	--step 1
	local meanFitness = 0
	
	for i=1,POPULATION_SIZE do
		local speciesSize = currentSpecies[self.population[i].species].length
		self.population[i].fitness = self.population[i].fitness / speciesSize
		meanFitness = meanFitness + self.population[i].fitness
	end
	meanFitness = meanFitness / POPULATION_SIZE
	logFile:write("Mean adjusted fitness: ", meanFitness, "\n")
	
	--step 2
	local newSizes = {}
	local sumFitnesses = {}
	local totalPopulation = 0
	for i in pairs(currentSpecies) do
		local sumFitness = 0
		for j in pairs(currentSpecies[i]) do
			if j ~= "length" then
				sumFitness = sumFitness + currentSpecies[i][j].fitness
			end
		end
		sumFitnesses[i] = sumFitness
		newSizes[i] = math.floor((sumFitness / meanFitness) + 0.5)
		totalPopulation = totalPopulation + newSizes[i]
		--logFile:write("Species ", i, " sum adjusted fitnesses: ", sumFitness, "\n")
	end
	
	for i=1,specieCount do
		if currentSpecies[i] then
			logFile:write("Species ", i, " sum adjusted fitnesses: ", sumFitnesses[i], "\n")
		end
	end
	
	--check if staleness needs to be incremented
	if aveAlteredFit > self.averagePerformance then
		self.averagePerformance = aveAlteredFit
		self.staleness = 0
	else
		self.staleness = self.staleness + 1
	end
	logFile:write("Staleness: ", self.staleness, "\n")
	
	--if the population is stale, remove all but top 3 species
	if self.staleness >= STALE_SPECIES_CUTOFF then
		logFile:write("Population stale - extinction event\n")
		self.staleness = 0
		sumFitnesses[-1] = 0
		local savedSpecies = {[1]=self.bestBrain.species,[2]=-1,[3]=-1,l=0}
		for i in pairs(sumFitnesses) do
			if i ~= savedSpecies[1] and sumFitnesses[i] > sumFitnesses[savedSpecies[2]] then
				savedSpecies[3] = savedSpecies[2]
				savedSpecies[2] = i
			elseif i ~= savedSpecies[1] and sumFitnesses[i] > sumFitnesses[savedSpecies[3]] then
				savedSpecies[3] = i
			end
			savedSpecies.l = savedSpecies.l + 1
		end
		if savedSpecies.l > 3 then
			for i in pairs(newSizes) do
				if i ~= savedSpecies[1] and i ~= savedSpecies[2] and i ~= savedSpecies[3] then
					totalPopulation = totalPopulation - newSizes[i]
					newSizes[i] = 0
				end
			end
		end
	end
	
	--add or remove to the species' sizes to make the population exact
	--add/remove from all species evenly, in no particular order
	--leave one space to carry over the best brain
	local excessPopulation = totalPopulation - (POPULATION_SIZE - 1)
	if excessPopulation ~= 0 then
		local ns = {length = 0}
		for i in pairs(newSizes) do
			if newSizes[i] > 0 then
				ns.length = ns.length + 1
				ns[ns.length] = i
			end
		end
		while excessPopulation > 0 do
			--population too high
			local rand = math.random(ns.length)
			if newSizes[ns[rand]] > 0 then
				newSizes[ns[rand]] = newSizes[ns[rand]] - 1
				excessPopulation = excessPopulation - 1
			end
		end
		
		while excessPopulation < 0 do
			--population too low
			local rand = math.random(ns.length)
			newSizes[ns[rand]] = newSizes[ns[rand]] + 1
			excessPopulation = excessPopulation + 1
		end
	end
	
	for p=1,specieCount do
		if newSizes[p] then
			if p == self.bestBrain.species then
				logFile:write("Species ", p, " size: ", currentSpecies[p].length, " -> ", (newSizes[p] + 1), "\n")
			else
				logFile:write("Species ", p, " size: ", currentSpecies[p].length, " -> ", newSizes[p], "\n")
			end
		end
	end
	
	--step 3
	local newPopulation = {}
	local popCounter = 1
	
	for s in pairs(currentSpecies) do
		if newSizes[s] > 0 then
			--sort all individuals by fitness (hight to low)
			local fits = {}
			local fitLen = 0
			for i=1,currentSpecies[s].length do
				fitLen = fitLen + 1
				fits[fitLen] = currentSpecies[s][i]
			end
			for i=2,fitLen do
				local c1 = i - 1
				local c2 = i
				while c1 >= 1 and fits[c1].fitness < fits[c2].fitness do
					local temp = fits[c1]
					fits[c1] = fits[c2]
					fits[c2] = temp
					c1 = c1 - 1
					c2 = c2 - 1
				end
			end
			--only select top 50% of individuals
			local eligibleParents = {length = 0}
			for i=1,math.ceil(fitLen / 2) do
				eligibleParents.length = eligibleParents.length + 1
				eligibleParents[eligibleParents.length] = fits[i]
			end
			
			if math.random() < FORCE_SEXUAL_REPRODUCTION then
				--force sexual reproduction
				--if there's only one eligible parent, it must be both parents
				if eligibleParents.length == 1 then
					for i=1,newSizes[s] do
						parent1 = eligibleParents[1]
						parent2 = eligibleParents[1]
						
						--make a new brain
						newBrain = Brain:new()
						newBrain.crossover(newBrain,parent1,parent2)
						newBrain.species = parent1.species
						newPopulation[popCounter] = newBrain
						popCounter = popCounter + 1
					end
					
				--if there's only two eligible parents, they must both be a parent
				elseif eligibleParents.length == 2 then
					for i=1,newSizes[s] do
						parent1 = eligibleParents[1]
						parent2 = eligibleParents[2]
						
						--make a new brain
						newBrain = Brain:new()
						newBrain.crossover(newBrain,parent1,parent2)
						newBrain.species = parent1.species
						newPopulation[popCounter] = newBrain
						popCounter = popCounter + 1
					end
					
				--if there's more than two eligible parents, choose two of them to be parents
				--weight the likelihood of each individual being chosen by their fitness
				else
					local lowFit = eligibleParents[eligibleParents.length].fitness
					local epWeighted = {length = 0}
					for i=1,newSizes[s] do
						--create list of eligible parents, where each parent appears a number of times according to their relative fitness
						for j=1,eligibleParents.length do
							local weightedLikelihood = math.floor(eligibleParents[j].fitness / lowFit)
							for k=1,weightedLikelihood do
								epWeighted.length = epWeighted.length + 1
								epWeighted[epWeighted.length] = eligibleParents[j]
							end
						end
						
						--select one parent from that list
						parent1 = epWeighted[math.random(epWeighted.length)]
						
						--remove all instances of the chosen parent from the list
						local m = 1
						while m <= epWeighted.length do
							if epWeighted[m] == parent1 then
								epWeighted[m] = epWeighted[epWeighted.length]
								epWeighted[epWeighted.length] = nil
								epWeighted.length = epWeighted.length - 1
							end
							m = m + 1
						end
						
						--choose the other parent
						parent2 = epWeighted[math.random(epWeighted.length)]
						
						--make a new brain
						newBrain = Brain:new()
						newBrain.crossover(newBrain,parent1,parent2)
						newBrain.species = parent1.species
						newPopulation[popCounter] = newBrain
						popCounter = popCounter + 1
					end
				end
			else
				--allow asexual reproduction
				--if there's only one eligible parent, it must be both parents
				if eligibleParents.length == 1 then
					for i=1,newSizes[s] do
						parent1 = eligibleParents[1]
						parent2 = eligibleParents[1]
						
						--make a new brain
						newBrain = Brain:new()
						newBrain.crossover(newBrain,parent1,parent2)
						newBrain.species = parent1.species
						newPopulation[popCounter] = newBrain
						popCounter = popCounter + 1
					end
					
				--if there's more than one eligible parent, choose two of them with replacement to be parents
				--weight the likelihood of each individual being chosen by their fitness
				else
					local lowFit = eligibleParents[eligibleParents.length].fitness
					local epWeighted = {length = 0}
					for i=1,newSizes[s] do
						--create list of eligible parents, where each parent appears a number of times according to their relative fitness
						for j=1,eligibleParents.length do
							local weightedLikelihood = math.floor(eligibleParents[j].fitness / lowFit)
							for k=1,weightedLikelihood do
								epWeighted.length = epWeighted.length + 1
								epWeighted[epWeighted.length] = eligibleParents[j]
							end
						end
						
						parent1 = epWeighted[math.random(epWeighted.length)]
						parent2 = epWeighted[math.random(epWeighted.length)]
						
						--make a new brain
						newBrain = Brain:new()
						newBrain.crossover(newBrain,parent1,parent2)
						newBrain.species = parent1.species
						newPopulation[popCounter] = newBrain
						popCounter = popCounter + 1
					end
				end
			end
		end
	end
	
	--mutate each new brain at random, then prepare their topology
	for i in pairs(newPopulation) do
		if math.random() < NODE_MUTATION_CHANCE then
			newPopulation[i].mutateAddNode(newPopulation[i])
		end
		if math.random() < CONNECTION_MUTATION_CHANCE then
			newPopulation[i].mutateAddConnection(newPopulation[i])
		end
		if math.random() < DISABLE_MUTATION_CHANCE then
			newPopulation[i].mutateDisable(newPopulation[i])
		end
		if math.random() < WEIGHT_MUTATION_CHANCE then
			newPopulation[i].mutateWeights(newPopulation[i])
		end
		newPopulation[i].prepareNodeTopology(newPopulation[i])
	end
	
	--step 4
	local oldNumSpecies = 0
	for i in pairs(currentSpecies) do
		oldNumSpecies = oldNumSpecies + 1
	end
	
	
	for i,v in ipairs(newPopulation) do
		local found = false
		for j in pairs(currentSpecies) do
			if j == self.bestBrain.species then
				if v.compare(v,self.bestBrain) <= BRAIN_DIFFERENCE_DELTA then
					v.species = j
					found = true
					break
				end
			else
				if v.compare(v,currentSpecies[j][1]) <= BRAIN_DIFFERENCE_DELTA then
					v.species = j
					found = true
					break
				end
			end
		end
		if not found then
			specieCount = specieCount + 1
			logFile:write("Species: " , v.species, " creates subspecies ", specieCount, "\n")
			v.species = specieCount
			currentSpecies[specieCount] = {[1]=v}
		end
	end
	
	newPopulation[popCounter] = self.bestBrain
	self.bestBrain.fitness = bestFit
	
	local newSpecies = {}
	local newNumSpecies = 0
	for i=1,POPULATION_SIZE do
		if not newSpecies[newPopulation[i].species] then
			newSpecies[newPopulation[i].species] = true
			newNumSpecies = newNumSpecies + 1
		end
	end
	logFile:write("Number of species: " , oldNumSpecies, " -> ", newNumSpecies, "\n")
	
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
		end
	else
		o = {}
		o.population={}
		o.generation=1
		o.currentBrain=1
		o.averagePerformance = 0
		o.staleness = 0
		
		for i=1,POPULATION_SIZE do
			newBrain = Brain:new()
			newBrain.initNewBrain(newBrain)
			
			newBrain.prepareNodeTopology(newBrain)
			specieCount = specieCount + 1
			newBrain.species = specieCount
			o.population[i] = newBrain
		end
	end
	
	setmetatable(o, self)
	self.__index = self
	return o
end