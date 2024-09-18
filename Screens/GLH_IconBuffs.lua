local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.iconBuffs = {}
local iBuffs, gBuffs = {}, ns.iconBuffs

local function eventGroupRosterUpdate(refresh)
    if not refresh and not iBuffs.tblClasses then return
    elseif not IsInGroup() or not ns.groupType or not ns.groupOut then return end

    iBuffs.tblClasses = {}
    local tblOld = iBuffs.tblClasses
    for i=1, GetNumGroupMembers() do
        local class = select(6, GetRaidRosterInfo(i))
        iBuffs.tblClasses[class] = iBuffs.tblClasses[class] and iBuffs.tblClasses[class] + 1 or 1
    end

    local changed = false
    if not refresh then
        for k, v in pairs(iBuffs.tblClasses) do
            if tblOld[k] ~= v then changed = true break end
        end
    end

    if changed or refresh then
        iBuffs:UpdateBuffIcons()
        iBuffs:UpdateAuraCounts(refresh)
    end
end
local lastUpdate = nil
local function eventCLEU(...)
    local _, event, _, _, _, _, _, _, _, _, _, sID, sName = ...
    if event == 'SPELL_AURA_APPLIED' or event == 'SPELL_AURA_REMOVED' then
        if lastUpdate and GetTime() - lastUpdate < .5 then return
        elseif ns.tblBuffsByID[sID] or ns.tblMultiBuffsByID[sID] then
            lastUpdate = GetTime()
            iBuffs:UpdateBuffIcons()
        end
    end
end

function iBuffs:Init()
    self.tblFrame = {}

    self.tblBuffs = {}
    self.tblMultiBuffs = {}
    self.tblClasses = nil
end
function iBuffs:IsShown() return self.tblFrame.frame or false end
function iBuffs:SetShown(val)
    if not val then
        self.tblFrame.row1:SetShown(val)
        self.tblFrame.row2:SetShown(val)
        return
    end

    if not self.tblFrame.row1 then self:CreateRowFrames() end

    self.tblFrame.row1:SetShown(val)
    self.tblFrame.row2:SetShown(val)

    ns.obs:Register('CLEU:ICON_BUFFS', eventCLEU)
    ns.obs:Register('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)

    C_Timer.After(.5, function() eventGroupRosterUpdate(true) end)
end

--* Create Buff Icon Frames
function iBuffs:CreateIconFrames(tbl, parentFrame, iconSize, spacing, tableUsed)
    local totalWidth = (iconSize * #tbl) + (spacing * (#tbl - 1))
        local startX = (parentFrame:GetWidth() - totalWidth) / 2

        for k, v in ipairs(tbl) do
            local icon = ns.frames:CreateFrame('GLH_BuffIcon_'..k, parentFrame, false, nil, 'Button')
            icon:SetHighlightTexture(ns.BLUE_HIGHLIGHT)
            icon:SetSize(iconSize, iconSize)
            v.iconFrame = icon

            local texture = icon:CreateTexture(nil, 'BACKGROUND')
            texture:SetAllPoints()
            texture:SetTexture(v.icon)
            texture:SetVertexColor(0.5, 0.5, 0.5, 1)
            v.iconFrame.texture = texture

            local overlay = icon:CreateTexture(nil, 'ARTWORK')
            overlay:SetAllPoints()
            overlay:SetVertexColor(1, 1, 1, 1)
            v.iconFrame.overlay = overlay

            local numberText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            numberText:SetPoint("CENTER", icon, "CENTER", 0, 0)
            numberText:SetFont(ns.MORPHEUS_FONT, 25, "OUTLINE")
            numberText:SetTextColor(1, 1, 1, 1)
            v.iconFrame.text = numberText

            icon:SetScript('OnEnter', function(self) iBuffs:CreateIconTooltip(k, tableUsed) end)
            icon:SetScript('OnLeave', function(self) GameTooltip:Hide() end)

            if k == 1 then icon:SetPoint("LEFT", parentFrame, "LEFT", startX, 0)
            else icon:SetPoint("LEFT", tbl[k-1].iconFrame, "RIGHT", spacing, 0) end
        end

        return tbl
end
function iBuffs:CreateRowFrames()
    local iconHeight = 35
    local fRow1 = ns.frames:CreateFrame('GLH_BuffIcons_Row1', ns.base.tblBase.frame)
    fRow1:SetPoint("CENTER", ns.base.tblBase.frame, "CENTER", 0, (iconHeight/2) -10)
    fRow1:SetSize(ns.base.tblBase.frame:GetWidth(), iconHeight)
    fRow1:SetShown(true)
    self.tblFrame.row1 = fRow1

    self.tblBuffs = self:CreateIconFrames(ns.tblIconBuffs, fRow1, iconHeight, 2, 'BUFFS')

    iconHeight = 30
    local fRow2 = ns.frames:CreateFrame('GLH_BuffIcons_Row1', ns.base.tblBase.frame)
    fRow2:SetPoint("TOP", fRow1, "BOTTOM", 0, -5)
    fRow2:SetSize(ns.base.tblBase.frame:GetWidth(), iconHeight)
    fRow2:SetShown(true)
    self.tblFrame.row2 = fRow2

    self.tblMultiBuffs = self:CreateIconFrames(ns.tblIconMulti, fRow2, iconHeight, 2, 'MULTI_BUFFS')
end
--? End of Buff Icon Frames

--* Create Buff Update Routine
function iBuffs:UpdateBuffIcons()
    --* Main Icon Buffs
    for _, v in ipairs(self.tblBuffs) do
        v.iconFrame.text:SetText('')
        v.iconFrame.overlay:SetAtlas(nil)
        v.iconFrame.texture:SetVertexColor(0.5, 0.5, 0.5, 1)

        for k in pairs(v.class) do
            if self.tblClasses[k] then
                v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                break
            end
        end
    end

    --* Multi Icon Buffs
    for _, v in ipairs(self.tblMultiBuffs) do
        v.iconFrame.text:SetText('')
        v.iconFrame.overlay:SetAtlas(nil)
        v.iconFrame.texture:SetVertexColor(0.5, 0.5, 0.5, 1)

        for k in pairs(v.class) do
            if self.tblClasses[k] then
                v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                if v.countOnly then ns.frames:CreateFadeAnimation(v.iconFrame.text, self.tblClasses[k]) end
                break
            end
        end
    end
end
function iBuffs:UpdateAuraCounts(refresh)
    for _, v in ipairs(self.tblBuffs) do v.count = 0 end
    for _, v in ipairs(self.tblMultiBuffs) do v.count = 0 end
end
--? End of Buff Update Routine

--* Create Tooltip Routine
function iBuffs:CreateIconTooltip(key, tbl)
end
--? End of Tooltip Routine

iBuffs:Init()

function gBuffs:SetShown(val) iBuffs:SetShown(val) end