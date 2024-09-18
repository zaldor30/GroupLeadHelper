local _, ns = ... -- Namespace (myaddon, namespace)

-- Application Initialization
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')
local Icon, ADB = LibStub('LibDBIcon-1.0'), LibStub('AceDB-3.0')
local ACR = LibStub("AceConfigRegistry-3.0")

ns.core = {}
local core = ns.core

ns.leader, ns.assistants = nil, {}
ns.groupOut, ns.groupType = nil, nil

--* GLH Core Functions
function core:Init()
    ns.tblCLEU = {}

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

--* Event Monitoring
local lastRefresh = nil
function core:Refresh()
    if lastRefresh and time() - lastRefresh < 1 then return end

    lastRefresh = time()
    ns.code:fOut('Refreshing Group Lead Helper...', ns.GLHColor, true)
    self:StartEventMonitoring(true)
    C_Timer.After(1, function() ns.code:fOut('Group Lead Helper Refreshed.', ns.GLHColor, true) end)
end --* Refresh the group information
function core:StartEventMonitoring(refresh)
    local function eventCombatLog()
        local _, event, _, sGUID = CombatLogGetCurrentEventInfo()
        if (ns.tblCLEU[event] or event:match('SPELL_AURA')) and sGUID:sub(1,6) == 'Player' then
            ns.obs:Notify('CLEU:ICON_BUFFS', CombatLogGetCurrentEventInfo()) end
    end
    local function eventGroupRosterUpdate()
        ns.groupOut = IsInRaid() and L['RAID'] or (IsInGroup() and L['PARTY'] or nil)
        ns.groupType = IsInRaid() and 'RAID' or (IsInGroup() and 'PARTY' or nil)
        if not ns.groupType then return end

        ns.leader, ns.assistants = {}, {}
        if IsInGroup() then
            for i=1,GetNumGroupMembers() do
                local name, rank, _, _, _, class = GetRaidRosterInfo(i)
                if rank == 2 then
                    ns.leader = { name, class }
                    if not IsInRaid() then break end
                elseif rank == 1 then table.insert(ns.assistants, { name, class }) end
            end
        end

        ns.obs:Notify('GROUP_ROSTER_UPDATE', refresh)
        if ns.base:IsShown() then return
        else ns.base:SetShown(true) end --! Fix showing
    end

    local eventGroupLeft = nil
    local function eventGroupJoined()
        GLH:RegisterEvent('GROUP_LEFT', eventGroupLeft)
        GLH:RegisterEvent('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)
        GLH:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', eventCombatLog)

        eventGroupRosterUpdate()
    end
    eventGroupLeft = function()
        if not self.isInGroup then return end

        ns.groupType = nil
        ns.groupOut = nil
        ns.leader, ns.assistants = nil, {}

        GLH:UnregisterAllEvents()
        ns.obs:Notify('GROUP_LEFT')
        ns.obs:UnregisterAll()

        GLH:UnregisterAllEvents()
        GLH:RegisterEvent('GROUP_JOINED', eventGroupJoined)
    end

    if refresh then eventGroupRosterUpdate()
    elseif IsInGroup() and not ns.groupType then
        self.isInGroup = true
        eventGroupJoined()
        if not ns.groupType then eventGroupLeft() return end

        if ns.base:IsShown() then return end
        ns.base:SetShown(true)
    elseif not IsInGroup() then eventGroupLeft() end
end -- CLEU, Group Roster, Group Left, Group Joined
--? End of ns.core

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

-- Small Backdrop
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