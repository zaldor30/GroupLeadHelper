local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.iconBuffs = {}
local iBuffs, gBuffs = {}, ns.iconBuffs

local function eventGroupRosterUpdate(refresh)
    if not IsInGroup() or not ns.groupType or not ns.groupOut then return end

    iBuffs:UpdateBuffIcons(refresh)
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

    self:UpdateBuffIcons()
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

    self.tblBuffs = self:CreateIconFrames(ns.tblIconMulti, fRow2, iconHeight, 2, 'MULTI_BUFFS')
end
--? End of Buff Icon Frames

--* Create Buff Update Routine
function iBuffs:UpdateBuffIcons(refresh)
    
end
--? End of Buff Update Routine

--* Create Tooltip Routine
function iBuffs:CreateIconTooltip(key, tbl)
end
--? End of Tooltip Routine

iBuffs:Init()

function gBuffs:SetShown(val) iBuffs:SetShown(val) end