local LOG_DIR = "/LOGS"
local ACTION_KEEP_LATEST_DATE = 0
local ACTION_KEEP_LATEST_LOG = 1
local ACTION_DELETE_ALL = 2

local STATE_START = 0
local STATE_SELECTING = 1
local STATE_EXECUTING = 2
local STATE_DONE = 3

local textWidth
local textHeight

Selection = { values = {}, current = 0, STATE_IDLE = 0, STATE_SELECTED = 1, STATE_EDITING = 2}
Selection.__index = Selection

function Selection.new(values, current)
    local self = setmetatable({}, Selection)
    self.current = current
    self.values = values
    self.state = self.STATE_IDLE
    return self
end

function Selection:setState(newState)
    self.state = newState
end

function Selection:getState()
    return self.state
end

function Selection:getIndex()
    return self.current
end

function Selection:getValue()
    return self.values[self.current]
end

function Selection:incValue()
    if self.current < #self.values then
        self.current = self.current + 1
    end
end

function Selection:decValue()
    if self.current > 1 then
        self.current = self.current - 1
    end
end

local actionSelector = Selection.new({"Keep latest date", "Keep latest log", "Delete all" }, 1)

local state = STATE_START
local deletedFiles = 0

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

local function cleanLogs(action)
    local log_files = getLogFiles()
    local keep_files
    local deleteCount = 0
    if action == ACTION_KEEP_LATEST_DATE then
        keep_files = getLastDay(log_files)
    elseif action == ACTION_KEEP_LATEST_LOG then
        keep_files = getLatestLogs(log_files)
    elseif action == ACTION_DELETE_ALL then
        keep_files = {}
    end

    for k,v in pairs(log_files) do
        if not keepFile(v, keep_files) then
            del(LOG_DIR .. "/" .. v)
            deleteCount = deleteCount + 1
        end
    end
    return deleteCount
end

local function newLine(y, n)
    local lines = n or 1
    return y + lines * (textHeight + 1)
end

local function updateGui()
    lcd.clear()
    local y = 0
    lcd.drawText(1, y, "LogCleaner", INVERS)
    y = newLine(y, 2)

    if state == STATE_DONE then
        lcd.drawText(1, y, "Purged " .. deletedFiles .. " files")
        y = newLine(y)
        lcd.drawText(1, y, "Press RTN")
    else
        local y = 20
        lcd.drawText(1, y, "For each model:")
        y = newLine(y)
        if state == STATE_START then
            lcd.drawText(2 * textWidth, y, actionSelector:getValue(), INVERS)
        elseif state == STATE_SELECTING then
            lcd.drawText(2 * textWidth, y, actionSelector:getValue(), BLINK)
        end
        y = newLine(y)
        lcd.drawText(1, y, "Long press Enter")
        y = newLine(y)
        lcd.drawText(1, y, "to exectue")
    end
end

local function handleStart(event)
    updateGui()
    if event == EVT_VIRTUAL_ENTER then
        state = STATE_SELECTING
        actionSelector:setState(Selection.STATE_EDITING)
    elseif event == EVT_VIRTUAL_ENTER_LONG then
        state = STATE_EXECUTING
        actionSelector:setState(Selection.STATE_IDLE)
    end
    return 0
end

local function handleSelecting(event)
    updateGui()
    if event == EVT_VIRTUAL_NEXT then
        actionSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        actionSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        state = STATE_START
    end
    return 0
end

local function handleExecuting(event)
    local action = actionSelector:getIndex()
    deletedFiles = cleanLogs(action)
    state = STATE_DONE
    return 0
end

local function handleDone(event)
    updateGui()
    if event == EVT_EXIT_BREAK then
        state = STATE_START
    end
    return 0
end

local function init()
    local w
    if lcd.RGB ~= nil then
        w, textHeight = lcd.sizeText("Hg")
        textWidth = w / 2
    else
        textWidth = 8
        textHeight = 8
    end
end

local function run(event)
    local result = 0
    if state == STATE_START then
        result = handleStart(event)
    elseif state == STATE_SELECTING then
        result = handleSelecting(event)
    elseif state == STATE_EXECUTING then
        result = handleExecuting(event)
    elseif state == STATE_DONE then
        result = handleDone(event)
    end
    return result
end

return {
    init = init, run = run
}