local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.gi = {}
local gi = ns.gi

local function obsMOVING_FRAME(isLocked)
    gi.tblFrame.frame:EnableMouse(isLocked)
    gi.tblFrame.fComp:EnableMouse(isLocked)
    gi.tblFrame.fLeader:EnableMouse(isLocked)
end
local function eventGROUP_ROSTER_UPDATE(refresh)
    if not gi:IsShown() then return end
    gi:UpdateGroupComp(refresh)
    gi:UpdateLeader(refresh)
    gi:UpdateDifficulty(refresh)
end
local function obsUPDATE_INSTANCE_INFO()
end

--* Group Info Functions
function gi:Init()
    self.tblComps = ns.ds:GetComps()
    self.activeComp = nil
    self.oldDifficulty = nil

    self.leader, self.assistants = nil, {}
    self.tblTanks, self.tblHealers = {}, {}
    self.tanks, self.healers, self.dps, self.unknown = 0, 0, 0, 0

    self.tblFrame = {}
end
function gi:IsShown() return (self.tblFrame and self.tblFrame.frame) and self.tblFrame.frame:IsShown() or false end
function gi:SetShown(val)
    if not val then
        if self.tblFrame.frame then self.tblFrame.frame:SetShown(val) end
        return
    end

    ns.obs:Register('MOVING_FRAME', obsMOVING_FRAME)
    ns.obs:Register('GROUP_ROSTER_UPDATE', eventGROUP_ROSTER_UPDATE)
    ns.obs:Register('UPDATE_INSTANCE_INFO', obsUPDATE_INSTANCE_INFO)

    if not self.tblFrame or not self.tblFrame.frame then
        self:Init()
        self:CreateFrame()
    end

    self:UpdateGroupComp()
    self:UpdateLeader()
    self:UpdateDifficulty()
    self.tblFrame.frame:SetShown(val)
end
function gi:CreateFrame()
    local baseFrame = ns.base.tblFrame

    --* Create the Base Frame
    local f = ns.frames:CreateFrame('Frame', 'GLH_GroupInfoFrame', baseFrame.frame)
    f:SetPoint('TOPLEFT', baseFrame.top, 'TOPLEFT', 5, 0)
    f:SetPoint('BOTTOMRIGHT', baseFrame.frame, 'BOTTOMRIGHT', -5, 0)
    f:EnableMouse(true)
    self.tblFrame.frame = f
    --? End of Base Frame

    --* Create the Group Comp Frame
    local fComp = ns.frames:CreateFrame('Button', 'GLH_GroupInfoComp', f)
    fComp:SetPoint('TOPLEFT', baseFrame.top, 'TOPLEFT', 2, -5)
    fComp:SetPoint('BOTTOMRIGHT', baseFrame.top, 'BOTTOMRIGHT', -2, 2)
    fComp:SetHighlightAtlas(ns.BLUE_LONG_HIGHLIGHT)
    fComp:EnableMouse(true)
    self.tblFrame.fComp = fComp

    local text = fComp:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    text:SetPoint('TOPLEFT', fComp, 'TOPLEFT', 0, 0)
    text:SetPoint('BOTTOMRIGHT', fComp, 'BOTTOMRIGHT', 0, 0)
    text:SetJustifyH('CENTER')
    text:SetJustifyV('MIDDLE')
    text:SetFont(ns.DEFAULT_FONT, 16)
    text:SetTextColor(1, 1, 1, 1)
    text:SetText('Group Comp')
    self.tblFrame.compText = text

    fComp:SetScript('OnEnter', function(self) gi:CreateGroupCompTooltip() end)
    fComp:SetScript('OnLeave', function(self) GameTooltip:Hide() end)
    --? End of Group Comp Frame

    --* Create the Group Leader Frame
    local fLeader = ns.frames:CreateFrame('Button', 'GLH_GroupInfoLeader', ns.base.tblFrame.frame)
    fLeader:SetPoint('TOPLEFT', ns.base.tblFrame.frame, 'TOPLEFT', 0, -5)
    fLeader:SetPoint('BOTTOMRIGHT', ns.base.tblFrame.fLock, 'BOTTOMRIGHT', 0, 0)
    fLeader:SetSize(50, 20)
    fLeader:SetHighlightAtlas(ns.BLUE_LONG_HIGHLIGHT)
    fLeader:EnableMouse(true)
    self.tblFrame.fLeader = fLeader

    local lText = fLeader:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    lText:SetPoint('TOPLEFT', fLeader, 'TOPLEFT', 7, 0)
    lText:SetPoint('BOTTOMRIGHT', fLeader, 'BOTTOMRIGHT', 0, 0)
    lText:SetJustifyH('LEFT')
    lText:SetJustifyV('MIDDLE')
    lText:SetFont(ns.DEFAULT_FONT, 12)
    lText:SetTextColor(1, 1, 1, 1)
    lText:SetWordWrap(false)
    lText:SetText('Group Leader')
    self.tblFrame.leaderText = lText

    fLeader:SetScript('OnEnter', function(self) gi:CreateGroupLeaderToolTip() end)
    fLeader:SetScript('OnLeave', function(self) GameTooltip:Hide() end)
    --? End of Group Leader Frame

    --* Create the Difficulty Frame
    local fDiff = ns.frames:CreateFrame('Button', 'GLH_GroupInfoDiff', f)
    fDiff:SetPoint('BOTTOM', ns.base.tblFrame.top, 'TOP', 2, -8)
    fDiff:SetSize(f:GetWidth(), 20)
    fDiff:EnableMouse(false)
    self.tblFrame.fDiff = fDiff

    local dText = fDiff:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    dText:SetPoint('TOPLEFT', fDiff, 'TOPLEFT', 0, 0)
    dText:SetPoint('BOTTOMRIGHT', fDiff, 'BOTTOMRIGHT', 0, 0)
    dText:SetJustifyH('CENTER')
    dText:SetJustifyV('MIDDLE')
    dText:SetFont(ns.DEFAULT_FONT, 12)
    dText:SetTextColor(1, 1, 1, 1)
    self.tblFrame.diffText = dText
    --? End of Difficulty Frame
