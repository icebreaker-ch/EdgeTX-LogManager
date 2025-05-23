-- Class LogFiles
local LogFile = loadfile("/SCRIPTS/TOOLS/LogManager/logfile.lua")()

local LOG_DIR = "/LOGS"

LogFiles = {}

function LogFiles:new(o)
    o = o or {}
    self.__index = self
    self = setmetatable(o, self)
    return o
end

function LogFiles:printModel(model)
    for _,v in pairs(self.map[model]) do
        print("    " .. v:getFileName())
    end
end

function LogFiles:printMap()
    for k,_ in pairs(self.map) do
        print(k .. ":")
        self:printModel(k)
    end
end

function LogFiles:read()
    self.fileCount = 0
    self.modelCount = 0
    self.map = {}
    for f in dir(LOG_DIR) do
        if LogFile.isLogFile(f) then
            local info = fstat(LOG_DIR .. "/" .. f)
            local logFile = LogFile:new(nil, f, info)
            local modelName = logFile:getModelName()
            if not self.map[modelName] then
                self.map[modelName] = {}
                self.modelCount = self.modelCount + 1
            end
            self.map[modelName][#self.map[modelName] + 1] = logFile
            self.fileCount = self.fileCount + 1
        end
    end
    -- self:printMap()
end

function LogFiles:delete(files)
    for _,v in pairs(files) do
        del(LOG_DIR .. "/" .. v:getFileName())
    end
end

function LogFiles:getModels()
    local models = {}
    for k,_ in pairs(self.map) do
        models[#models + 1] = k
    end
    return models
end

function LogFiles:getModelCount()
    return self.modelCount
end

function LogFiles:getFileCount()
    return self.fileCount
end

function LogFiles:getAllLogs()
    local logs = {}
    for model in pairs(self.map) do
        for _,log in pairs(self.map[model]) do
            table.insert(logs, log)
        end
    end
    return logs
end

function LogFiles:getLogsForModel(modelName)
    return self.map[modelName]
end

function LogFiles:getEmptyLogsForModel(modelName)
    local logs = {}
    for _,v in pairs(self.map[modelName]) do
        if v:getSize() == 0 then
            table.insert(logs, v)
        end
    end
    return logs
end

function LogFiles:getLastForModel(modelName)
    local last = nil
    for _,v in pairs(self.map[modelName]) do
        if not last or last:getFileName() < v:getFileName() then
            last = v
        end
    end
    return last
end

function LogFiles:getLastDateForModel(modelName)
    local lastDate = nil
    for _,v in pairs(self.map[modelName]) do
        if not lastDate or lastDate < v:getDate() then
            lastDate = v:getDate()
        end
    end
    return lastDate
end

function LogFiles:getAllButLastDate(modelName)
    local logs = {}
    local lastDate = self:getLastDateForModel(modelName);
    for _,v in pairs(self.map[modelName]) do
        if v:getDate() < lastDate then
            table.insert(logs, v)
        end
    end
    return logs
end

function LogFiles:getAllButLast(modelName)
    local logs = {}
    local last = self:getLastForModel(modelName)
    for _,v in pairs(self.map[modelName]) do
        if v:getFileName() ~= last:getFileName() then
            table.insert(logs, v)
        end
    end
    return logs
end

return LogFiles