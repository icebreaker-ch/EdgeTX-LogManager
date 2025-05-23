-- Class UI model
local UiModel = {}

UiModel.OPTION_ALL_MODELS = 1
UiModel.OPTION_DELETE_EMPTY_LOGS = 1
UiModel.OPTION_KEEP_LATEST_DATE = 2
UiModel.OPTION_KEEP_LAST_FLIGHT = 3
UiModel.OPTION_DELETE_ALL = 4

function UiModel:new()
    local o = UiModel
    self.__index = self
    self = setmetatable(o, self)
    self.modelOptions = {}
    self.selectedModelOption = 1
    self.deleteOptions = {"Delete empty logs", "Keep latest date", "Keep last flight", "Delete all Logs" }
    self.selectedDeleteOption = 1
    return o
end

function UiModel:update(logFiles)
   self.modelOptions = { "* (all Models)" }
    for _,v in pairs(logFiles:getModels()) do
        self.modelOptions[#self.modelOptions + 1] = v
    end
end

function UiModel:getSelectedModel()
    if self.selectedModelOption == UiModel.OPTION_ALL_MODELS then
        return nil
    else
        return self.modelOptions[self.selectedModelOption]
    end
end
    
function UiModel:getModelOption()
    return self.selectedModelOption
end

function UiModel:setModelOption(index)
    self.selectedModelOption = index
end

function UiModel:getDeleteOption()
    return self.selectedDeleteOption
end

function UiModel:setDeleteOption(index)
    self.selectedDeleteOption = index
end

return UiModel