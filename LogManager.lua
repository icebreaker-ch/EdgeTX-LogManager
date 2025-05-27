local LogFiles = loadfile("/SCRIPTS/TOOLS/LogManager/logfiles.lua")()
local logFiles = LogFiles.new()

local UiModel = loadfile("/SCRIPTS/TOOLS/LogManager/uimodel.lua")()
local uiModel = UiModel.new()

local ColorUi = loadfile("/SCRIPTS/TOOLS/LogManager/colorui.lua")()
local colorUi = ColorUi.new(uiModel, logFiles)

return {init = function() colorUi:init() end, run = function(event, touchState) return colorUi:run(event, touchState) end}
