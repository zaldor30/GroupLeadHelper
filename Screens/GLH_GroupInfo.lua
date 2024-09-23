local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.groupInfo = {}
local gi, groupInfo = {}, ns.groupInfo

--* Event Routines
local function eventGroupRosterUpdate(refresh)
    if not IsInGroup() or not ns.GroupRoster.groupType or not ns.GroupRoster.groupOut then return end

    gi:UpdateGroupComposition(refresh)
    if ns.GroupRoster.leader and (gi.oldLeader ~= ns.GroupRoster.leader[1] or refresh) then
        gi.oldLeader = ns.GroupRoster.leader[1]
        local cName = UnitIsConnected(ns.GroupRoster.leader[1]) and ns.code:cPlayer(ns.GroupRoster.leader[1], ns.GroupRoster.leader[2]) or ns.code:cPlayer(ns.GroupRoster.leader[1], nil, 'FF808080')
        ns.frames:CreateFadeAnimation(gi.tblFrame.leaderText, (L['LEADER']..': '..cName))
    end

    local dID = ns.GroupRoster.groupType == 'raid' and GetRaidDifficultyID() or GetDungeonDifficultyID()
    if gi.oldDifficulty ~= dID or refresh then
        local difficulty = gi:UpdateDifficulty(refresh)
        if difficulty then ns.frames:CreateFadeAnimation(gi.tblFrame.diffText, difficulty) end
    end

    local iID = select(8, GetInstanceInfo())
    if gi.oldInstance ~= iID or refresh then
        gi.oldInstance = iID
        --gi:UpdateInstance()
    end
end

function gi:Init()
    self.tblFrame = self.tblFrame or {}

    self.oldLeader = nil
    self.oldInstance = nil
    self.oldGroupType, self.oldDifficulty = nil, nil
    self.tanks, self.healers, self.dps, self.unknown = 0, 0, 0, 0

    self.activeComp = nil -- CompID
    self.tblComps = {}
end
function groupInfo:Init()
    self.tblClasses = {}

    self.instanceID = nil
    self.instance = nil
    self.iColor = nil
