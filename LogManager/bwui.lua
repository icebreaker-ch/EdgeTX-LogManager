local Selector = loadfile("/SCRIPTS/TOOLS/LogManager/selector.lua")()
local modelSelector = Selector.new()
local actionSelector = Selector.new({"Delete empty", "Keep latest date", "Keep last flight", "Delete all" }, 1)

local LOG_DIR = "/LOGS"

local ACTION_DELETE_EMPTY_LOGS = 1
local ACTION_KEEP_LATEST_DATE = 2
local ACTION_KEEP_LAST_FLIGHT = 3
local ACTION_DELETE_ALL = 4

local STATE_IDLE = 0
local STATE_CHOICE_MODEL_SELECTED = 1
local STATE_CHOICE_ACTION_SELECTED = 2
local STATE_CHOICE_MODEL_EDITING = 3
local STATE_CHOICE_ACTION_EDITING = 4
local STATE_EXECUTING = 5
local STATE_REPORT = 6
local STATE_DONE = 7

local textWidth
local textHeight
local state = STATE_IDLE

local BwUi = {}
BwUi.__index = BwUi

function BwUi.new(uiModel, logFiles)
    local self = setmetatable({}, BwUi)
    self.uiModel = uiModel
    self.logFiles = logFiles
    self.deletedFiles = 0

    actionSelector:setOnChange(function(index) uiModel:setDeleteOption(index) end)
    modelSelector:setOnChange(function(index) uiModel:setModelOption(index) end)
    if lcd.RGB ~= nil then
        local w, textHeight = lcd.sizeText("Hg")
        textWidth = w / 2
    else
        textWidth = 6
        textHeight = 8
    end

    return self
end

local function newLine(y, n)
    local lines = n or 1
    return y + lines * (textHeight + 1)
end

function BwUi:updateUi()
    lcd.clear()
    local y = 0
    local fileCount = self.logFiles:getFileCount()
    local modelCount = self.logFiles:getModelCount()
    lcd.drawText(1, y, "LogManager", INVERS)
    y = newLine(y)
    lcd.drawText(1, y, fileCount .. " Logs for " .. modelCount .. " Model(s)")
    
    y = 20
    if state == STATE_REPORT then
        lcd.drawText(1, y, "Purged " .. self.deletedFiles .. " files")
        y = newLine(y)
        lcd.drawText(1, y, "Press RTN")
    else
        -- Model Selector
        lcd.drawText(1, y, "Model:")
        lcd.drawText(6 * textWidth, y, modelSelector:getValue(), modelSelector:getFlags())
        y = newLine(y)

        -- Action Selector
        lcd.drawText(1, y, "Actn:")
        lcd.drawText(6 * textWidth, y, actionSelector:getValue(), actionSelector:getFlags())
        y = newLine(y)

        lcd.drawText(1, y, "Long press Enter")
        y = newLine(y)
        lcd.drawText(1, y, "to exectue")
    end
end

function BwUi:handleIdle(event)
    if event == EVT_VIRTUAL_NEXT then
        modelSelector:setState(Selector.STATE_SELECTED)
        state = STATE_CHOICE_MODEL_SELECTED
    elseif event == EVT_VIRTUAL_ENTER_LONG then
        state = STATE_EXECUTING
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceModelSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        modelSelector:setState(Selector.STATE_EDITING)
        state = STATE_CHOICE_MODEL_EDITING
    elseif event == EVT_VIRTUAL_NEXT or event == EVT_VIRTUAL_PREV then
        modelSelector:setState(Selector.STATE_IDLE)
        actionSelector:setState(Selector.STATE_SELECTED)
        state = STATE_CHOICE_ACTION_SELECTED
    elseif event == EVT_VIRTUAL_ENTER_LONG then
        modelSelector:setState(Selector.STATE_IDLE)
        state = STATE_EXECUTING
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceModelEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        modelSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        modelSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        modelSelector:setState(Selector.STATE_SELECTED)
        state = STATE_CHOICE_MODEL_SELECTED
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceActionSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        actionSelector:setState(Selector.STATE_EDITING)
        state = STATE_CHOICE_ACTION_EDITING
    elseif event == EVT_VIRTUAL_NEXT or event == EVT_VIRTUAL_PREV then
        actionSelector:setState(Selector.STATE_IDLE)
        modelSelector:setState(Selector.STATE_SELECTED)
        state = STATE_CHOICE_MODEL_SELECTED
    elseif event == EVT_VIRTUAL_ENTER_LONG then
        actionSelector:setState(Selector.STATE_IDLE)
        state = STATE_EXECUTING
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceActionEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        actionSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        actionSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        actionSelector:setState(Selector.STATE_IDLE)
        state = STATE_CHOICE_ACTION_SELECTED
    end
    self:updateUi()
    return 0
