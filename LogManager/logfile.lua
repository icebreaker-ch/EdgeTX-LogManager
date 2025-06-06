-- Class LogFile
local LogFile = {}
LogFile.__index = LogFile
-- pattern modelName, date, time
LogFile.pattern = "(.*)%-(%d%d%d%d%-%d%d%-%d%d)%-(%d%d%d%d%d%d)%.csv$"

function LogFile.new(fileName, info)
    local self = setmetatable({}, LogFile)
    self.fileName = fileName
    self.info = info
    self.modelName, self.date, self.time = string.match(fileName, self.pattern)
    return self
end

function LogFile.isLogFile(fname)
    return string.match(fname, LogFile.pattern)
end

function LogFile:getModelName()
    return self.modelName
end

function LogFile:getFileName()
    return self.fileName
end

function LogFile:getDate()
    return self.date
end

function LogFile:getSize()
    return self.info.size
end

return LogFile