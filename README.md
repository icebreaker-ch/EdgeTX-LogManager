# LogManager
A tool for managing LOG-Files in an EdgeTX color RC transmitter.
Actions can be performed on all models or a selected model.

![start](https://github.com/user-attachments/assets/ab624f43-ed1d-4521-943b-24e5f55ae9ab)

## Model selection

![modelSelection](https://github.com/user-attachments/assets/b45c827b-fd70-4740-9f43-216a48ceee2f)

## Actions
The following actions can be executed:
- Keep latest date: Keeps all log files for the latest flying day for the selcted model(s).
- Keep last flight: Keeps the latest log file for the selected model(s)
- Delete all Logs: Deletes all log files found for the selected model(s)

![actionSelection](https://github.com/user-attachments/assets/9b90d415-8e73-4459-8181-27d91e86c307)

![confirm](https://github.com/user-attachments/assets/7eaacdd5-11ea-410a-b3af-07ee60db548d)

## Installation
### Color screen Radios
Copy the file `LogManager.lua` to the folder `/SCRIPTS/TOOLS` on your transmitter.
Copy the files `colorui.lua`, `logfile.lua`, `logfiles.lua, `selector.lua` and `uimodel.lua`
to the folder `/SCRIPTS/TOOLS/LogManager`
The structure on your SD card should look like this afterwards:
```
/TOOLS
    LogManager.lua
    :
    /LogManager
        colorui.lua
        logfile.lua
        logfiles.lua
```
### Black and white screen Radios
Copy the file `BwLogManager.lua` to the folder `/SCRIPTS/TOOLS` on your transmitter.
Copy the files `bwui.lua`, `logfile.lua`, `logfiles.lua, `selector.lua` and `uimodel.lua`
to the folder `/SCRIPTS/TOOLS/LogManager`
The structure on your SD card should look like this afterwards:
```
/TOOLS
    LogManager.lua
    :
    /LogManager
        bwui.lua
        logfile.lua
        logfiles.lua
        selector.lua
```

