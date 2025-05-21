-- Class LogFile
LogFile = { file_name = nil, model_name = nil}
LogFile.__index = LogFile

function LogFile.new(file_name)
    local self = setmetatable({}, LogFile)
    self.file_name = file_name
    self.model_name = string.sub(file_name, 1, #file_name - 22)
    return self
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

return LogFile