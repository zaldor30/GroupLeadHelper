local _, ns = ... -- Namespace (myaddon, namespace)

-- Application Initialization
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')
local Icon, ADB = LibStub('LibDBIcon-1.0'), LibStub('AceDB-3.0')
local ACR = LibStub("AceConfigRegistry-3.0")

ns.core = {}
local core = ns.core

local function groupRosterUpdate(...) -- For use in startup and GROUP_ROSTER_UPDATE event
    local oldGroupType = ns.groupType
    if not IsInGroup() or (IsInGroup() and not ns.p.alwaysShow and
        not UnitIsGroupLeader('player') and not UnitIsGroupAssistant('player')) then
        -- Show Messages
        if IsInGroup() then ns.code:cOut(L['GLH_INACTIVE_NOT_LEADER'], 'FFFF9100', true)
        elseif (not ns.groupType and oldGroupType) or (not oldGroupType and ns.groupType) then
            ns.code:cOut(L['GLH_INACTIVE'], 'FFFF9100', true) end

        ns.groupType = nil

        ns.observer:Notify('FULL_SHUTDOWN')
        GLH:UnregisterAllEvents()
        GLH:UnregisterEvent('GROUP_ROSTER_UPDATE')
        GLH:RegisterEvent('GROUP_JOINED', groupRosterUpdate)
    elseif IsInGroup() then
        ns.groupType = IsInRaid() and 'Raid' or 'Party'
        if (not ns.groupType and oldGroupType) or (not oldGroupType and ns.groupType) then
            ns.code:cOut(L['GLH_ACTIVE']..' '..ns.groupType, 'FFFF9100', true) end

        oldGroupType = ns.groupType
        GLH:UnregisterEvent('GROUP_JOINED')
        GLH:RegisterEvent('GROUP_ROSTER_UPDATE', groupRosterUpdate)
        ns.observer:Notify('GROUP_ROSTER_UPDATE', (ns.groupType or false))

        ns.base:SetShown(true)
    end

    -- Don't show message if group type has not changed

    --? Could do a chat maessage watch for 'joins the party.'
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
            showTooltips = true,
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