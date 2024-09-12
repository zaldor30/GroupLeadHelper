-- Localization file for English/United States
local L = LibStub("AceLocale-3.0"):NewLocale("GroupLeadHelper", "enUS", true)
if not L then return end

L['HELP'] = 'Help'
L['CONFIG'] = 'Config'
L['MINIMAP'] = 'Minimap'

L['MISSING_ADDON_1'] = 'GLH uses Details! therefore, Details! must be running.'
L['MISSING_ADDON_2'] = 'Details! is not loaded.  Shutting down GLH.'

L['GLH_ACTIVE'] = 'GLH is active:'
L['GLH_INACTIVE'] = 'GLH is inactive, you are not in a group.'
L['GLH_INACTIVE_NOT_LEADER'] = 'GLH is inactive, you are not the leader or assistant.'

L['SLASH_COMMANDS'] = [[
GLH Command Help:
|cFF00FF00/glh|r to show/hide the main window.
|cFF00FF00/glh help|r to show command options.
|cFF00FF00/glh config|r to open configurations.
|cFF00FF00/glh minimap|r to show/hide the minimap icon.]]

L['MINIMAP_TOOLTIP'] = [[
|cFF00FF00/glh help|r to show command options.

|cFF00FF00Left Click|r to show/hide the main window.
|cFF00FF00Right Click|r to show the options menu.]]