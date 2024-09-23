local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.iconBuffs = {}
local iBuffs, gBuffs = {}, ns.iconBuffs

local lastRoster = nil
local function eventGroupRosterUpdate(refresh)
    if lastRoster and GetTime() - lastRoster < 1 then return
    elseif not IsInGroup() or not ns.GroupRoster.groupType or not ns.GroupRoster.groupOut then return end
    lastRoster = GetTime()

    iBuffs:UpdateBuffs(refresh)
    iBuffs:UpdateCounts(refresh)
end

local lastAuraUpdate, auraRunning = nil, false
local function eventCLEU(...)
    if auraRunning then return end

    local _, event, _, _, _, _, _, _, _, _, _, sID, sName = ...
    if event == 'SPELL_AURA_APPLIED' or event == 'SPELL_AURA_REMOVED' then
        if lastAuraUpdate and GetTime() - lastAuraUpdate < .5 then return
        elseif ns.tblBuffsByID[sID] or ns.tblMultiBuffsByID[sID] then
            auraRunning = true
            lastAuraUpdate = GetTime()
            C_Timer.After(.5, function()
                iBuffs:UpdateBuffs()
                iBuffs:UpdateCounts()
                auraRunning = false
            end)
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

    eventGroupRosterUpdate(true)
end

--* Create Buff Icon Frames
local defaultFontSize = 25
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
            numberText:SetFont(ns.MORPHEUS_FONT, defaultFontSize, "OUTLINE")
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
local tblOldBuffs, tblOldMulti, tblBuffsFound, tblClasses = {}, {}, {}, {}
function iBuffs:UpdateBuffs(refresh, count)
    --* Prep Tables
    tblBuffsFound, tblClasses = {}, {}
    tblOldMulti = {}

    tblOldMulti = ns.code:DeepCopy(self.tblMultiBuffs)

    self.tblMultiBuffs = ns.tblIconMulti

    --* Find all buffs
    local finished = true
    for i=1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if not name then finished = false break end

        --name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId
        AuraUtil.ForEachAura(name, 'HELPFUL', 1, function(...)
            local aura = { ... }
            if ns.tblBuffsByID[aura[10]] then
                local key = ns.tblBuffsByID[aura[10]].key
                if not tblBuffsFound[aura[10]] then
                    tblBuffsFound[aura[10]] = {
                        ['key'] = key,
                        ['count'] = 1
                    }
                else tblBuffsFound[aura[10]].count = tblBuffsFound[aura[10]].count + 1 end
            elseif ns.tblMultiBuffsByID[aura[10]] then
                local key = ns.tblMultiBuffsByID[aura[10]].key
                if not tblBuffsFound[aura[10]] then
                    tblBuffsFound[aura[10]] = {
                        ['key'] = key,
                        ['count'] = 1
                    }
                else tblBuffsFound[aura[10]].count = tblBuffsFound[aura[10]].count + 1 end
            end
        end)

        local class = select(6, GetRaidRosterInfo(i))
        tblClasses[class] = (tblClasses[class] or 0) + 1
    end
    if not finished then
        if count > 10 then ns.code:dOut('Failed to find all buffs.', ns.GLHColor, true) return
        else C_Timer.After(1, function() iBuffs:UpdateBuffs(refresh, count+1) end) end
    end

    --* Update Count Only Multi Buffs
    for k, v in ipairs(self.tblMultiBuffs) do
        v.iconFrame.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
        v.iconFrame.overlay:SetAtlas(nil)
        v.iconFrame.text:SetText('')
        v.count, v.buffGiverFound = 0, false

        if v.countOnly then
            for c in pairs(v.class) do
                if tblClasses[c] or tblBuffsFound[v.id] then
                    v.count = (v.count or 0) + tblClasses[c]
                    v.buffGiverFound = true
                end
            end

            if v.buffGiverFound then
                if refresh or v.count ~= tblOldMulti[k].count then
                    v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                    ns.frames:CreateFadeAnimation(v.iconFrame.text, (v.count or ''))
                else
                    v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                    v.iconFrame.text:SetText(v.count or '')
                end
            end
        end
    end
    tblOldMulti = nil
end
function iBuffs:UpdateCounts(refresh)
    tblOldBuffs = {}
    tblOldBuffs = ns.code:DeepCopy(self.tblBuffs)
    self.tblBuffs = ns.tblIconBuffs

    local function updateIcon(k, v)
        v.iconFrame.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
        v.iconFrame.text:SetText('')
        v.iconFrame.overlay:SetAtlas(nil)
        v.count, v.buffGiverFound = 0, false

        v.count = GetNumGroupMembers() - (tblBuffsFound[v.id] and tblBuffsFound[v.id].count or 0)

        for c in pairs(v.class) do
            if tblClasses[c] then
                v.buffGiverFound = true
                break
            end
        end

        if v.buffGiverFound then
            if v.count <= 0 then
                v.count = 0
                v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                if v.count ~= tblOldBuffs[k].count then
                    ns.frames:CreateAnimationAtlas(v.iconFrame.overlay, ns.GREEN_CHECK)
                else v.iconFrame.overlay:SetAtlas(ns.GREEN_CHECK) end
            elseif v.count == GetNumGroupMembers() then
                v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                if v.count ~= tblOldBuffs[k].count then
                    ns.frames:CreateAnimationAtlas(v.iconFrame.overlay, ns.RED_CHECK)
                else v.iconFrame.overlay:SetAtlas(ns.RED_CHECK) end
            else
                v.iconFrame.text:SetTextColor(1, 1, 0, 1)
                v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                if v.count >= 10 then v.iconFrame.text:SetFont(ns.MORPHEUS_FONT, 20, "OUTLINE")
                else v.iconFrame.text:SetFont(ns.MORPHEUS_FONT, defaultFontSize, "OUTLINE") end
                if v.count ~= tblOldBuffs[k].count then
                    ns.frames:CreateFadeAnimation(v.iconFrame.text, (v.count or ''))
                else v.iconFrame.text:SetText(v.count or '') end
            end
        end
    end

    for k, v in ipairs(self.tblBuffs) do updateIcon(k, v) end
    for k, v in ipairs(self.tblMultiBuffs) do
        if not v.countOnly then updateIcon(k, v) end
    end
    tblOldBuffs = nil
end
--? End of Buff Update Routine

--* Create Tooltip Routine
function iBuffs:CreateIconTooltip(key, tbl)
end
--? End of Tooltip Routine

iBuffs:Init()

function gBuffs:SetShown(val) iBuffs:SetShown(val) end