end
function groupInfo:SetShown(val)
    if not val then
        if gi.tblFrame.frame then gi.tblFrame.frame:SetShown(val) end

        GLH:UnregisterEvent('UPDATE_INSTANCE_INFO')
        GLH:UnregisterEvent('PLAYER_ENTERING_WORLD')
        GLH:UnregisterEvent('ZONE_CHANGED_NEW_AREA')

        gi:Init()
        return
    elseif gi.tblFrame.frame and gi.tblFrame.frame:IsShown() then return end

    ns.obs:Register('GROUP_LEFT', function()
        gi.tblFrame.frame:SetShown(false)
    end)
    ns.obs:Register('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)

    local function updateInstanceInfo()
        gi:UpdateDifficulty(true)
        gi:GetInstanceInfo()
    end
    GLH:RegisterEvent('UPDATE_INSTANCE_INFO', updateInstanceInfo)
    GLH:RegisterEvent('PLAYER_ENTERING_WORLD', updateInstanceInfo)
    GLH:RegisterEvent('ZONE_CHANGED_NEW_AREA', updateInstanceInfo)

    gi.tblComps = ns.ds:GetComps()
    gi:CreateBaseFrame()
    gi:UpdateGroupComposition()

    if ns.GroupRoster.leader and ns.GroupRoster.leader[1] and ns.GroupRoster.leader[1] ~= '' then
        gi.oldLeader = ns.GroupRoster.leader[1]
        local cName = UnitIsConnected(ns.GroupRoster.leader[1]) and ns.code:cPlayer(ns.GroupRoster.leader[1], ns.GroupRoster.leader[2]) or ns.code:cPlayer(ns.GroupRoster.leader[1], nil, 'FF808080')
        ns.frames:CreateFadeAnimation(gi.tblFrame.leaderText, (L['LEADER']..': '..cName))
    end

    local difficulty = gi:UpdateDifficulty()
    if difficulty then ns.frames:CreateFadeAnimation(gi.tblFrame.diffText, difficulty) end
    gi:GetInstanceInfo()

    gi.tblFrame.frame:SetShown(val)
    ns.groupInfo.tblFrame = gi.tblFrame
end
function gi:CreateBaseFrame()
    --* Create Group Composition Frame
    local f = self.tblFrame.frame or CreateFrame('Button', 'GLH_GroupInfoFrame', ns.base.tblBase.top)
    f:SetSize(ns.base.tblBase.top:GetWidth(), 30)
    f:SetPoint('CENTER', ns.base.tblBase.top, 'CENTER', 0, 0)
    f:SetHighlightAtlas(ns.BLUE_LONG_HIGHLIGHT)

    local text = f:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    text:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, -4)
    text:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 0)
    text:SetJustifyH('CENTER')
    text:SetJustifyV('MIDDLE')
    text:SetFont(ns.DEFAULT_FONT, 16)
    text:SetTextColor(1, 1, 1, 1)

    f:SetScript('OnEnter', function(self) gi:CreateGroupCompTooltip() end)
    f:SetScript('OnLeave', function(self) GameTooltip:Hide() end)

    self.tblFrame.frame = f
    self.tblFrame.compText = text
    --? End of Group Composition Frame

    --* Create Group Leader Frame
    local lFrame = self.tblFrame.leaderFrame or CreateFrame('Button', 'GLH_GroupLeaderFrame', ns.base.tblBase.top)
    lFrame:SetPoint('TOPLEFT', f, 'BOTTOMLEFT', 7, 0)
    lFrame:SetPoint('BOTTOMRIGHT', ns.base.tblBase.fLock, 'BOTTOMLEFT', 0, 0)
    lFrame:SetHighlightAtlas(ns.BLUE_LONG_HIGHLIGHT)

    local lText = lFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    lText:SetPoint('LEFT', 2, 0)
    lText:SetJustifyH('LEFT')
    lText:SetJustifyV('MIDDLE')
    lText:SetFont(ns.DEFAULT_FONT, 14)
    lText:SetTextColor(1, 1, 1, 1)
    lText:SetWordWrap(false)
    self.tblFrame.leaderText = lText

    lFrame:SetScript('OnEnter', function(self) gi:CreateGroupLeaderToolTip() end)
    lFrame:SetScript('OnLeave', function(self) GameTooltip:Hide() end)
    self.tblFrame.leaderFrame = lFrame
    --? End of Group Leader Frame

    --* Create Group Difficulty Frame
    local dFrame = self.tblFrame.diffFrame or CreateFrame('Button', 'GLH_GroupDifficultyFrame', ns.base.tblBase.top)
    dFrame:SetPoint('BOTTOMLEFT', ns.base.tblBase.frame, 'BOTTOMLEFT', 5, 3)
    dFrame:SetSize(ns.base.tblBase.frame:GetWidth() / 2, 25)
    --dFrame:SetHighlightAtlas(ns.BLUE_LONG_HIGHLIGHT)
    self.tblFrame.diffFrame = dFrame

    local dText = dFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    dText:SetPoint('LEFT', 5, 0)
    dText:SetJustifyH('LEFT')
    dText:SetJustifyV('MIDDLE')
    dText:SetFont(ns.DEFAULT_FONT, 14)
    dText:SetTextColor(1, 1, 1, 1)
    self.tblFrame.diffText = dText
    --? End of Group Difficulty Frame

    --* Create Group Instance Frame
    local iFrame = self.tblFrame.iFrame or CreateFrame('Button', 'GLH_GroupDifficultyFrame', ns.base.tblBase.top)
    iFrame:SetPoint('TOPLEFT', dFrame, 'TOPRIGHT', 0, 2)
    iFrame:SetPoint('BOTTOMRIGHT', ns.base.tblBase.frame, 'BOTTOMRIGHT', 0, 2)
    iFrame:SetWidth(ns.base.tblBase.frame:GetWidth() / 2)
    iFrame:SetHighlightAtlas(ns.BLUE_LONG_HIGHLIGHT)

    local iText = iFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    iText:SetPoint('RIGHT', -5, 0)
    iText:SetJustifyH('RIGHT')
    iText:SetJustifyV('MIDDLE')
    iText:SetFont(ns.DEFAULT_FONT, 14)
    iText:SetTextColor(1, 1, 1, 1)
    iText:SetWidth(iFrame:GetWidth())
    iText:SetWordWrap(false)
    self.tblFrame.iText = iText

    iFrame:SetScript('OnEnter', function(self) gi:GetInstanceTooltip() end)
    iFrame:SetScript('OnLeave', function(self) GameTooltip:Hide() end)
    self.tblFrame.iFrame = iFrame
    --? End of Group Instance Frame
end

