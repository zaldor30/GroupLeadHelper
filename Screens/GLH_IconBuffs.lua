local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.iconBuffs = {}
local buffs = ns.iconBuffs

local function eventGroupRosterUpdate(refresh)
    buffs:UpdateBuffs(refresh)
    buffs:UpdateCounts(refresh)
end
local isRunning = false
local function eventCLEU(tblCLEU)
    local sID = tblCLEU[10]
    if isRunning then return

    --* Using sID 1297, seems to be the id that is sent with Battle Shout (6673) aura
    elseif (sID == 1297 or ns.tblBuffsByID[sID] or ns.tblMultiBuffsByID[sID]) and
        (tblCLEU[2] == 'SPELL_AURA_APPLIED' or tblCLEU[2] == 'SPELL_AURA_REMOVED') then
        isRunning = true
        buffs:UpdateBuffs()
        buffs:UpdateCounts()
        isRunning = false
    end
end

function buffs:Init()
    self.tblFrame = {}

    self.tblBuffs = {}
    self.tblMultiBuffs = {}
    self.tblClasses = nil
end
function buffs:IsShown() return (self.tblFrame and self.tblFrame.frame) and self.tblFrame.frame:IsShown() or false end
function buffs:SetShown(val)
    if not val then
        if self.tblFrame and self.tblFrame.row1 then
            self.tblFrame.row1:SetShown(val)
            self.tblFrame.row2:SetShown(val)

            ns.cleuEvents['SPELL_AURA_APPLIED'] = nil
            ns.cleuEvents['SPELL_AURA_REMOVED'] = nil

            ns.obs:Unregister('CLEU:ICON_BUFFS', eventCLEU)
            ns.obs:Unregister('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)
        end
        return
    end

    if not self.tblFrame or not self.tblFrame.row1 then
        self:Init()
        self:CreateRow1Frame()
        self:CreateRow2Frame()
    end

    self.tblFrame.row1:SetShown(val)
    self.tblFrame.row2:SetShown(val)

    --* CLEU Subevents to look for
    ns.cleuEvents['SPELL_AURA_APPLIED'] = true
    ns.cleuEvents['SPELL_AURA_REMOVED'] = true

    ns.obs:Register('CLEU', eventCLEU)
    ns.obs:Register('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)

    self:UpdateBuffs(true)
    self:UpdateCounts(true)
end

--* Create Icon Buffs Frame
local defaultFontSize = 25
function buffs:CreateIconFrames(tbl, parentFrame, iconSize, spacing, tableUsed)
    local totalWidth = (iconSize * #tbl) + (spacing * (#tbl - 1))
        local startX = (parentFrame:GetWidth() - totalWidth) / 2

        for k, v in ipairs(tbl) do
            local icon = ns.frames:CreateFrame('Button', 'GLH_BuffIcon_'..k, parentFrame)
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

            icon:SetScript('OnEnter', function(self) buffs:CreateIconTooltip(k, tableUsed) end)
            icon:SetScript('OnLeave', function(self) GameTooltip:Hide() end)

            if k == 1 then icon:SetPoint("LEFT", parentFrame, "LEFT", startX, 0)
            else icon:SetPoint("LEFT", tbl[k-1].iconFrame, "RIGHT", spacing, 0) end
        end

        return tbl
end
--? End of Icon Buffs Frame

--* Create Row 1 Icon Buffs Frame
local iconHeight = 30
function buffs:CreateRow1Frame()
    local fRow1 = ns.frames:CreateFrame('Frame', 'GLH_BuffIcons_Row1', ns.base.tblFrame.frame)
    fRow1:SetPoint("CENTER", ns.base.tblFrame.frame, "CENTER", 0, (iconHeight / 2) + 5)
    fRow1:SetSize(ns.base.tblFrame.frame:GetWidth(), iconHeight)
    fRow1:SetShown(true)
    self.tblFrame.row1 = fRow1

    self.tblBuffs = self:CreateIconFrames(ns.tblIconBuffs, fRow1, iconHeight, 2, 'BUFFS')
end
--? Create Row 2 Icon Buffs Frame

--* Create Row 2 Icon Buffs Frame
function buffs:CreateRow2Frame()
    local fRow2 = ns.frames:CreateFrame('Frame', 'GLH_BuffIcons_Row2', ns.gi.tblFrame.frame)
    fRow2:SetPoint("TOP", self.tblFrame.row1, "BOTTOM", 0, -2)
    fRow2:SetSize(ns.gi.tblFrame.frame:GetWidth(), iconHeight)
    fRow2:SetShown(true)
    self.tblFrame.row2 = fRow2

    self.tblMultiBuffs = self:CreateIconFrames(ns.tblIconMulti, fRow2, iconHeight - 5, 2, 'MULTI_BUFFS')
end
--? End of Create Row 2 Icon Buffs Frame

--* Buff Update/Tooltip Functions
local tblOldBuffs, tblOldMulti, tblBuffsFound, tblClasses = {}, {}, {}, {}
function buffs:UpdateBuffs(refresh)
    if not ns.roster then return end

    tblBuffsFound, tblOldMulti, tblClasses = {}, ns.code:DeepCopy(self.tblMultiBuffs), {}
    self.tblMultiBuffs = ns.tblIconMulti

    --* Find all buffs
    tblClasses = {}
    for _, v in pairs(ns.roster) do
        AuraUtil.ForEachAura(v.name, 'HELPFUL', 1, function(...)
            local aura = { ... }
            if ns.tblBuffsByID[aura[10]] then
                local key = ns.tblBuffsByID[aura[10]].key
                if not tblBuffsFound[aura[10]] then
                    tblBuffsFound[aura[10]] = { key = key, count = 1 }
                else tblBuffsFound[aura[10]].count = tblBuffsFound[aura[10]].count + 1 end
            elseif ns.tblMultiBuffsByID[aura[10]] then
                local key = ns.tblMultiBuffsByID[aura[10]].key
                if not tblBuffsFound[aura[10]] then
                    tblBuffsFound[aura[10]] = { key = key, count = 1 }
                else tblBuffsFound[aura[10]].count = tblBuffsFound[aura[10]].count + 1 end
            end
        end)

        local class = v.classFile
        if class then
            tblClasses[class] = (tblClasses[class] or 0) + 1 end
    end

    --* Update Multi Buff Counts
    for k, v in ipairs(self.tblMultiBuffs) do
        v.iconFrame.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
        v.iconFrame.overlay:SetAtlas(nil)
        v.iconFrame.text:SetText('')
        v.count, v.buffGiverFound = 0, false

        if v.countOnly then
            for c in pairs(v.class) do
                if tblClasses[c] or tblBuffsFound[v.id] then
                    v.count = (v.count or 0) + (tblClasses[c] or 0)
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
function buffs:UpdateCounts(refresh)
    tblOldBuffs = ns.code:DeepCopy(self.tblBuffs)
    self.tblBuffs = ns.tblIconBuffs

    local function updateIcon(k, v)
        if v.countOnly then return end

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
function buffs:CreateIconTooltip(k, tableUsed)
    local tbl = tableUsed == 'BUFFS' and ns.tblIconBuffs or ns.tblIconMulti
    local v = tbl[k]
    if not v or not v.id then return end

    local title = v.name..(v.countOnly and '' or ' Buffed: '..v.count..'/'..GetNumGroupMembers())
    local msg = ns.code:wordWrap(C_Spell.GetSpellDescription(v.id))..'\n \nCapable Classes:\n'

    local count = 0

    local cSorted = ns.code:sortTableByField(v.class)

    for _, r in pairs(cSorted or {}) do
        count = count < 3 and count + 1 or 1
        msg = msg..ns.code:cText(ns.ds.tblClassesByFile[r].classColor, ns.ds.tblClassesByFile[r].className)
        msg = count < 3 and msg..', ' or msg..'\n'
    end

    msg = msg:trim()
    if string.sub(msg, -1) == ',' then msg = string.sub(msg, 1, -2) end
    ns.code:createTooltip(title, msg)
    
end
--? End of Buff Update/Tooltip Functions