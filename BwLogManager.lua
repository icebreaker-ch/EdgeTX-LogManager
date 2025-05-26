local LogFiles = loadfile("/SCRIPTS/TOOLS/LogManager/logfiles.lua")()
local logFiles = LogFiles.new()

local UiModel = loadfile("/SCRIPTS/TOOLS/LogManager/uimodel.lua")()
local uiModel = UiModel.new()

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
local STATE_DONE = 6

local textWidth
local textHeight

local state = STATE_IDLE
local deletedFiles = 0

local function newLine(y, n)
    local lines = n or 1
    return y + lines * (textHeight + 1)
end

local function updateUi()
    lcd.clear()
    local y = 0
    local fileCount = logFiles:getFileCount()
    local modelCount = logFiles:getModelCount()
    lcd.drawText(1, y, "LogManager", INVERS)
    y = newLine(y)
    lcd.drawText(1, y, fileCount .. " Logs for " .. modelCount .. " Model(s)")
    
    y = 20
    if state == STATE_DONE then
        lcd.drawText(1, y, "Purged " .. deletedFiles .. " files")
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

local function handleIdle(event)
    if event == EVT_VIRTUAL_NEXT then
        modelSelector:setState(Selector.STATE_SELECTED)
        state = STATE_CHOICE_MODEL_SELECTED
    elseif event == EVT_VIRTUAL_ENTER_LONG then
        state = STATE_EXECUTING
    end
    updateUi()
    return 0
end

local function handleChoiceModelSelected(event)
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
    updateUi()
    return 0
end

local function handleChoiceModelEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        modelSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        modelSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        modelSelector:setState(Selector.STATE_SELECTED)
        state = STATE_CHOICE_MODEL_SELECTED
    end
    uiModel:setModelOption(modelSelector:getIndex())
    updateUi()
    return 0
end

local function handleChoiceActionSelected(event)
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
    updateUi()
    return 0
end

local function handleChoiceActionEditing(event)
    if event == EVT_VIRTUAL_NEXT then
        actionSelector:incValue()
    elseif event == EVT_VIRTUAL_PREV then
        actionSelector:decValue()
    elseif event == EVT_VIRTUAL_ENTER then
        actionSelector:setState(Selector.STATE_IDLE)
        state = STATE_CHOICE_ACTION_SELECTED
    end
    uiModel:setDeleteOption(actionSelector:getIndex())
    updateUi()
    return 0
end

local function concat(table1, table2)
    for _,v in pairs(table2) do
        table1[#table1 + 1] = v
    end
    return table1
end

function deleteLogs(model, action)
    local filesToDelete = {}

    if action == ACTION_DELETE_EMPTY_LOGS then
        if model then   
            filesToDelete = logFiles:getEmptyLogsForModel(model)
        else -- All models
            for _,m in pairs(logFiles:getModels()) do
                print(m)
                filesToDelete = concat(filesToDelete, logFiles:getEmptyLogsForModel(m))
            end
        end
    elseif action == ACTION_DELETE_ALL then
        if model then
            filesToDelete = logFiles:getLogsForModel(model)
        else -- All models
            filesToDelete = logFiles:getAllLogs()
        end
    elseif action == ACTION_KEEP_LAST_FLIGHT then
        if model then
            filesToDelete = concat(filesToDelete, logFiles:getAllButLast(model))
        else -- All models
            for _,m in pairs(logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, logFiles:getAllButLast(m))
            end
        end
    elseif action == ACTION_KEEP_LATEST_DATE then
        if model then
            filesToDelete = concat(filesToDelete, logFiles:getAllButLastDate(model))
        else -- ALl models
            for _,m in pairs(logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, logFiles:getAllButLastDate(m))
            end
        end
    end

    logFiles:delete(filesToDelete)
end

local function handleExecuting(event)
    local model = uiModel:getSelectedModel()
    local deleteOption = uiModel:getDeleteOption()
    deleteLogs(model, deleteOption)
    state = STATE_DONE
    return 0
end

local function reload()
    logFiles:read()
    uiModel:update(logFiles)
    modelSelector:setValues(uiModel:getModelOptions())
    modelSelector:setIndex(1)
    modelSelector:setState(Selector.STATE_IDLE)

    actionSelector:setIndex(1)
    actionSelector:setState(Selector.STATE_IDLE)
end

local function handleDone(event)
    reload()
    updateUi()
    state = STATE_IDLE
    return 0
end

local function init()
    local w
    if lcd.RGB ~= nil then
        w, textHeight = lcd.sizeText("Hg")
        textWidth = w / 2
    else
        textWidth = 6
        textHeight = 8
    end
    reload()
end

local function run(event)
    local result = 0
    if state == STATE_IDLE then
        result = handleIdle(event)
    elseif state == STATE_CHOICE_MODEL_SELECTED then
        result = handleChoiceModelSelected(event)
    elseif state == STATE_CHOICE_MODEL_EDITING then
        result = handleChoiceModelEditing(event)
    elseif state == STATE_CHOICE_ACTION_SELECTED then
        result = handleChoiceActionSelected(event)
    elseif state == STATE_CHOICE_ACTION_EDITING then
        result = handleChoiceActionEditing(event)
    elseif state == STATE_EXECUTING then
        result = handleExecuting(event)
    elseif state == STATE_DONE then
        result = handleDone()
    end
    return result
end

return {
    init = init, run = run
}