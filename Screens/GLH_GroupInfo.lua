local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.groupInfo = {}
local gi, groupInfo = {}, ns.groupInfo

--* Event Routines
local function eventGroupRosterUpdate(refresh)
    if not IsInGroup() or not ns.groupType or not ns.groupOut then return end

    gi:UpdateGroupComposition(refresh)
    if gi.oldLeader ~= ns.leader[1] or refresh then
        gi.oldLeader = ns.leader[1]
        local cName = UnitIsConnected(ns.leader[1]) and ns.code:cPlayer(ns.leader[1], ns.leader[2]) or ns.code:cPlayer(ns.leader[1], nil, 'FF808080')
        ns.frames:CreateFadeAnimation(gi.tblFrame.leaderText, (L['LEADER']..': '..cName))
    end

    local dID = ns.groupType == 'raid' and GetRaidDifficultyID() or GetDungeonDifficultyID()
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
end
function groupInfo:Init()
    self.tblClasses = {}
end
function groupInfo:SetShown(val)
    if not val then
        if gi.tblFrame.frame then gi.tblFrame.frame:SetShown(val) end

        gi:Init()
        return
    elseif gi.tblFrame.frame and gi.tblFrame.frame:IsShown() then return end

    ns.obs:Register('GROUP_LEFT', function()
        gi.tblFrame.frame:SetShown(false)
    end)
    ns.obs:Register('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)

    gi:CreateBaseFrame()
    gi:UpdateGroupComposition()

    if ns.leader[1] and ns.leader[1] ~= '' then
        print(ns.leader[1])
        gi.oldLeader = ns.leader[1]
        local cName = UnitIsConnected(ns.leader[1]) and ns.code:cPlayer(ns.leader[1], ns.leader[2]) or ns.code:cPlayer(ns.leader[1], nil, 'FF808080')
        ns.frames:CreateFadeAnimation(gi.tblFrame.leaderText, (L['LEADER']..': '..cName))
    end

    local difficulty = gi:UpdateDifficulty()
    if difficulty then ns.frames:CreateFadeAnimation(gi.tblFrame.diffText, difficulty) end

    gi.tblFrame.frame:SetShown(val)
    ns.groupInfo.tblFrame = gi.tblFrame
end
function gi:CreateBaseFrame()
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

    self.tblFrame.frame = f
    self.tblFrame.compText = text

    local lFrame = self.tblFrame.leaderFrame or CreateFrame('Button', 'GLH_GroupLeaderFrame', ns.base.tblBase.top)
    lFrame:SetPoint('TOPLEFT', f, 'BOTTOMLEFT', 7, 0)
    lFrame:SetPoint('BOTTOMRIGHT', ns.base.tblBase.fLock, 'BOTTOMLEFT', 0, 0)
    lFrame:SetHighlightAtlas(ns.BLUE_LONG_HIGHLIGHT)
    self.tblFrame.leaderFrame = lFrame

    local lText = lFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    lText:SetPoint('LEFT', 2, 0)
    lText:SetJustifyH('LEFT')
    lText:SetJustifyV('MIDDLE')
    lText:SetFont(ns.DEFAULT_FONT, 14)
    lText:SetTextColor(1, 1, 1, 1)
    lText:SetWordWrap(false)
    self.tblFrame.leaderText = lText

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
end

--* Update Group Composition
local compOut = nil
local tankIcon, healerIcon, dpsIcon, unknownIcon = '|A:'..ns.TANK_LFR_ICON..':20:20|a', '|A:'..ns.HEALER_LFR_ICON..':20:20|a', '|A:'..ns.DPS_LFR_ICON..':20:20|a', '|A:'..ns.UNKNOWN_LFR_ICON..':20:20|a'
function gi:UpdateGroupComposition(refresh)
    if not ns.groupOut then return end

    groupInfo.tblClasses = {}
    local tblClasses = groupInfo.tblClasses
    local tanks, healers, dps, unknown = ns.code:GetGroupRoles()

    if not refresh and self.oldGroupType == ns.groupType and self.tanks == tanks and self.healers == healers and
        self.dps == dps and self.unknown == unknown then return end

    self.oldGroupType = ns.groupType
    compOut = ns.groupOut..': '..tankIcon..(tanks or 0)..'  '..healerIcon..(healers or 0)..'  '..dpsIcon..(dps or 0)--..' '..unknownIcon..' Unknown'
    self.tanks, self.healers, self.dps, self.unknown = (tanks or 0), (healers or 0), (dps or 0), (unknown or 0)

    ns.frames:CreateFadeAnimation(self.tblFrame.compText, compOut)
end
function gi:CreateGroupCompTooltip()
end
--? End of Group Composition

--* Create Group Leader Tooltip
function gi:CreateGroupLeaderToolTip()
    
end
--? End of Group Leader

--* Difficulty frame
function gi:UpdateDifficulty(refresh)
    local dColor = nil
        local msgDifficulty = 'Difficulty: '..ns.code:cText('FFFF0000', 'Unknown')
        local dungeonID = ns.groupType == 'PARTY' and GetDungeonDifficultyID() or nil
        local rID = ns.groupType == 'RAID' and GetRaidDifficultyID() or nil

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
                else msgDifficulty = 'Difficulty: '..ns.code:cText('FFFF0000', 'Invalid') end
            else return end

            gi.oldDifficulty = dungeonID or rID
        else return end

        return msgDifficulty
end
--? End of Difficulty frame
gi:Init()
groupInfo:Init()