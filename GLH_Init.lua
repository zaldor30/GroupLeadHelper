local _, ns = ... -- Namespace (myaddon, namespace)
ns = {}

GLH = LibStub('AceAddon-3.0'):NewAddon('GLH', 'AceConsole-3.0', 'AceEvent-3.0')
GLH.author  = C_AddOns.GetAddOnMetadata('GuildRecruiter', 'Author')
GLH.version = C_AddOns.GetAddOnMetadata('GuildRecruiter', 'Version')

-- Namespace Globals
ns.dbVersion = '1.0'
ns.isTesting = false
ns.isPreRelease = false
ns.preReleaseType = 'Beta'
ns.versionOut = '(v'..ns.version..(ns.isPreRelease and ' '..ns.preReleaseType or '')..')'

ns.debug = false
ns.commPrefix = 'GLHSync'
C_ChatInfo.RegisterAddonMessagePrefix(ns.commPrefix)

ns.ICON_PATH = 'Interface\\AddOns\\GroupLeadHelper\\Images\\'

ns.icon = ns.ICON_PATH..'GLH_Icon.tga'

-- Highlgiht Images
ns.BLUE_HIGHLIGHT = 'bags-glow-heirloom'
ns.BLUE_LONG_HIGHLIGHT = 'communitiesfinder_card_highlight'

-- Font Globals
ns.ARIAL_FONT = 'Fonts\\ARIAN.ttf'
ns.SKURRI_FONT = 'Fonts\\SKURRI.ttf'
ns.DEFAULT_FONT = 'Fonts\\FRIZQT__.ttf'
ns.MORPHEUS_FONT = 'Fonts\\MORPHEUS.ttf'
ns.DEFAULT_FONT_SIZE = 12