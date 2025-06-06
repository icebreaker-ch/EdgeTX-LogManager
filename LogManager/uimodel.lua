-- Class UI model
local UiModel = {}
UiModel.__index = UiModel

UiModel.OPTION_ALL_MODELS = 1

UiModel.OPTION_DELETE_EMPTY_LOGS = 1
UiModel.OPTION_KEEP_TODAY = 2
UiModel.OPTION_KEEP_LATEST_DATE = 3
UiModel.OPTION_KEEP_LAST_FLIGHT = 4
UiModel.OPTION_DELETE_ALL = 5

UiModel.NO_CHANGE = 0
UiModel.SELECTION_CHANGED = 1
UiModel.LOGFILES_CHANGED = 2


function UiModel.new()
    local self = setmetatable({}, UiModel)
    self.modelOptions = {}
    self.selectedModelOption = 1
    self.deleteOptions = {"Delete empty logs", "Keep today", "Keep latest date", "Keep last flight", "Delete all Logs" }
    self.selectedDeleteOption = 1
    self.changed = UiModel.NO_CHANGE
    return self
end

function UiModel:update(logFiles)
   self.modelOptions = { "* (all Models)" }
    for _,v in pairs(logFiles:getModels()) do
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

function UiModel:setChanged (changed)
    self.changed = changed
end

return UiModel