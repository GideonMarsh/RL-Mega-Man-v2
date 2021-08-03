--ga.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--the class for handling the genetic algorithm

require "constants"
require "brain"
require "log"

--the prototype for GeneticAlgorithmController objects
--GeneticAlgorithmController objects maintain the population of brains being used in the genetic algorithm
--the main driver should not have access to brain objects directly

GeneticAlgorithmController = {population={},species={},generation=0,currentBrain=0}

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
	--	remove stale species
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
	local totalPopulation = 0
	for i in pairs(currentSpecies) do
		local sumFitness = 0
		for j in pairs(currentSpecies[i]) do
			if j ~= "length" then
				sumFitness = sumFitness + currentSpecies[i][j].fitness
			end
		end
		newSizes[i] = math.floor(sumFitness / meanFitness)
		totalPopulation = totalPopulation + newSizes[i]
		logFile:write("Species ", i, " sum adjusted fitnesses: ", sumFitness, "\n")
		local speciesAveFit = sumFitness / currentSpecies[i].length
		if self.species[i].highestFitness < speciesAveFit then
			self.species[i].highestFitness = speciesAveFit
			self.species[i].staleCounter = 0
		else
			self.species[i].staleCounter = self.species[i].staleCounter + 1
		end
	end
	
	--check if species are stale and remove them
	--never remove the species that best brain is a part of
	for i in pairs(self.species) do
		if self.species[i].staleCounter >= STALE_SPECIES_CUTOFF and not i == self.bestBrain.species then
			self.species[i].staleCounter = -1
			newSizes[i] = 0
			logFile:write("Stale species removed: ", i, "\n")
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
		local s = 1
		while excessPopulation > 0 do
			--population too high
			newSizes[ns[s]] = newSizes[ns[s]] - 1
			excessPopulation = excessPopulation - 1
			s = (s % ns.length) + 1
		end
		
		while excessPopulation < 0 do
			--population too low
			newSizes[ns[s]] = newSizes[ns[s]] + 1
			excessPopulation = excessPopulation + 1
			s = (s % ns.length) + 1
		end
	end
	
	for p in pairs(newSizes) do
		logFile:write("Species ", p, " size: ", currentSpecies[p].length, " -> ", newSizes[p], "\n")
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
		end
	end
	
	--mutate each new brain at random, then prepare their topology
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
		for j in pairs(self.species) do
			if v.compare(v,self.species[j].representative) <= BRAIN_DIFFERENCE_DELTA then
				v.species = j
				found = true
				break
			end
		end
		if not found then
			local newSpeciesCounter = 1
			local newSpecies = v.species .. "." .. newSpeciesCounter
			while self.species[newSpecies] do
				newSpeciesCounter = newSpeciesCounter + 1
				newSpecies = v.species .. "." .. newSpeciesCounter
			end
			self.species[newSpecies] = {}
			self.species[newSpecies].representative = v
			self.species[newSpecies].staleCounter = 0
			self.species[newSpecies].highestFitness = 0
			v.species = newSpecies
			logFile:write("New Species: ", newSpecies, "\n")
		end
	end
	
	newPopulation[popCounter] = self.bestBrain
	self.bestBrain.fitness = bestFit
	
	self.currentBrain = 1
	self.generation = self.generation + 1
	
	self.population = newPopulation
	
	--check to see which species are extinct
	for i in pairs(self.species) do
		if self.species[i].staleCounter >= 0 then
			local matched = false
			for j,v in ipairs(self.population) do
				if v.species == i then 
					matched = true
					break
				end
			end
			if not matched then self.species[i].staleCounter = -1 end
		end
	end
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
		for i in pairs(o.species) do
			o.species[i].representative = Brain:new(o.species[i].representative)
		end
	else
		o = {}
		o.population={}
		o.generation=1
		o.currentBrain=1
		o.species={}
		
		for i=1,POPULATION_SIZE do
			newBrain = Brain:new()
			newBrain.initNewBrain(newBrain)
			
			newBrain.prepareNodeTopology(newBrain)
			o.population[i] = newBrain
		end
		
		local initialSpeciesCounter = 1
		for i,v in ipairs(o.population) do
			local found = false
			for j in pairs(o.species) do
				if v.compare(v,o.species[j].representative) <= BRAIN_DIFFERENCE_DELTA then
					v.species = j
					found = true
					break
				end
			end
			if not found then
				o.species[initialSpeciesCounter .. ""] = {}
				o.species[initialSpeciesCounter .. ""].representative = v
				o.species[initialSpeciesCounter .. ""].staleCounter = 0
				o.species[initialSpeciesCounter .. ""].highestFitness = 0
				v.species = initialSpeciesCounter .. ""
				initialSpeciesCounter = initialSpeciesCounter + 1
			end
		end
	end
	
	setmetatable(o, self)
	self.__index = self
	return o
end