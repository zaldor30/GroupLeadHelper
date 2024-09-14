local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.base = {}
local base, gBase = {}, ns.base

local tblFrame = {}
local locked = 'gficon-chest-evergreen-greatvault-incomplete'
local unlocked = 'gficon-chest-evergreen-greatvault-complete'

local function OnDragStart(self)
    if base.isMoveLocked then return end
    self:StartMoving()
end
local function OnDragStop(self)
    self:StopMovingOrSizing()

    base.screenPos.point,_,_, base.screenPos.x, base.screenPos.y = self:GetPoint()
    ns.p.screenPos = base.screenPos
end

local function eventGroupRosterUpdate(inGroup)
    base:UpdateGroupComp()
    base:UpdateDifficulty()
    base:UpdateInstanceInfo()
end
local function eventFullShutdown()
    ns.observer:Notify('FULL_SHUTDOWN')
    ns.observer:Unregister('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)
end
local function eventCloseScreens()
    ns.observer:Unregister('CLOSE_SCREENS', eventCloseScreens)
    ns.observer:Unregister('FULL_SHUTDOWN', eventFullShutdown)
    ns.observer:Unregister('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)
end

function base:Init()
    self.isMoveLocked = true

    self.screenPos = { point = 'CENTER', x = 0, y = 0 }
end
function base:SetShown(val)
    if not val then
        tblFrame.frame:Hide()
        ns.observer:Notify('OPEN_SCREENS')
    end

    ns.observer:Notify('CLOSE_SCREENS')
    ns.observer:Register('CLOSE_SCREENS', eventCloseScreens)
    ns.observer:Register('FULL_SHUTDOWN', eventFullShutdown)
    ns.observer:Register('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)

    self.screenPos = ns.p.screenPos or self.pos
    if not tblFrame.frame then
        self:CreateFirstRowFrame()
        self:CreateSecondRowFrame()
    end

    eventGroupRosterUpdate()
    tblFrame.frame:SetShown(val)
end
function base:CreateFirstRowFrame() --* Frame and group comp, lock and close
    --* Create the main frame
    local f = ns.frames:CreateFrame('GLH_Base_Frame', UIParent, true)
    f:SetSize(350, 150)
    f:SetPoint(self.screenPos.point, self.screenPos.x, self.screenPos.y)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart', OnDragStart)
    f:SetScript('OnDragStop', OnDragStop)
    f:SetScript('OnHide', function()
        ns.observer:Notify('CLOSE_SCREENS')
    end)
    tblFrame.frame = f
    gBase.tblFrame = tblFrame

    --* Create the top frame components
    local b = ns.frames:CreateFrame('GLH_Base_Close', f, false, nil, 'Button')
    b:SetSize(30, 30)
    b:SetPoint('TOPRIGHT', 0, 0)
    b:SetNormalTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Up')
    b:SetPushedTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Down')
    b:SetHighlightTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight')
    b:SetScript('OnClick', function() base:SetShown(false) end)
    tblFrame.close = b

    local bLock = ns.frames:CreateFrame('GLH_Base_Lock', f, false, nil, 'Button')
    bLock:SetSize(20, 20)
    bLock:SetPoint('RIGHT', b, 'LEFT', 0, 0)
    bLock:SetNormalTexture(base.isMoveLocked and locked or unlocked)
    --bLock:SetPushedTexture(ns.frames.BUTTON_LOCKED)
    bLock:SetHighlightTexture(unlocked)
    bLock:SetScript('OnClick', function(self)
        base.isMoveLocked = not base.isMoveLocked
        tblFrame.tFrame:EnableMouse(base.isMoveLocked)
        bLock:SetNormalTexture(base.isMoveLocked and locked or unlocked)
        --bLock:SetPushedTexture(base.isMoveLocked and ns.frames.BUTTON_UNLOCKED or ns.frames.BUTTON_LOCKED)
        bLock:SetHighlightTexture(base.isMoveLocked and unlocked or locked)
    end)

    --* Create Group Comp
    local t = ns.frames:CreateFrame('GLH_Base_Title', f, false, nil, 'Button')
    t:SetHeight(20)
    t:SetPoint('LEFT', f, 'LEFT', 5, 0)
    t:SetPoint('TOPRIGHT', bLock, 'TOPLEFT', -5, 0)
    t:SetHighlightTexture(ns.BLUE_LONG_HIGHLIGHT)
    tblFrame.tFrame = t

    local txt = t:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    txt:SetText('Group Lead Helper')
    txt:SetTextColor(1, 1, 1, 1)
    txt:SetPoint('LEFT', 7, 0)
    tblFrame.fontComp = txt

    t:SetScript('OnEnter', function() base:CreateGroupCompTooltip() end)
    t:SetScript('OnLeave', function() GameTooltip:Hide() end)
end
function base:CreateSecondRowFrame()
    local f = ns.frames:CreateFrame('GLH_Base_SecondRow', tblFrame.frame)
    f:SetPoint('TOPLEFT', tblFrame.tFrame, 'BOTTOMLEFT', 3, 0)
    f:SetPoint('RIGHT', tblFrame.close, 'RIGHT', -5, 0)
    f:SetHeight(20)

    --* Difficulty Text
    local txt = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    txt:SetText('')
    txt:SetTextColor(1, 1, 1, 1)
    txt:SetPoint('LEFT', 6, 0)
    tblFrame.difficulty = txt

    --* Instance Text
    local txt2 = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    txt2:SetText('')
    txt2:SetTextColor(1, 1, 1, 1)
    txt2:SetJustifyH('RIGHT')
    txt2:SetPoint('RIGHT', -6, 0)
    txt2:SetWidth(f:GetWidth()/2)
    txt2:SetWordWrap(false)
    tblFrame.instance = txt2

end

--* Update for Row 1
local compOut, totalMembers, groupType = nil, 0, nil
local tank, healer, dps, unknown, tblTanks, tblHealers = 0, 0, 0, 0, {}, {}
local tankIcon, healerIcon, dpsIcon = '|A:'..ns.TANK_LFR_ICON..':20:20|a', '|A:'..ns.HEALER_LFR_ICON..':20:20|a', '|A:'..ns.DPS_LFR_ICON..':20:20|a'
function base:UpdateGroupComp()
    if not tblFrame.fontComp then return end

    local oTank, oHealer, oDPS, oUnknown = tank, healer, dps, unknown

    tank, healer, dps, unknown, tblTanks, tblHealers = ns.code:GetGroupRoles()
    if groupType == ns.groupType and totalMembers == GetNumGroupMembers() and oTank == tank and
        oHealer == oHealer and oDPS == dps and oUnknown == unknown then return end
    totalMembers, groupType = GetNumGroupMembers(), ns.groupType

    compOut = ns.groupType..':  '
    compOut = compOut..tankIcon..tank..'  '..healerIcon..healer..'  '..dpsIcon..dps--..' '..unknown..' Unknown'

    ns.frames:CreateFadeAnimation(tblFrame.fontComp, compOut)
end
local old_dID, dColor = nil, nil
function base:UpdateDifficulty()
    if not tblFrame.difficulty then return end

    local msgDifficulty = 'Difficulty: '..ns.code:cText('FFFF0000', 'Unknown')
    local dID = ns.groupType == 'Party' and GetDungeonDifficultyID() or nil
    local rID = ns.groupType == 'Raid' and GetRaidDifficultyID() or nil

    if old_dID and dID == old_dID then return
    elseif old_dID and rID == old_dID then return end

    if dID then
        if dID == 1 then dColor = ns.NORMAL_DUNGEON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Normal')
        elseif dID == 2 then dColor = ns.HEROIC_DUNGEON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Heroic')
        elseif dID == 23 then dColor = ns.MYTHIC_DUNGEON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Mythic')
        else msgDifficulty = 'Difficulty: '..ns.code:cText('FFFF0000', 'Invalid') end
    elseif rID then
        if rID == 17 then dColor = ns.LFR_DUNGEON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'LFR')
        elseif rID == 14 then dColor = ns.NORMAL_DUNGEON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Normal')
        elseif rID == 15 then dColor = ns.HEROIC_DUNGEON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Heroic')
        elseif rID == 16 then dColor = ns.MYTHIC_DUNGEON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Mythic')
        else msgDifficulty = 'Difficulty: '..ns.code:cText('FFFF0000', 'Invalid') end
    else return end

    old_dID = dID or rID
    ns.frames:CreateFadeAnimation(tblFrame.difficulty, msgDifficulty)
end
local oldInstanceID = nil
function base:UpdateInstanceInfo()
    if not tblFrame.instance then return end

    --[[
    1. name
    2. instanceType
    3. difficultyID
    4. difficultyName
    5. maxPlayers
    6. dynamicDifficulty
    7. isDynamic
    8. instanceID
    9. instanceGroupSize
    10. LfgDungeonID
    --]]

    local info = { GetInstanceInfo() }
    local instanceID = strlower(ns.groupType) == info[2] and info[8] or nil
    -- Horde Garrison: 1151, Alliance Garrison: 1331
    if not instanceID or instanceID == 1152 or instanceID == 1331 or
        not info[1] or info[1] == '' then
        oldInstanceID = nil
        tblFrame.instance:SetText('')
        return
    elseif oldInstanceID and instanceID == oldInstanceID then return end

    local msgInstance = 'Instance: '..ns.code:cText('FFFF0000', 'Unknown')
    if instanceID then
        local instanceName = info[1]
        if instanceName then msgInstance = ns.code:cText(dColor, instanceName)
        else msgInstance = 'Instance: '..ns.code:cText('FFFF0000', 'Unknown') end
    end

    oldInstanceID = instanceID
    ns.frames:CreateFadeAnimation(tblFrame.instance, msgInstance)
end
function base:CreateGroupCompTooltip()
    if not compOut then base:UpdateGroupComp() end

    local title = compOut
    local body = tankIcon..' Tanks:\n'

    local count = 0
    for _,v in pairs(tblTanks) do
        local cPlayer = ns.code:cPlayer(v[1], v[6])
        body = body..'|T'..ns.ds.tblClassesByFile[v[6]].iconPath..':20|t '..(cPlayer or v[1])
        body = UnitIsConnected(v[1]) and body or body..ns.code:cText('FFFF0000', ' (Offline)')
        count = count + 1
        if count == 2 then
            count = 0
            body = body..'\n'
        else body = body..' ' end
    end

    body = body..'\n'..healerIcon..' Healers:\n'
    for _,v in pairs(tblHealers) do
        local cPlayer = ns.code:cPlayer(v[1], v[6])
        body = body..'|T'..ns.ds.tblClassesByFile[v[6]].iconPath..':20|t '..(cPlayer or v[1])
        body = UnitIsConnected(v[1]) and body or body..ns.code:cText('FFFF0000', ' (Offline)')
        count = count + 1
        if count == 2 then
            count = 0
            body = body..'\n'
        else body = body..' ' end
    end

    ns.code:createTooltip(title, body, 'FORCE_TOOLTIP')
end
base:Init()

function gBase:IsShown() return tblFrame.frame and tblFrame.frame:IsShown() or false end
function gBase:SetShown(val) base:SetShown(val) end