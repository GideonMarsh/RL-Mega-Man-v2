--log.lua
--created by Gideon Marsh
--github.com/GideonMarsh

--provides functionality for saving information to a log file

require "constants"

logFile = {}

function openLogFile(gen)
	local logFileName = LOG_FILE .. gen .. LOG_FILE_EXT
	logFile = assert(io.open(logFileName, "w"))
end