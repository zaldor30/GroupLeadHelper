local _, ns = ... -- Namespace (myaddon, namespace)

-- Application Initialization
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')
local Icon, ADB = LibStub('LibDBIcon-1.0'), LibStub('AceDB-3.0')
local ACR = LibStub("AceConfigRegistry-3.0")

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

-- Highlgiht Images
ns.BLUE_HIGHLIGHT = 'bags-glow-heirloom'
ns.BLUE_LONG_HIGHLIGHT = 'communitiesfinder_card_highlight'

-- Font Globals
ns.ARIAL_FONT = 'Fonts\\ARIAN.ttf'
ns.SKURRI_FONT = 'Fonts\\SKURRI.ttf'
ns.DEFAULT_FONT = 'Fonts\\FRIZQT__.ttf'
ns.MORPHEUS_FONT = 'Fonts\\MORPHEUS.ttf'
ns.DEFAULT_FONT_SIZE = 12

ns.core = {}
local core = ns.core

local function groupRosterUpdate(...) -- For use in startup and GROUP_ROSTER_UPDATE event
    local oldGroupType = ns.groupType
    local msg = L['GLH_INACTIVE']
    if IsInGroup() and not ns.p.alwaysShow and not UnitIsGroupLeader('player') and not UnitIsGroupAssistant('player') then
        msg = L['GLH_INACTIVE_NOT_LEADER']
    elseif IsInGroup() then
        ns.groupType = IsInRaid() and 'Raid' or 'Party'
        msg = L['GLH_ACTIVE']..' '..ns.groupType
    else ns.groupType = nil end

    ns.observer:Notify('GROUP_ROSTER_UPDATE', (ns.groupType or false))

    -- Don't show message if group type has not changed

    --? Could do a chat maessage watch for 'joins the party.'
    if (not ns.groupType and oldGroupType) or (not oldGroupType and ns.groupType) then
        ns.code:cOut(msg, 'FFFF9100', true)

        if oldGroupType then -- Was in group
            GLH:UnregisterEvent('GROUP_ROSTER_UPDATE')
            GLH:RegisterEvent('GROUP_JOINED', groupRosterUpdate)
        elseif not oldGroupType then -- Joined a group
            if ns.p.alwaysShow and not ns.base:IsShown() then ns.base:SetShown(true) end
            GLH:UnregisterEvent('GROUP_JOINED')
            GLH:RegisterEvent('GROUP_ROSTER_UPDATE', groupRosterUpdate)
        end
    end
end

function GLH:OnInitialize() --* Called when the addon is loaded
    local function startGLH()
        GLH:UnregisterEvent('ADDON_LOADED')
        if not C_AddOns.IsAddOnLoaded('Details') then --* Check if Details! is loaded
            ns.code:fOut('Group Lead Helper '..ns.versionOut..' loaded.', ns.GLHColor, true)
            ns.code:fOut(L['MISSING_ADDON_1'], ns.GLHColor, true)
            ns.code:fOut(L['MISSING_ADDON_2'], 'FFFF0000', true)
            return
        end

        core:StartGroupLeadHelper()
    end

    GLH:RegisterEvent('ADDON_LOADED', startGLH)
end
--/inv holycynic-dalaran
--* GLH Core Functions
function core:Init()
    self.dbDefaults = {
        profile = {
            debugMode = false,
            minimap = { hide = false },
            screenPos = { point = 'CENTER', x = 0, y = 0 }, -- Main Frame Position
            alwaysShow = true,
        },
        global = {
            showWhatsNew = true,
        }
    }
end
function core:StartGroupLeadHelper() --* Start the Group Lead Helper
    self:StartDatabase()
    self:StartMiniMapIcon()
    self:StartSlashCommands()
    self:StartEventMonitoring()

    ns.groupType = nil
    ns.code:cOut('Group Lead Helper '..ns.versionOut..' loaded.', ns.GLHColor, true)
    --ns.code:cOut('Type /glh for options.', ns.GLHColor, true)
    groupRosterUpdate()
end
function core:StartDatabase() --* Start the database
    self.db = ADB:New('GroupLeadHelperDB', self.dbDefaults, true)
    ns.p, ns.g = self.db.profile, self.db.global
end
function core:StartMiniMapIcon() -- Start Mini Map Icon
    local code = ns.code
    local iconData = LibStub("LibDataBroker-1.1"):NewDataObject("GLH_Icon", { -- Minimap Icon Settings
        type = 'data source',
        icon = ns.icon,
        OnClick = function(_, button)
            if button == 'LeftButton' and IsShiftKeyDown() and not ns.base:IsShown() then ns.base:SetShown(true)
            elseif button == 'LeftButton' and not ns.base:IsShown() then ns.base:SetShown(true)
            elseif button == 'RightButton' then Settings.OpenToCategory('Guild Recruiter') end
        end,
        OnTooltipShow = function(GameTooltip)
            local title = code:cText('FFFFFF00', GLH.title..' '..ns.versionOut..':')
            local body = code:cText('FFFFFFFF', L['MINIMAP_TOOLTIP'])

            ns.code:createTooltip(title, body, 'FORCE_TOOLTIP')
        end,
        OnLeave = function() GameTooltip:Hide() end,
    })

    Icon:Register('GLH_Icon', iconData, ns.p.minimap)
    self.minimapIcon = Icon
end
function core:StartSlashCommands() -- Start Slash Commands
    local function slashCommand(msg)
        msg = strlower(msg:trim())

        if not msg or msg == '' and not ns.win.home:IsShown() then return ns.win.home:SetShown(true)
        elseif strlower(msg) == strlower(L['HELP']) then ns.code:fOut(L['SLASH_COMMANDS'], ns.GLHColor, true)
        elseif strlower(msg) == strlower(L['CONFIG']) then Settings.OpenToCategory('Guild Recruiter')
        elseif strlower(msg):match(strlower(L['MINIMAP'])) then
            ns.p.minimap.hide = not ns.p.minimap.hide
            self.minimapIcon:Refresh('GLH_Icon', ns.p.minimap)
        end
    end

    GLH:RegisterChatCommand('glh', slashCommand)
end
function core:StartEventMonitoring() --* Start the event monitoring
    if IsInGroup() then
        GLH:RegisterEvent('GROUP_ROSTER_UPDATE', groupRosterUpdate)
    else GLH:RegisterEvent('GROUP_JOINED', groupRosterUpdate) end
end
core:Init() --* Initialize the core