end

--* Group Comp Functions
local compOut = nil
local tankIcon, healerIcon, dpsIcon, unknownIcon = '|A:'..ns.TANK_LFR_ICON..':14:14|a', '|A:'..ns.HEALER_LFR_ICON..':14:14|a', '|A:'..ns.DPS_LFR_ICON..':14:14|a', '|A:'..ns.UNKNOWN_LFR_ICON..':14:14|a'
function gi:CompIndicators(tanks, healers, dps, unknown)
    local players = GetNumGroupMembers()
    local tblComps = self.tblComps[ns.groupInfo.groupType]
    if not tblComps then return tanks, healers, dps, unknown end

    for k, v in pairs(tblComps) do
        if v.startSize <= players and v.endSize >= players then
            self.activeComp = k
            break
        end
    end
    if not self.activeComp then return tanks, healers, dps, unknown, nil end

    local buildComp = tblComps[self.activeComp].name

    tanks = tanks or 0
    if tanks < tblComps[self.activeComp].tank or tanks > tblComps[self.activeComp].tank then
        tanks = ns.code:cText('FFFF0000', tanks) end

    healers = healers or 0
    local addPad = ns.groupInfo.groupType == 'RAID' and 1 or 0
    if healers < tblComps[self.activeComp].healer or healers > tblComps[self.activeComp].healer + addPad then
        healers = ns.code:cText('FFFF0000', healers)
    elseif healers == tblComps[self.activeComp].healer + addPad then ns.code:cText('FFFFFF00', healers) end

    dps = dps or 0
    addPad = ns.groupInfo.groupType == 'RAID' and 2 or 0
    if dps < tblComps[self.activeComp].dps or dps > tblComps[self.activeComp].dps + addPad then
        dps = ns.code:cText('FFFF0000', dps)
    elseif dps == tblComps[self.activeComp].dps then return tanks, healers, dps, unknown, buildComp
    elseif dps <= tblComps[self.activeComp].dps + addPad then ns.code:cText('FFFFFF00', dps) end

    return tanks, healers, dps, unknown, buildComp
end
function gi:UpdateGroupComp(refresh)
    if not ns.groupInfo or not ns.groupInfo.groupOut then return end

    local tanks, healers, dps, unknown, tblTanks, tblHealers = ns.code:GetGroupRoles()
    self.tblTanks, self.tblHealers = tblTanks, tblHealers

    if not refresh and self.oldGroupType == ns.groupInfo.groupType and self.tanks == tanks and self.healers == healers and
        self.dps == dps and self.unknown == unknown then return end
    self.tanks, self.healers, self.dps, self.unknown = (tanks or 0), (healers or 0), (dps or 0), (unknown or 0)

    tanks, healers, dps, unknown = gi:CompIndicators(tanks, healers, dps, unknown)

    self.oldGroupType = ns.groupInfo.groupType
    compOut = ns.groupInfo.groupOut..': '..tankIcon..(tanks or 0)..'  '..healerIcon..(healers or 0)..'  '..dpsIcon..(dps or 0)--..' '..unknownIcon..' Unknown'

    ns.frames:CreateFadeAnimation(self.tblFrame.compText, compOut)
end
function gi:CreateGroupCompTooltip()
    local tanks, healers, dps, unknown, buildComp = gi:CompIndicators(self.tanks, self.healers, self.dps, self.unknown)
    if not buildComp then return end

    local title = 'Group Composition'..' ('..tankIcon..(tanks or 0)..'  '..healerIcon..(healers or 0)..'  '..dpsIcon..(dps or 0)..')'
    local body = 'Players in Group: '..GetNumGroupMembers()..'\nIdeal Composition: '..buildComp..'\n'

    local colCount, tankfound = 0, false
    for _, r in pairs(self.tblTanks) do
        tankfound = true
        colCount = colCount + 1
        local name = ns.code:cPlayer(r.name, r.classFile)
        local offline = r.isOnline and '' or ' (Offline)'
        if colCount == 1 then body = body..'\n'..tankIcon..' '..name..offline
        else
            colCount = 0
            body = body..' '..tankIcon..' '..name..offline
        end
    end
    body = tankfound and body..'\n' or body

    colCount = 0
    for _, r in pairs(self.tblHealers) do
        colCount = colCount + 1
        local name = ns.code:cPlayer(r.name, r.classFile)
        local offline = r.isOnline and '' or ' (Offline)'
        if colCount == 1 then body = body..'\n'..healerIcon..' '..name..offline
        else
            colCount = 0
            body = body..' '..healerIcon..' '..name..offline
        end
    end

    ns.code:createTooltip(title, body, 'FORCE_TOOLTIP')
