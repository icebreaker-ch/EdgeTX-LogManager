local Selector = loadfile("/SCRIPTS/TOOLS/LogManager/selector.lua")()

local LOG_DIR = "/LOGS"

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

local BwUi = {}
BwUi.__index = BwUi

function BwUi.new(uiModel, logFiles)
    local self = setmetatable({}, BwUi)
    self.uiModel = uiModel
    self.logFiles = logFiles
    self.state = STATE_IDLE
    self.deletedFiles = 0
    self.modelSelector = Selector.new()
    self.actionSelector = Selector.new({"Delete empty", "Keep today", "Keep latest date", "Keep last flight", "Delete all" }, 1)

    self.actionSelector:setOnChange(function(index) uiModel:setDeleteOption(index) end)
    self.modelSelector:setOnChange(function(index) uiModel:setModelOption(index) end)
    self.actionSelector = Selector.new(uiModel.deleteOptions, 1)
    self.actionSelector:setOnChange(function(index) uiModel:setDeleteOption(index) end)
    if lcd.RGB ~= nil then
        local w
        w, textHeight = lcd.sizeText("Hg")
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

local function s(number)
    if number == 1 then
        return ""
    else
        return "s"
    end
end

function BwUi:updateUi()
    lcd.clear()
    local LEFT = 0
    local y = 0
    local totalFileCount = self.logFiles:getFileCount()
    local modelCount = self.logFiles:getModelCount()

    lcd.drawText(LEFT, y, "LogManager", INVERS)
    y = newLine(y)
    lcd.drawText(LEFT, y, string.format("%d Log%s for %d Model%s", totalFileCount, s(totalFileCount), modelCount, s(modelCount)))

    y = newLine(y, 1.5)
    if self.state == STATE_REPORT then
        lcd.drawText(LEFT, y, string.format("Purged %d file%s", self.deletedFiles, s(self.deletedFiles)))
        y = newLine(y)
        lcd.drawText(LEFT, y, "Press RTN")
    else
        -- Model Selector
        lcd.drawText(LEFT, y, "Model:")
        lcd.drawText(6 * textWidth, y, self.modelSelector:getValue(), self.modelSelector:getFlags())
        y = newLine(y)

        -- Action Selector
        lcd.drawText(LEFT, y, "Actn:")
        lcd.drawText(6 * textWidth, y, self.actionSelector:getValue(), self.actionSelector:getFlags())

        local modelFileCount = self.logFiles:getFileCount(self.uiModel:getSelectedModel())
        local deleteCount = #self:getFilesToDelete()
        y = newLine(y) + 2

        lcd.drawText(LEFT, y, string.format("Selected: %d/%d file%s", deleteCount, modelFileCount, s(modelFileCount)))

        local statusLine
        if self.state == STATE_CHOICE_MODEL_EDITING then
            statusLine = "Select model"     
        elseif self.state == STATE_CHOICE_ACTION_EDITING then
            statusLine = "Select action"
        elseif self.state == STATE_EXECUTING then
            statusLine = "Executing..."
        elseif deleteCount == 0 then
            statusLine = "No files to delete"
        elseif deleteCount > 0 then
            statusLine = "Long press Enter to delete"
        else
            statusLine = ""
        end
        y = newLine(y) + 2
        lcd.drawText(LEFT, y, statusLine, SMLSIZE)
    end
end

function BwUi:handleIdle(event)
    if event == EVT_VIRTUAL_NEXT then
        self.modelSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_MODEL_SELECTED
    elseif event == EVT_VIRTUAL_ENTER_LONG and #self:getFilesToDelete() > 0 then
        self.state = STATE_EXECUTING
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceModelSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.modelSelector:setState(Selector.STATE_EDITING)
        self.state = STATE_CHOICE_MODEL_EDITING
    elseif event == EVT_VIRTUAL_NEXT or event == EVT_VIRTUAL_PREV then
        self.modelSelector:setState(Selector.STATE_IDLE)
        self.actionSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_ACTION_SELECTED
    elseif event == EVT_VIRTUAL_ENTER_LONG and #self:getFilesToDelete() > 0 then
        self.modelSelector:setState(Selector.STATE_IDLE)
        self.state = STATE_EXECUTING
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceModelEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        self.modelSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        self.modelSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        self.modelSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_MODEL_SELECTED
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceActionSelected(event)
    if event == EVT_VIRTUAL_ENTER then
        self.actionSelector:setState(Selector.STATE_EDITING)
        self.state = STATE_CHOICE_ACTION_EDITING
    elseif event == EVT_VIRTUAL_NEXT or event == EVT_VIRTUAL_PREV then
        self.actionSelector:setState(Selector.STATE_IDLE)
        self.modelSelector:setState(Selector.STATE_SELECTED)
        self.state = STATE_CHOICE_MODEL_SELECTED
    elseif event == EVT_VIRTUAL_ENTER_LONG then
        self.actionSelector:setState(Selector.STATE_IDLE)
        self.state = STATE_EXECUTING
    end
    self:updateUi()
    return 0
