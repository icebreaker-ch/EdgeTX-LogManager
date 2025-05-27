local LogFiles = loadfile("/SCRIPTS/TOOLS/LogManager/logfiles.lua")()
local logFiles = LogFiles.new()

local UiModel = loadfile("/SCRIPTS/TOOLS/LogManager/uimodel.lua")()
local uiModel = UiModel.new()

local BwUi = loadfile("/SCRIPTS/TOOLS/LogManager/bwui.lua")()
local bwUi = BwUi.new(uiModel, logFiles)


return {init = function() bwUi:reload() end, run = function(event) return bwUi:run(event) end}