-- Class UI model
local UiModel = {}
UiModel.__index = UiModel

UiModel.OPTION_ALL_MODELS = 1

UiModel.DELETE_OPTION = {
    DELETE_EMPTY_LOGS = 1,
    KEEP_TODAY = 2,
    KEEP_LATEST_DATE = 3,
    KEEP_LAST_FLIGHT = 4,
    DELETE_LT_10K = 5,
    DELETE_LT_20K = 6,
    DELETE_LT_50K = 7,
    DELETE_LT_100K = 8,
    DELETE_ALL = 9
}

UiModel.NO_CHANGE = 0
UiModel.SELECTION_CHANGED = 1
UiModel.LOGFILES_CHANGED = 2


function UiModel.new()
    local self = setmetatable({}, UiModel)
    self.modelOptions = {}
    self.selectedModelOption = 1
    self.deleteOptions = {
        [UiModel.DELETE_OPTION.DELETE_EMPTY_LOGS] = "Delete empty logs",
        [UiModel.DELETE_OPTION.KEEP_TODAY] = "Keep today",
        [UiModel.DELETE_OPTION.KEEP_LATEST_DATE] = "Keep latest date",
        [UiModel.DELETE_OPTION.KEEP_LAST_FLIGHT] = "Keep last flight",
        [UiModel.DELETE_OPTION.DELETE_LT_10K] = "Delete Logs<10kB",
        [UiModel.DELETE_OPTION.DELETE_LT_20K] = "Delete Logs<20kB",
        [UiModel.DELETE_OPTION.DELETE_LT_50K] = "Delete Logs<50kB",
        [UiModel.DELETE_OPTION.DELETE_LT_100K] = "Delete Logs<100kB",
        [UiModel.DELETE_OPTION.DELETE_ALL] = "Delete all Logs"
    }
    self.selectedDeleteOption = 1
    self.changed = UiModel.NO_CHANGE
    return self
end

function UiModel:update(logFiles)
    self.modelOptions = { "* (all Models)" }
    for _, v in pairs(logFiles:getModels()) do
        self.modelOptions[#self.modelOptions + 1] = v
    end
    self.changed = UiModel.LOGFILES_CHANGED
end

function UiModel:getSelectedModel()
    if self.selectedModelOption == UiModel.OPTION_ALL_MODELS then
        return nil
    else
        return self.modelOptions[self.selectedModelOption]
    end
end

function UiModel:getModelOptions()
    return self.modelOptions
end

function UiModel:getModelOption()
    return self.selectedModelOption
end

function UiModel:setModelOption(index)
    self.selectedModelOption = index
    self.changed = UiModel.SELECTION_CHANGED
end

function UiModel:getDeleteOption()
    return self.selectedDeleteOption
end

function UiModel:setDeleteOption(index)
    self.selectedDeleteOption = index
    self.changed = UiModel.SELECTION_CHANGED
end

function UiModel:getChanged()
    return self.changed
end

function UiModel:resetChanged()
    self.changed = UiModel.NO_CHANGE
end

function UiModel:setChanged(changed)
    self.changed = changed
end

return UiModel
