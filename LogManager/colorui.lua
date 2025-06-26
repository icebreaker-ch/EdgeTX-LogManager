-- Class ColorUi
local ColorUi = {}
ColorUi.__index = ColorUi

function ColorUi.new(uiModel, logFiles)
    local self = setmetatable({}, ColorUi)
    self.uiModel = uiModel
    self.logFiles = logFiles
    self.exitCode = 0
    return self
end

function ColorUi:getFilesToDelete()
    local filesToDelete = {}
    local selectedModel = self.uiModel:getSelectedModel()
    local deleteOption = self.uiModel:getDeleteOption()

    if deleteOption == self.uiModel.DELETE_OPTION.DELETE_EMPTY_LOGS then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, size = 0})
    elseif deleteOption == self.uiModel.DELETE_OPTION.DELETE_ALL then
        filesToDelete = self.logFiles:filter({modelName = selectedModel})
    elseif deleteOption == self.uiModel.DELETE_OPTION.KEEP_LAST_FLIGHT then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, keepLastFlight = true})
    elseif deleteOption == self.uiModel.DELETE_OPTION.KEEP_TODAY then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, keepToday = true})
    elseif deleteOption == self.uiModel.DELETE_OPTION.KEEP_LATEST_DATE then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, keepLastDay = true})
    elseif deleteOption == self.uiModel.DELETE_OPTION.DELETE_LT_10K then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, maxSize = 10000})
    elseif deleteOption == self.uiModel.DELETE_OPTION.DELETE_LT_20K then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, maxSize = 20000})
    elseif deleteOption == self.uiModel.DELETE_OPTION.DELETE_LT_50K then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, maxSize = 50000})
    elseif deleteOption == self.uiModel.DELETE_OPTION.DELETE_LT_100K then
        filesToDelete = self.logFiles:filter({modelName = selectedModel, maxSize = 100000})
    end
    return filesToDelete
end

function ColorUi:onConfirm(filesToDelete)
    self.logFiles:delete(filesToDelete)
    self.logFiles:read()
    self.uiModel:update(self.logFiles)
    self.uiModel:setModelOption(self.uiModel.OPTION_ALL_MODELS)
    self.uiModel:setChanged(self.uiModel.CHANGE.LOGFILES)
end

function ColorUi:onDeleteLogsPressed()
    local filesToDelete = self:getFilesToDelete()

    lvgl.confirm({title = "Delete",
                  message = "Really delete " .. #filesToDelete .. " files?",
                  confirm = function() return self:onConfirm(filesToDelete) end})
end

function ColorUi:updateUi()
    local selectedModel = self.uiModel:getSelectedModel()
    local logFileCount = self.logFiles:getFileCount(selectedModel)
    self.labelLogCount:set({text = logFileCount .. " Logfiles"})

    local filesToDelete = self:getFilesToDelete()
    self.labelDeleteCount:set({text = "Delete " .. #filesToDelete .. "/" .. logFileCount})
end

function ColorUi:redraw()
    local LEFT = 10
    local ROW = { 10, 40, 80, 180 }

    lvgl.clear();

    local page = lvgl.page({title="Log Manager"})

    local fileCount = self.logFiles:getFileCount()
    local modelCount = self.logFiles:getModelCount()

    page:label({x = LEFT, y = ROW[1],
            text = "Found " .. fileCount .. " logfiles for " .. modelCount .. " models"})

    local modelBox = page:box({x = LEFT, y = ROW[2], flexFlow = lvgl.FLOW_ROW, flexPad = lvgl.PAD_LARGE})
    modelBox:label({text = "Select Model(s):"})
    modelBox:choice({title = "Model",
        get = function() return self.uiModel:getModelOption() end,
        set = function(index) return self.uiModel:setModelOption(index) end,
        values = self.uiModel:getModelOptions()})
    self.labelLogCount = modelBox:label({})

    local logFilesBox = page:box({x = LEFT, y = ROW[3], flexFlow = lvgl.FLOW_ROW, flexPad = lvgl.PAD_LARGE})
    logFilesBox:label({text = "Select Logfiles:"})
    logFilesBox:choice({title = "Action",
        get = function() return self.uiModel:getDeleteOption() end,
        set = function(index) return self.uiModel:setDeleteOption(index) end,
        values = self.uiModel.deleteOptions})
    self.labelDeleteCount = logFilesBox:label({})

    local buttonBox = page:box({x = LEFT, y = ROW[4], flexFlow = lvgl.FLOW_ROW, flexPad = lvgl.PAD_LARGE})
    buttonBox:button({w = 100, text = "Exit", press = function() self.exitCode = 1 end})
    buttonBox:button({w = 100, text = "Delete Logs",
        press = function() self:onDeleteLogsPressed() end,
        active = function() return #self:getFilesToDelete() > 0 end})

    self:updateUi()
end

function ColorUi:update(change)    
    if change == self.uiModel.CHANGE.SELECTION then
        self:updateUi()
        self.uiModel:resetChanged()
    elseif change == self.uiModel.CHANGE.LOGFILES then
        self:redraw()
        self.uiModel:resetChanged()
    end
end

function ColorUi:init()
    if lvgl ~= nil then
        self.logFiles:read()
        self.uiModel:update(self.logFiles)
    end
end

function ColorUi:run(event, touchState)
    if lvgl then
        local change = self.uiModel:getChanged()
        if change ~= self.uiModel.CHANGE.NONE then
            self:update(change)
        end
    else
        lcd.clear()
        lcd.drawText(10, 10, "LVGL support required")
    end
    return self.exitCode
end

return ColorUi