--* Update Group Composition
local compOut = nil
local tankIcon, healerIcon, dpsIcon, unknownIcon = '|A:'..ns.TANK_LFR_ICON..':20:20|a', '|A:'..ns.HEALER_LFR_ICON..':20:20|a', '|A:'..ns.DPS_LFR_ICON..':20:20|a', '|A:'..ns.UNKNOWN_LFR_ICON..':20:20|a'
function gi:CompIndicators(tanks, healers, dps, unknown)
    local players = GetNumGroupMembers()
    local tblComps = self.tblComps[ns.GroupRoster.groupType]
    if not tblComps then return end

    for k, v in pairs(tblComps) do
        if v.startSize <= players and v.endSize >= players then
            self.activeComp = k
            break
        end
    end

    local buildComp = tblComps[self.activeComp].name

    tanks = tanks or 0
    if tanks < tblComps[self.activeComp].tank or tanks > tblComps[self.activeComp].tank then
        tanks = ns.code:cText('FFFF0000', tanks) end

    healers = healers or 0
    local addPad = ns.GroupRoster.groupType == 'RAID' and 1 or 0
    if healers < tblComps[self.activeComp].healer or healers > tblComps[self.activeComp].healer + addPad then
        healers = ns.code:cText('FFFF0000', healers)
    elseif healers == tblComps[self.activeComp].healer + addPad then ns.code:cText('FFFFFF00', healers) end

    dps = dps or 0
    addPad = ns.GroupRoster.groupType == 'RAID' and 2 or 0
    if dps < tblComps[self.activeComp].dps or dps > tblComps[self.activeComp].dps + addPad then
        dps = ns.code:cText('FFFF0000', dps)
    elseif dps == tblComps[self.activeComp].dps then return tanks, healers, dps, unknown, buildComp
    elseif dps <= tblComps[self.activeComp].dps + addPad then ns.code:cText('FFFFFF00', dps) end

    return tanks, healers, dps, unknown, buildComp
end

function gi:UpdateGroupComposition(refresh)
    if not ns.GroupRoster.groupOut then return end

    local tanks, healers, dps, unknown = ns.code:GetGroupRoles()

    if not refresh and self.oldGroupType == ns.GroupRoster.groupType and self.tanks == tanks and self.healers == healers and
        self.dps == dps and self.unknown == unknown then return end
    self.tanks, self.healers, self.dps, self.unknown = (tanks or 0), (healers or 0), (dps or 0), (unknown or 0)

    tanks, healers, dps, unknown = gi:CompIndicators(tanks, healers, dps, unknown)

    self.oldGroupType = ns.GroupRoster.groupType
    compOut = ns.GroupRoster.groupOut..': '..tankIcon..(tanks or 0)..'  '..healerIcon..(healers or 0)..'  '..dpsIcon..(dps or 0)--..' '..unknownIcon..' Unknown'

    ns.frames:CreateFadeAnimation(self.tblFrame.compText, compOut)
end
function gi:CreateGroupCompTooltip()
    local tanks, healers, dps, unknown, buildComp = gi:CompIndicators(self.tanks, self.healers, self.dps, self.unknown)
    if not buildComp then return end

    local title = 'Group Composition'..' ('..tankIcon..(tanks or 0)..'  '..healerIcon..(healers or 0)..'  '..dpsIcon..(dps or 0)..')'
    local body = 'Players in Group: '..GetNumGroupMembers()..'\nIdeal Composition: '..buildComp

    ns.code:createTooltip(title, body, 'FORCE_TOOLTIP')
end
--? End of Group Composition

--* Create Group Leader Tooltip
function gi:GetGroupLeaders()
    local gLead = ''
    local title, body = ns.GroupRoster.groupType..' Leader', '\n \nAssistants:\n'

    if IsInRaid() then
        for i=1, GetNumGroupMembers() do
            local unit, rank = GetRaidRosterInfo(i)
            if not unit then unit = UnitName('player') end

            local connected = UnitIsConnected(unit)
            if rank == 1 then
                body = '\n'..body..(not connected and '<offline> ' or '')..ns.code:cPlayer(unit, UnitClassBase(unit))
            elseif rank == 2 then
                body = 'Leader: '..(not connected and '<offline> ' or '')..ns.code:cPlayer(unit, UnitClassBase(unit))..body
                gLead = 'Leader: '..ns.code:cPlayer(unit, UnitClassBase(unit))..(not connected and ' <offline>' or '')
            end
        end
    elseif ns.GroupRoster.groupType == 'Party' then
        for i=1, GetNumGroupMembers() do
            local unit = GetRaidRosterInfo(i)
            if not unit then unit = UnitName('player') end

            if UnitIsGroupLeader(unit) then
                local connected = UnitIsConnected(unit)
                body = 'Leader: '..(not connected and '<offline> ' or '')..ns.code:cPlayer(unit, UnitClassBase(unit))
                gLead = 'Leader: '..ns.code:cPlayer(unit, UnitClassBase(unit))..(not connected and ' <offline>' or '')
                break
            end
        end
    end

    return title, body, gLead
