-- Class LogFiles
local LogFile = loadfile("/SCRIPTS/TOOLS/LogManager/logfile.lua")()

local LOG_DIR = "/LOGS"
local LOGFILE_PATTERN = "(.*)%-(%d%d%d%d%-%d%d%-%d%d)%-(%d%d%d%d%d%d)%.csv$"

local function append(table, entry)
    table[#table + 1] = entry
end


local LogFiles = {}
LogFiles.__index = LogFiles

function LogFiles.new()
    local self = setmetatable({}, LogFiles)
    return self
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
            local logFile = LogFile.new(f, info)
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
    return #files
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

-- returns the file count for all models (model == nil) or specific model
function LogFiles:getFileCount(--[[opt]]model)
    if model then
        return #self.map[model]
    else        
        return self.fileCount
    end
end

-- returns the logs for all models (model == nil) or specific model
function LogFiles:getLogs(--[[opt]]model)
    local logs = {}
    if model then
        logs = self.map[model]
    else
        for model in pairs(self.map) do
            for _,log in pairs(self.map[model]) do
                append(logs, log)
            end
        end
    end
    return logs
end

function LogFiles:getLastFlights()
    local result = {}
    for m,v in pairs(self.map) do
        for _,l in pairs(self.map[m]) do
            if not result[m] or l:getFileName() > result[m]:getFileName() then
                result[m] = l
            end
        end
    end
    return result
end

function LogFiles:filter(filterSpec)
    local lastFlights
    if filterSpec.keepLastFlight or filterSpec.keepLastDay then
        lastFlights = self:getLastFlights()
    end

    local now = getDateTime()
    local today = string.format("%04d-%02d-%02d", now.year, now.mon, now.day)


    local result = {}
    local logs = self:getLogs()
    for _,l in pairs(logs) do
        local fileName = l:getFileName()
        local modelName, date, time = string.match(fileName, LOGFILE_PATTERN)
        if (not filterSpec.modelName or modelName == filterSpec.modelName) and
        (not filterSpec.keepToday or date ~= today) and
        (not filterSpec.size or filterSpec.size == l:getSize()) and
        (not filterSpec.keepLastFlight or fileName ~= lastFlights[modelName]:getFileName()) and
        (not filterSpec.keepLastDay or date ~= lastFlights[modelName]:getDate()) then
            result[#result + 1] = l
        end
    end
    return result
end

return LogFiles