-- Class LogFile
LogFile = { }

function LogFile:new(file_name, info)
    local o = LogFile
    self = setmetatable(o, self)
    self.__index = self
    self.file_name = file_name
    self.model_name = string.sub(file_name, 1, #file_name - 22)
    self.size = info.size
    return o
end

function LogFile.isLogFile(fname)
    return string.sub(fname, #fname -3, #fname) == ".csv"
end

function LogFile:getModelName()
    return self.model_name
end

function LogFile:getFileName()
    return self.file_name
end

function LogFile:getDate()
    return string.sub(self.file_name, #self.file_name - 20, #self.file_name - 11)
end

function LogFile:getSize()
    return self.size
end

return LogFile