-- Class LogFile
local LogFile = {}
LogFile.__index = LogFile

function LogFile.new(fileName, info)
    local self = setmetatable({}, LogFile)
    self.fileName = fileName
    self.info = info
    self.modelName = string.sub(fileName, 1, #fileName - 22)
    return self
end

function LogFile.isLogFile(fname)
    return string.sub(fname, #fname -3, #fname) == ".csv"
end

function LogFile:getModelName()
    return self.modelName
end

function LogFile:getFileName()
    return self.fileName
end

function LogFile:getDate()
    return string.sub(self.fileName, #self.fileName - 20, #self.fileName - 11)
end

function LogFile:getSize()
    return self.info.size
end

return LogFile