end
--? End of Group Comp Functions

--* Group Leader Functions
function gi:UpdateLeader(refresh)
    if not ns.groupInfo or not ns.groupInfo.leader then return
    elseif not refresh and self.leader == ns.groupInfo.leader[1] then return end

    self.leader = ns.groupInfo.leader[1]
    local roleIcon = ns.groupInfo.leader[2] == 'TANK' and tankIcon or ns.groupInfo.leader[2] == 'HEALER' and healerIcon or dpsIcon
    local offline = ns.roster[self.leader].isOnline and '' or ' (Offline)'
    local out = roleIcon..' '..ns.code:cPlayer(ns.groupInfo.leader[1], ns.groupInfo.leader[2])..offline
    ns.frames:CreateFadeAnimation(self.tblFrame.leaderText, out)
end
function gi:CreateGroupLeaderToolTip()
    local title = ns.groupInfo.groupOut..' '..L['LEADER']..':'

    local roleIcon = ns.groupInfo.leader[2] == 'TANK' and tankIcon or ns.groupInfo.leader[2] == 'HEALER' and healerIcon or dpsIcon
    local offline = ns.roster[ns.groupInfo.leader[1]].isOnline and '' or ' (Offline)'
    local body = roleIcon..' '..ns.code:cPlayer(ns.groupInfo.leader[1], ns.groupInfo.leader[2])..offline

    if ns.groupInfo.groupType == 'RAID' then
        local colCount = 0
        body = body..'\n \n'..L['GROUP_ASSISTANT']..':'
        for _, a in pairs(ns.groupInfo.assistants) do
            colCount = colCount + 1
            roleIcon = a[2] == 'TANK' and tankIcon or a[2] == 'HEALER' and healerIcon or dpsIcon
            offline = ns.roster[a[1]].isOnline and '' or ' (Offline)'
            if colCount == 1 then body = body..'\n'..roleIcon..' '..ns.code:cPlayer(a[1], a[2])..offline
            else
                colCount = 0
                body = body..'\n'..roleIcon..' '..ns.code:cPlayer(a[1], a[2])..offline
            end
        end
    end

    ns.code:createTooltip(title, body, 'FORCE_TOOLTIP')
end
--? End of Group Leader Functions

--* Group Difficulty Functions
function gi:UpdateDifficulty(refresh)
    if not ns.groupInfo then return end

    local dColor = nil
    local header = ns.groupInfo.groupType == 'RAID' and L['RAID'] or 'Dungeon'
    local msgDifficulty = header..': '..ns.code:cText('FFFF0000', 'Unknown')
    local dungeonID = ns.groupInfo.groupType == 'PARTY' and GetDungeonDifficultyID() or nil
    local rID = ns.groupInfo.groupType == 'RAID' and GetRaidDifficultyID() or nil

    if not self.oldDifficulty or refresh or dungeonID ~= self.oldDifficulty or
        rID == self.oldDifficulty then

        if dungeonID then
            if dungeonID == 1 then dColor = ns.RARE_COLOR msgDifficulty = header..': '..ns.code:cText(dColor, 'Normal')
            elseif dungeonID == 2 then dColor = ns.EPIC_COLOR msgDifficulty = header..': '..ns.code:cText(dColor, 'Heroic')
            elseif dungeonID == 23 then dColor = ns.LEGENDARY_COLOR msgDifficulty = header..': '..ns.code:cText(dColor, 'Mythic')
            else msgDifficulty = header..': '..ns.code:cText('FFFF0000', 'Invalid') end
        elseif rID then
            if rID == 17 then dColor = ns.UNCOMMON_COLOR msgDifficulty = header..': '..ns.code:cText(dColor, 'LFR')
            elseif rID == 14 then dColor = ns.RARE_COLOR msgDifficulty = header..': '..ns.code:cText(dColor, 'Normal')
            elseif rID == 15 then dColor = ns.EPIC_COLOR msgDifficulty = header..': '..ns.code:cText(dColor, 'Heroic')
            elseif rID == 16 then dColor = ns.LEGENDARY_COLOR msgDifficulty = header..': '..ns.code:cText(dColor, 'Mythic')
            else msgDifficulty = header..': '..ns.code:cText('FFFF0000', 'Invalid') end
        else return end

        self.oldDifficulty = dungeonID or rID
        ns.frames:CreateFadeAnimation(self.tblFrame.diffText, msgDifficulty)
    else return end

    return msgDifficulty, dColor
end
--? End of Group Difficulty Functions