end
function gi:CreateGroupLeaderToolTip()
    if not ns.GroupRoster.groupType then return end

    local title, body = L['GROUP_LEADER'], '\n \n'..L['GROUP_ASSISTANT']..':\n'
    local gLead = ns.GroupRoster.groupOut..' '..L['LEADER']..': '..ns.code:cPlayer(ns.GroupRoster.leader[1], ns.GroupRoster.leader[2])
    gLead = UnitIsConnected(ns.GroupRoster.leader[1]) and gLead or gLead..ns.code:cText('FF808080', ' <offline>')

    local tblOffline = {}
    for i=1, GetNumGroupMembers() do
        local unit,_,_,_,_,_,_, online = GetRaidRosterInfo(i)
        tblOffline[unit] = online
    end
    if #ns.GroupRoster.assistants > 0 then
        for i=1, #ns.GroupRoster.assistants do
            local unit = ns.GroupRoster.assistants[i]
            body = body..ns.code:cPlayer(unit[1], unit[2])..(tblOffline[unit[1]] and '' or ns.code:cText('FF808080', ' <offline>'))..'\n'
        end
        body = gLead..body
    else body = gLead end

    ns.code:createTooltip(title, body, 'FORCE_TOOLTIP')
end
--? End of Group Leader

--* Difficulty frame
function gi:UpdateDifficulty(refresh)
    local dColor = nil
        local msgDifficulty = 'Difficulty: '..ns.code:cText('FFFF0000', 'Unknown')
        local dungeonID = ns.GroupRoster.groupType == 'PARTY' and GetDungeonDifficultyID() or nil
        local rID = ns.GroupRoster.groupType == 'RAID' and GetRaidDifficultyID() or nil

        if not gi.oldDifficulty or refresh or dungeonID ~= gi.oldDifficulty or
            rID == gi.oldDifficulty then

            if dungeonID then
                if dungeonID == 1 then dColor = ns.RARE_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Normal')
                elseif dungeonID == 2 then dColor = ns.EPIC_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Heroic')
                elseif dungeonID == 23 then dColor = ns.LEGENDARY_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Mythic')
                else msgDifficulty = 'Difficulty: '..ns.code:cText('FFFF0000', 'Invalid') end
            elseif rID then
                if rID == 17 then dColor = ns.UNCOMMON_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'LFR')
                elseif rID == 14 then dColor = ns.RARE_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Normal')
                elseif rID == 15 then dColor = ns.EPIC_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Heroic')
                elseif rID == 16 then dColor = ns.LEGENDARY_COLOR msgDifficulty = 'Difficulty: '..ns.code:cText(dColor, 'Mythic')
                else msgDifficulty = L['DIFFICULTY']..': '..ns.code:cText('FFFF0000', 'Invalid') end
            else return end

            gi.oldDifficulty = dungeonID or rID
        else return end

        return msgDifficulty, dColor
end
--? End of Difficulty frame

--* Instance Tooltip
function gi:GetInstanceInfo()
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
    local _, iColor = gi:UpdateDifficulty(true)

    if not iColor or not info[8] or info[8] == 1152 or info[8] == 1331 then
        self.tblFrame.iFrame:SetShown(false)
        self.instanceID, self.instance, self.iColor = nil, nil, nil
        return
    elseif self.instanceID == info[8] then return end

    self.tblFrame.iFrame:SetShown(true)
    self.instanceID = info[8]
    self.instance = info[1]
    self.iColor = iColor

    ns.frames:CreateFadeAnimation(self.tblFrame.iText, ns.code:cText(iColor or 'FFFFFFFF', info[1]))
end
function gi:GetInstanceTooltip()
    if not self.instance then return end

    local title = L['INSTANCE']..': '..self.instance
    local body = (gi:UpdateDifficulty(true))

    ns.code:createTooltip(title, body, 'FORCE_TOOLTIP')
end
--? End of Instance Tooltip
gi:Init()
groupInfo:Init()