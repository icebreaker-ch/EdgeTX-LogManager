#!/usr/bin/env lua

local lfs = require "lfs"

local LOG_DIR = "LOGS"

local function isCsv(fname)
    local l = string.len(fname)
    local ext = string.sub(fname, l - 3, l)
    return ext == ".csv"
end

local function getModelName(fname)
    local l = string.len(fname)
    return string.sub(fname, 1, l - 22)
end

local function getLogFiles()
    local log_files = {}
    for f in lfs.dir(LOG_DIR) do
        if isCsv(f) then
            log_files[#log_files + 1] = f
        end
    end
    return log_files
end

local function getLastLogs(log_files)
    local last_logs = {}
    for k,f in pairs(log_files) do
        local modelName = getModelName(f)
        if (last_logs[modelName] == nil) then
            last_logs[modelName] = f
        elseif f > last_logs[modelName] then
            last_logs[modelName] = f
        end
    end
    return last_logs
end

local function keepFile(fname, keep_files)
    for k,v in pairs(keep_files) do
        if fname == v then
            return true
        end
    end
    return false
end

local function cleanLogs()
    local log_files = getLogFiles()
    local keep_files = getLastLogs(log_files)
    for k,v in pairs(log_files) do
        if not keepFile(v, keep_files) then
            print("delete file " .. v)
        end
    end
end

cleanLogs()