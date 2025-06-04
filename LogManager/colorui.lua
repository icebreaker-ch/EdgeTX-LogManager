local function concat(table1, table2)
    local result = table1
    for _,v in pairs(table2) do
        table.insert(table1, v)
    end
    return result
end

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

    if deleteOption == self.uiModel.OPTION_DELETE_EMPTY_LOGS then
        if selectedModel then
            filesToDelete = self.logFiles:getEmptyLogsForModel(selectedModel)
        else -- All models
            for _,m in pairs(self.logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, self.logFiles:getEmptyLogsForModel(m))
            end
        end
    elseif deleteOption == self.uiModel.OPTION_DELETE_ALL then
        filesToDelete = self.logFiles:getLogs(selectedModel)
    elseif deleteOption == self.uiModel.OPTION_KEEP_LAST_FLIGHT then
        if selectedModel then
            filesToDelete = concat(filesToDelete, self.logFiles:getAllButLast(selectedModel))
        else -- All models
            for _,m in pairs(self.logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, self.logFiles:getAllButLast(m))
            end
        end
    elseif deleteOption == self.uiModel.OPTION_KEEP_TODAY then
        if selectedModel then
            filesToDelete = concat(filesToDelete, self.logFiles:getAllButToday(selectedModel))
        else -- ALl models
            for _,m in pairs(self.logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, self.logFiles:getAllButToday(m))
            end
        end
    elseif deleteOption == self.uiModel.OPTION_KEEP_LATEST_DATE then
        if selectedModel then
            filesToDelete = concat(filesToDelete, self.logFiles:getAllButLastDate(selectedModel))
        else -- ALl models
            for _,m in pairs(self.logFiles:getModels()) do
                filesToDelete = concat(filesToDelete, self.logFiles:getAllButLastDate(m))
            end
        end
    end
    return filesToDelete
end

function ColorUi:onConfirm(filesToDelete)
    self.logFiles:delete(filesToDelete)
    self.logFiles:read()
    self.uiModel:update(self.logFiles)
    self.uiModel:setModelOption(self.uiModel.OPTION_ALL_MODELS)
    self.uiModel:setChanged(self.uiModel.LOGFILES_CHANGED)
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
    if change == self.uiModel.SELECTION_CHANGED then
        self:updateUi()
        self.uiModel:resetChanged()
    elseif change == self.uiModel.LOGFILES_CHANGED then
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
        if change ~= self.uiModel.NO_CHANGE then
            self:update(change)
        end
    else
        lcd.clear()
        lcd.drawText(10, 10, "LVGL support required")
    end
    return self.exitCode
end

return ColorUi
