local _, ns = ... -- Namespace (myaddon, namespace)

-- Application Initialization
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')
local Icon, ADB = LibStub('LibDBIcon-1.0'), LibStub('AceDB-3.0')
local ACR = LibStub("AceConfigRegistry-3.0")

ns.core = {}
local core = ns.core

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
            showTooltips = true,
        }
    }
end
core:Init()

function core:StartGroupLeadHelper() --* Start the Group Lead Helper
    self:StartDatabase()
    self:StartMiniMapIcon()
    self:StartSlashCommands()
    self:StartEventMonitoring()

    ns.groupType = nil
    ns.code:cOut('Group Lead Helper '..ns.versionOut..' loaded.', ns.GLHColor, true)
end
function core:StartDatabase() --* Start the database
    self.db = ADB:New('GroupLeadHelperDB', self.dbDefaults)
    ns.p, ns.g = self.db.profile, self.db.global
end
function core:StartMiniMapIcon() --* Start Mini Map Icon
    local code = ns.code
    local iconData = LibStub("LibDataBroker-1.1"):NewDataObject("GLH_Icon", { -- Minimap Icon Settings
        type = 'data source',
        icon = ns.icon,
        OnClick = function(_, button)
            if button == 'LeftButton' and ns.base:IsShown() then ns.base:SetShown(false)
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
function core:StartSlashCommands() --* Start Slash Commands
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

--* Event Routines

--? End of Event Routines
--* Event Monitoring
function core:StartEventMonitoring()
    local function eventGroupJoined()
        local function eventGroupLeft()
            ns.groupType = nil
            ns.groupOut = nil
            ns.leader, ns.assistants = nil, {}

            GLH:UnregisterAllEvents()
            self:StartEventMonitoring()

            ns.base:SetShown(false)
        end
        local function eventCombatLog()
            local _, event, _, sGUID = CombatLogGetCurrentEventInfo()
            if (ns.tblCLEU[event] or event:match('SPELL_AURA')) and sGUID:sub(1,6) == 'Player' then
                ns.obs:Notify('COMBAT_LOG_EVENT_UNFILTERED', CombatLogGetCurrentEventInfo()) end
        end
        local function eventGroupRosterUpdate()
            ns.groupType = IsInRaid() and 'RAID' or IsInGroup() and 'PARTY' or nil
            ns.groupOut = ns.groupType and ns.groupType:sub(1,1):upper()..ns.groupType:sub(2):lower() or ''

            ns.leader, ns.assistants = nil, {}
            if IsInGroup() then
                for i=1,GetNumGroupMembers() do
                    local name, rank, _, _, _, _, _, _, _, _, class = GetRaidRosterInfo(i)
                    if rank == 2 then
                        ns.leader = class and ns.code:cPlayer(name, class) or name
                        if not IsInRaid() then break end
                    elseif rank == 1 then table.insert(ns.assistants, (class and ns.code:cPlayer(name, class) or name)) end
                end
            end

            ns.obs:Notify('GROUP_ROSTER_UPDATE')
        end

        GLH:UnregisterAllEvents()

        GLH:RegisterEvent('GROUP_LEFT', eventGroupLeft)
        GLH:RegisterEvent('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)
        GLH:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', eventCombatLog)
    end

    if IsInGroup() and not ns.groupType then
        eventGroupJoined()

        if ns.base:IsShown() then return end
        ns.base:SetShown(true)
    else GLH:RegisterEvent('GROUP_JOINED', eventGroupJoined) end
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

        ns.core:StartGroupLeadHelper()
    end

    GLH:RegisterEvent('ADDON_LOADED', startGLH)
end

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