
local exitCode = 0
local uiChanged = false

local LogFiles = loadfile("/SCRIPTS/TOOLS/LogManager/logfiles.lua")()
local logFiles = LogFiles:new()

local labelLogCount

local UiModel = loadfile("/SCRIPTS/TOOLS/LogManager/uimodel.lua")()
local uiModel = UiModel:new()

local function updateLogCount()
    local logFileCount
    local selectedModel = uiModel:getSelectedModel()
    if not selectedModel then -- All Models
            logFileCount = logFiles:getFileCount()
    else
            logFileCount = #logFiles:getLogsForModel(selectedModel)
    end
    labelLogCount:set({text = logFileCount .. " Logfiles"})
end

local function setModelOption(index)
    uiModel:setModelOption(index)
    updateLogCount()
end

local function concat(table1, table2)
    local result = table1
    for _,v in pairs(table2) do
        table.insert(table1, v)
    end
    return result
end

local function onExitPressed()
    exitCode = 1
end

local function onConfirm(filesToDelete)
    logFiles:delete(filesToDelete)
    logFiles:read()
    uiModel:update(logFiles)
    uiModel:setModelOption(UiModel.OPTION_ALL_MODELS)
    uiChanged = true
end

local function onDeleteLogsPressed()

    local filesToDelete = {}
    local model = uiModel:getSelectedModel()
    local deleteOption = uiModel:getDeleteOption()

    if deleteOption == UiModel.OPTION_DELETE_EMPTY_LOGS then
        if model then
            filesToDelete = logFiles:getEmptyLogsForModel(model)
        else -- All models
            for _,m in pairs(logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, logFiles:getEmptyLogsForModel(m))
            end
        end
    elseif deleteOption == UiModel.OPTION_DELETE_ALL then
        if model then
            filesToDelete = logFiles:getLogsForModel(model)
        else -- All models
            filesToDelete = logFiles:getAllLogs()
        end
    elseif deleteOption == UiModel.OPTION_KEEP_LAST_FLIGHT then
        if model then
            filesToDelete = concat(filesToDelete, logFiles:getAllButLast(model))
        else -- All models
            for _,m in pairs(logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, logFiles:getAllButLast(m))
            end
        end
    elseif deleteOption == UiModel.OPTION_KEEP_LATEST_DATE then
        if model then
            filesToDelete = concat(filesToDelete, logFiles:getAllButLastDate(model))
        else -- ALl models
            for _,m in pairs(logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, logFiles:getAllButLastDate(m))
            end
        end
    end

    if #filesToDelete > 0 then
        lvgl.confirm({title = "Delete",
                      message = "Really delete " .. #filesToDelete .. " files?",
                      confirm = function() return onConfirm(filesToDelete) end})
    else
        lvgl.message({title = "Message", message = "No files to delete", details = "Press RTN to continue"})
    end
end

local function redraw()
    local COL = { 10, 150, 300 }
    local ROW = { 10, 40, 80, 180 }

    lvgl.clear();

    local page = lvgl.page({title="Log Manager"})

    local fileCount = logFiles:getFileCount()
    local modelCount = logFiles:getModelCount()

    page:label({x=COL[1], y = ROW[1],
            text = "Found " .. fileCount .. " logfiles for " .. modelCount .. " models"})

    page:label({x = COL[1], y = ROW[2], text = "Select Model(s):"})
    page:choice({x = COL[2], y = ROW[2],
        title = "Model",
        get = function() return uiModel:getModelOption() end,
        set = setModelOption,
        values = uiModel.modelOptions})
    local logFileCount = 0
    labelLogCount = page:label({x = COL[3], y= ROW[2]})
    updateLogCount()

    page:label({x = COL[1], y = ROW[3], text = "Select Logfiles:"})
    page:choice({x = COL[2], y = ROW[3],
        title = "Action",
        get = function() return uiModel:getDeleteOption() end,
        set = function(index) return uiModel:setDeleteOption(index) end,
        values = uiModel.deleteOptions})

    local box = page:box({x = COL[1], y = ROW[4], flexFlow = lvgl.FLOW_ROW, flexPad = 20})
    box:button({w = 100, text = "Exit", press = onExitPressed})
    box:button({w = 100, text = "Delete Logs", press = onDeleteLogsPressed})
end

local function init()
    if lvgl == nil then return end

    logFiles:read()
    uiModel:update(logFiles)
    uiChanged = true
end

local function run(event, touchState)
    if lvgl == nil then
        lcd.drawText(0, 0, "LVGL support required", COLOR_THEME_WARNING)
    end
    
    if uiChanged then
        redraw()
        uiChanged = false
    end
    return exitCode
end

return {init = init, run = run, useLvgl=true}
