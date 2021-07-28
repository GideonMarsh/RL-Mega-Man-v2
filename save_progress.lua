--save_progress.lua
--created by Gideon Marsh
--github.com/GideonMarsh
--code for basicSerialize() and saveit() obtained from the book 
--	Programming in Lua by Roberto Ierusalimschy

--manages permanent file storage for the genetic algorithm

function basicSerialize(o)
	if type(o) == "number" then
		return tostring(o)
	elseif type(o) == "boolean" then
		if o then return "true" end
		return "false"
	else   -- assume it is a string
		return string.format("%q", o)
	end
end

function saveit(name, value, saved)
	saved = saved or {}       -- initial value
	io.write(name, " = ")
	if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
		io.write(basicSerialize(value), "\n")
	elseif type(value) == "table" then
		if saved[value] then    -- value already saved?
			io.write(saved[value], "\n")  -- use its previous name
		else
			saved[value] = name   -- save name for next time
			io.write("{}\n")     -- create a new table
			for k,v in pairs(value) do      -- save its fields
				local fieldname = string.format("%s[%s]", name, basicSerialize(k))
				saveit(fieldname, v, saved)
			end
		end
	else
		error("cannot save a " .. type(value))
	end
end

--saves the passed object to the specified file
function saveObject(filename, object)
	io.output(filename)

	local t = {}
	saveit("object", object, t)
	io.flush()
end

--returns true if file exists, false if not
function fileExists(filename)
	local f = io.open(filename,"r")
	if f then
		return true
	else
		return false
	end
end

--recreates and returns the stored object from the specified file
function loadFromFile(filename)
	dofile(filename)
	return object
end
