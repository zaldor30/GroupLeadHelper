local _, ns = ... -- Namespace (myaddon, namespace)

--* Namespace Globals
ns.version, ns.dbVersion = GLH.version, '1.0'
ns.isTesting = false
ns.isPreRelease = true
ns.preReleaseType = 'Alpha'
ns.versionOut = '(v'..ns.version..(ns.isPreRelease and ' '..ns.preReleaseType or '')..')'

ns.debug = false
ns.commPrefix = 'GLHSync'
C_ChatInfo.RegisterAddonMessagePrefix(ns.commPrefix)

-- Color Globals
ns.GLHColor = 'FF00FFFF'
-- Level Colors
ns.COMMON_COLOR = 'ff9d9d9d'
ns.UNCOMMON_COLOR = 'ff1eff00'
ns.RARE_COLOR = 'ff0070dd'
ns.EPIC_COLOR = 'ffa335ee'
ns.LEGENDARY_COLOR = 'ffff8000'

-- Icon Globals
ns.ICON_PATH = GLH.ICON_PATH
ns.icon = ns.ICON_PATH..'GLH_Icon.tga'

--* Atlas Images
ns.HORDE_SMALL_BACKDROP = 'Campaign_Horde'
ns.ALLIANCE_SMALL_BACKDROP = 'Campaign_Alliance'
ns.HORDE_HEADER = 'Objective-Header-CampaignHorde'
ns.ALLIANCE_HEADER = 'Objective-Header-CampaignAlliance'

-- Role Icons
ns.DPS_LFR_ICON = 'UI-Frame-DpsIcon' -- Atlas 31x30
ns.TANK_LFR_ICON = 'UI-Frame-TankIcon' -- Atlas 31x30
ns.HEALER_LFR_ICON = 'UI-Frame-HealerIcon' -- Atlas 31x30
ns.UNKNOWN_LFR_ICON = 'legendaryactivequesticon'--'UI-Frame-GroupRoleIcon' -- Atlas 31x30

ns.RED_CHECK = 'GM-raidMarker2'
ns.GREEN_CHECK = 'Capacitance-General-WorkOrderCheckmark'

-- Highlgiht Images
ns.BLUE_HIGHLIGHT = 'bags-glow-heirloom'
ns.BLUE_LONG_HIGHLIGHT = 'communitiesfinder_card_highlight'

ns.MOVE_LOCKED = 'gficon-chest-evergreen-greatvault-incomplete' --'pvptalents-talentborder-locked' --'Professions_Specialization_Lock'
ns.MOVE_UNLOCKED = 'gficon-chest-evergreen-greatvault-complete' --'pvptalents-talentborder'
ns.MOVE_HIGHLIGHT = 'gficon-chest-evergreen-greatvault-collect' --'pvptalents-talentborder-glow' --'Professions_Specialization_Lock_Glow'

-- Font Globals
ns.ARIAL_FONT = 'Fonts\\ARIAN.ttf'
ns.SKURRI_FONT = 'Fonts\\SKURRI.ttf'
ns.DEFAULT_FONT = 'Fonts\\FRIZQT__.ttf'
ns.MORPHEUS_FONT = 'Fonts\\MORPHEUS.ttf'
ns.DEFAULT_FONT_SIZE = 12

--* Frame Constants
-- Frame Icons
ns.MINIMIZE = '128-RedButton-Minus'
ns.MINIMIZE_PRESSED = '128-RedButton-Minus-Pressed'
ns.MINIMIZE_HIGHLIGHT = '128-RedButton-Minus-Highlight'
ns.CLOSE = '128-RedButton-Exit'
ns.CLOSE_PRESSED = '128-RedButton-Exit-Pressed'
ns.CLOSE_HIGHLIGHT = '128-RedButton-Exit-Highlight'
ns.REFRESH = '128-RedButton-Refresh'
ns.REFRESH_PRESSED = '128-RedButton-Refresh-Pressed'
ns.REFRESH_HIGHLIGHT = '128-RedButton-Refresh-Highlight'

-- Backdrop Templates
ns.DEFAULT_BORDER = 'Interface\\Tooltips\\UI-Tooltip-Border'
ns.BLANK_BACKGROUND = 'Interface\\Buttons\\WHITE8x8'
ns.DIALOGUE_BACKGROUND = 'Interface\\DialogFrame\\UI-DialogBox-Background'
function ns.BackdropTemplate(bgImage, edgeImage, tile, tileSize, edgeSize, insets)
	tile = tile == 'NO_TILE' and false or true

	return {
		bgFile = bgImage or ns.DIALOGUE_BACKGROUND,
		edgeFile = edgeImage or ns.DEFAULT_BORDER,
		tile = true,
		tileSize = tileSize or 16,
		edgeSize = edgeSize or 16,
		insets = insets or { left = 3, right = 3, top = 3, bottom = 3 }
	}
end

-- Frame Stratas
ns.BACKGROUND_STRATA = 'BACKGROUND'
ns.LOW_STRATA = 'LOW'
ns.MEDIUM_STRATA = 'MEDIUM'
ns.HIGH_STRATA = 'HIGH'
ns.DIALOG_STRATA = 'DIALOG'
ns.TOOLTIP_STRATA = 'TOOLTIP'
ns.DEFAULT_STRATA = ns.BACKGROUND_STRATA