end

local function concat(table1, table2)
    for _,v in pairs(table2) do
        table1[#table1 + 1] = v
    end
    return table1
end

function BwUi:deleteLogs(model, action)
    local filesToDelete = {}

    if action == ACTION_DELETE_EMPTY_LOGS then
        if model then   
            filesToDelete = self.logFiles:getEmptyLogsForModel(model)
        else -- All models
            for _,m in pairs(self.logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, self.logFiles:getEmptyLogsForModel(m))
            end
        end
    elseif action == ACTION_DELETE_ALL then
        if model then
            filesToDelete = self.logFiles:getLogsForModel(model)
        else -- All models
            filesToDelete = self.logFiles:getAllLogs()
        end
    elseif action == ACTION_KEEP_LAST_FLIGHT then
        if model then
            filesToDelete = concat(filesToDelete, self.logFiles:getAllButLast(model))
        else -- All models
            for _,m in pairs(self.logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, self.logFiles:getAllButLast(m))
            end
        end
    elseif action == ACTION_KEEP_LATEST_DATE then
        if model then
            filesToDelete = concat(filesToDelete, self.logFiles:getAllButLastDate(model))
        else -- ALl models
            for _,m in pairs(self.logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, self.logFiles:getAllButLastDate(m))
            end
        end
    end

    self.deletedFiles = self.logFiles:delete(filesToDelete)
end

function BwUi:handleExecuting(event)
    local model = self.uiModel:getSelectedModel()
    local deleteOption = self.uiModel:getDeleteOption()
    self:deleteLogs(model, deleteOption)
    self.logFiles:read()
    self.uiModel:update(self.logFiles)
    state = STATE_REPORT
    return 0
end

function BwUi:reload()
    self.logFiles:read()
    self.uiModel:update(self.logFiles)
    modelSelector:setValues(self.uiModel:getModelOptions())
    modelSelector:setIndex(1)
    modelSelector:setState(Selector.STATE_IDLE)

    actionSelector:setIndex(1)
    actionSelector:setState(Selector.STATE_IDLE)
end

function BwUi:handleReport(event)
    if event == EVT_EXIT_BREAK then
        state = STATE_DONE
    else
        self:updateUi()
    end
    return 0
end

function BwUi:handleDone(event)
    self:reload()
    self:updateUi()
    state = STATE_IDLE
    return 0
end

function BwUi:run(event)
    local result = 0
    if state == STATE_IDLE then
        result = self:handleIdle(event)
    elseif state == STATE_CHOICE_MODEL_SELECTED then
        result = self:handleChoiceModelSelected(event)
    elseif state == STATE_CHOICE_MODEL_EDITING then
        result = self:handleChoiceModelEditing(event)
    elseif state == STATE_CHOICE_ACTION_SELECTED then
        result = self:handleChoiceActionSelected(event)
    elseif state == STATE_CHOICE_ACTION_EDITING then
        result = self:handleChoiceActionEditing(event)
    elseif state == STATE_EXECUTING then
        result = self:handleExecuting(event)
    elseif state == STATE_REPORT then
        result = self:handleReport(event)
    elseif state == STATE_DONE then
        result = self:handleDone()
    end
    return result
end

return BwUi
