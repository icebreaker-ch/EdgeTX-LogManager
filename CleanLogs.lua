#!/usr/bin/env lua

local LOG_DIR = "/LOGS"
local KEEP_LATEST_DATE = 0
local KEEP_LATEST_LOG = 1
local DELETE_ALL = 2
local EXIT = 3

local menu_items = { "Keep latest date", "Keep latest log", "Delete all", "Exit" }
local selection = 0

local function isLogFile(fname)
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
    for f in dir(LOG_DIR) do
        if isLogFile(f) then
            log_files[#log_files + 1] = f
        end
    end
    return log_files
end

local function getLatestLogs(log_files)
    local keep_files = {}
    for k,f in pairs(log_files) do
        local modelName = getModelName(f)
        if (keep_files[modelName] == nil) then
            keep_files[modelName] = f
        elseif f > keep_files[modelName] then
            keep_files[modelName] = f
        end
    end
    return keep_files
end

local function getDate(fname)
    local l = string.len(fname)
    return string.sub(fname, #fname - 21, #fname - 11)
end

local function getLastDay(log_files)
    local last_day = {}
    -- find latest date for each model
    for k,f in pairs(log_files) do
        local modelName = getModelName(f)
        local date = getDate(f)
        if last_day[modelName] == nil then
            last_day[modelName] = date
        elseif date > last_day[modelName] then
            last_day[modelName] = date
        end
    end

    -- collect files to keep
    local keep_files = {}
    for k,f in pairs(log_files) do
        local modelName = getModelName(f)
        local date = getDate(f)
        if last_day[modelName] == date then
            keep_files[#keep_files + 1] = f
        end
    end
    return keep_files
end

local function keepFile(fname, keep_files)
    for k,v in pairs(keep_files) do
        if fname == v then
            return true
        end
    end
    return false
end

local function cleanLogs(op)
    local log_files = getLogFiles()
    local keep_files
    if op == KEEP_LATEST_DATE then
        keep_files = getLastDay(log_files)
    elseif op == KEEP_LATEST_LOG then
        keep_files = getLatestLogs(log_files)
    elseif op == DELETE_ALL then
        keep_files = {}
    end

    for k,v in pairs(log_files) do
        if not keepFile(v, keep_files) then
            del(LOG_DIR .. "/" .. v)
        end
    end
end

local function drawHeader()
    lcd.drawText(1, 0, "Clean Log Files", INVERS)
    lcd.drawText(1, 10, "For each model:")
end

local function nextItem(list, current)
    if current < #list - 1 then
        current = current + 1
    end
    return current
end

local function prevItem(list, current)
    if current > 0 then
        current = current - 1
    end
    return current
end

local function run(event)
    if event == EVT_VIRTUAL_NEXT then
        selection = nextItem(menu_items, selection)
    elseif event == EVT_VIRTUAL_PREV then
        selection = prevItem(menu_items, selection)
    elseif event == EVT_VIRTUAL_ENTER then
        if selection == EXIT then
            return 1
        else
            cleanLogs(selection)
       end
    end

    lcd.clear()
    drawHeader()
    lcd.drawCombobox(1, 20, 120, menu_items, selection)
    return 0
end

return {
    run = run
}