end

function BwUi:handleChoiceActionEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        self.actionSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        self.actionSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        self.actionSelector:setState(Selector.STATE_IDLE)
        self.state = STATE_CHOICE_ACTION_SELECTED
    end
    self:updateUi()
    return 0
end

function BwUi:handleReport(event)
    if event == EVT_EXIT_BREAK then
        self.state = STATE_DONE
    else
        self:updateUi()
    end
    return 0
end

function BwUi:handleDone(event)
    self:reload()
    self:updateUi()
    self.state = STATE_IDLE
    return 0
end

function BwUi:getFilesToDelete()
    local filesToDelete = {}
    local selectedModel = self.uiModel:getSelectedModel()
    local deleteOption = self.uiModel:getDeleteOption()

    if deleteOption == self.uiModel.OPTION_DELETE_EMPTY_LOGS then
        filesToDelete = self.logFiles:filter({ modelName = selectedModel, size = 0 })
    elseif deleteOption == self.uiModel.OPTION_DELETE_ALL then
        filesToDelete = self.logFiles:filter({ modelName = selectedModel })
    elseif deleteOption == self.uiModel.OPTION_KEEP_LAST_FLIGHT then
        filesToDelete = self.logFiles:filter({ modelName = selectedModel, keepLastFlight = true })
    elseif deleteOption == self.uiModel.OPTION_KEEP_TODAY then
        filesToDelete = self.logFiles:filter({ modelName = selectedModel, keepToday = true })
    elseif deleteOption == self.uiModel.OPTION_KEEP_LATEST_DATE then
        filesToDelete = self.logFiles:filter({ modelName = selectedModel, keepLastDay = true })
    end
    return filesToDelete
end

<<<<<<< HEAD
=======
function BwUi:getFilesToDelete()
    local filesToDelete = {}
    local selectedModel = self.uiModel:getSelectedModel()
    local deleteOption = self.uiModel:getDeleteOption()

    if deleteOption == self.uiModel.OPTION_DELETE_EMPTY_LOGS then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, size = 0})
    elseif deleteOption == self.uiModel.OPTION_DELETE_ALL then
        filesToDelete = self.logFiles:filter({modelName = selectedModel})
    elseif deleteOption == self.uiModel.OPTION_KEEP_LAST_FLIGHT then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, keepLastFlight = true})
    elseif deleteOption == self.uiModel.OPTION_KEEP_TODAY then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, keepToday = true})
    elseif deleteOption == self.uiModel.OPTION_KEEP_LATEST_DATE then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, keepLastDay = true})
    end
    return filesToDelete
end

>>>>>>> ac8fc267d619dd3e98aa9b288b19e835b21d783a
function BwUi:deleteLogs(model, action)
    local filesToDelete = self:getFilesToDelete()
    self.deletedFiles = self.logFiles:delete(filesToDelete)
end

function BwUi:handleExecuting(event)
    self:deleteLogs()
    self.logFiles:read()
    self.uiModel:update(self.logFiles)
    self.state = STATE_REPORT
    return 0
end

function BwUi:reload()
    self.logFiles:read()
    self.uiModel:update(self.logFiles)
    self.modelSelector:setValues(self.uiModel:getModelOptions())
    self.modelSelector:setIndex(1)
    self.modelSelector:setState(Selector.STATE_IDLE)

    self.actionSelector:setIndex(1)
    self.actionSelector:setState(Selector.STATE_IDLE)
end

function BwUi:run(event)
    local result = 0
    if self.state == STATE_IDLE then
        result = self:handleIdle(event)
    elseif self.state == STATE_CHOICE_MODEL_SELECTED then
        result = self:handleChoiceModelSelected(event)
    elseif self.state == STATE_CHOICE_MODEL_EDITING then
        result = self:handleChoiceModelEditing(event)
    elseif self.state == STATE_CHOICE_ACTION_SELECTED then
        result = self:handleChoiceActionSelected(event)
    elseif self.state == STATE_CHOICE_ACTION_EDITING then
        result = self:handleChoiceActionEditing(event)
    elseif self.state == STATE_EXECUTING then
        result = self:handleExecuting(event)
    elseif self.state == STATE_REPORT then
        result = self:handleReport(event)
    elseif self.state == STATE_DONE then
        result = self:handleDone()
    end
    return result
end

return BwUi
