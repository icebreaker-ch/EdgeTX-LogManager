-- Class LogFile
LogFile = {}

function LogFile:new(o, fileName, info)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    o.fileName = fileName
    o.modelName = string.sub(fileName, 1, #fileName - 22)
    o.info = info
    return o
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