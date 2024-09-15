local _, ns = ... -- Namespace (myaddon, namespace)

--* Namespace Globals
ns.version, ns.dbVersion = GLH.version, '1.0'
ns.isTesting = false
ns.isPreRelease = true
ns.preReleaseType = 'Pre-Alpha'
ns.versionOut = '(v'..ns.version..(ns.isPreRelease and ' '..ns.preReleaseType or '')..')'

ns.debug = false
ns.commPrefix = 'GLHSync'
C_ChatInfo.RegisterAddonMessagePrefix(ns.commPrefix)

-- Color Globals
ns.GLHColor = 'FF00FFFF'

-- Icon Globals
ns.ICON_PATH = GLH.ICON_PATH
ns.icon = ns.ICON_PATH..'GLH_Icon.tga'

-- Role Icons
ns.DPS_LFR_ICON = 'UI-Frame-DpsIcon' -- Atlas 31x30
ns.TANK_LFR_ICON = 'UI-Frame-TankIcon' -- Atlas 31x30
ns.HEALER_LFR_ICON = 'UI-Frame-HealerIcon' -- Atlas 31x30

ns.RED_CHECK = 'GM-raidMarker2'
ns.GREEN_CHECK = 'Capacitance-General-WorkOrderCheckmark'

-- Highlgiht Images
ns.BLUE_HIGHLIGHT = 'bags-glow-heirloom'
ns.BLUE_LONG_HIGHLIGHT = 'communitiesfinder_card_highlight'

-- Font Globals
ns.ARIAL_FONT = 'Fonts\\ARIAN.ttf'
ns.SKURRI_FONT = 'Fonts\\SKURRI.ttf'
ns.DEFAULT_FONT = 'Fonts\\FRIZQT__.ttf'
ns.MORPHEUS_FONT = 'Fonts\\MORPHEUS.ttf'
ns.DEFAULT_FONT_SIZE = 12

-- Level Colors
ns.COMMON_COLOR = 'ff9d9d9d'
ns.UNCOMMON_COLOR = 'ff1eff00'
ns.RARE_COLOR = 'ff0070dd'
ns.EPIC_COLOR = 'ffa335ee'
ns.LEGENDARY_COLOR = 'ffff8000'

-- Dungeon Colors
ns.LFR_DUNGEON_COLOR = 'ff9d9d9d'
ns.NORMAL_DUNGEON_COLOR = 'ff0070dd'
ns.HEROIC_DUNGEON_COLOR = 'ffa335ee'
ns.MYTHIC_DUNGEON_COLOR = 'ffff8000'