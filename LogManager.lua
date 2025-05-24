local LogFiles = loadfile("/SCRIPTS/TOOLS/LogManager/logfiles.lua")()
local logFiles = LogFiles.new()

local UiModel = loadfile("/SCRIPTS/TOOLS/LogManager/uimodel.lua")()
local uiModel = UiModel.new()

local ColorUi = loadfile("/SCRIPTS/TOOLS/LogManager/colorui.lua")()
local colorUi = ColorUi.new(uiModel, logFiles)


local function init()
    if lvgl == nil then return end

    logFiles:read()
    uiModel:update(logFiles)
end 

local function run(event, touchState)
    if lvgl == nil then
        lcd.drawText(0, 0, "LVGL support required", COLOR_THEME_WARNING)
    end
    
    local change = uiModel:getChanged()
    if change ~= UiModel.NO_CHANGE then
        colorUi:update(change)
    end
    return colorUi:getExitCode()
end

return {init = init, run = run, useLvgl=true}
