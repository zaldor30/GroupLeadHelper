local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.buffIcons = {}
local icons, buffIcons = {}, ns.buffIcons

local tblBuffs = {}
local mBuffs = {
    __index = function(tbl, key)
        return rawget(tbl, key)
    end,
    __newindex = function(self, key, value)
        rawset(self, key, value)
    end
}
local tblMultiBuffs = {}
local mMultiBuffs = {
    __index = function(self, key)
        return rawget(self, key)
    end,
    __newindex = function(self, key, value)
        rawset(self, key, value)
    end
}
setmetatable(tblBuffs, mBuffs)
setmetatable(tblMultiBuffs, mMultiBuffs)

local function eventGroupRosterUpdate(inGroup)
    icons.tblInGroup = {}
    for i=1, GetNumGroupMembers() do
        local class = UnitClassBase(GetRaidRosterInfo(i))

        if class and icons.tblInGroup[class] then icons.tblInGroup[class] = icons.tblInGroup[class] + 1
        elseif class then icons.tblInGroup[class] = 1 end
    end

    icons:UpdateIcons()
    icons:UpdateAuraCounts()
end

local auraRunning = false
local function eventSpellAura(...)
    local sID = select(12, ...)
    if not auraRunning and sID and (icons.tblBuffsByID[sID] or icons.tblMultiBuffsByID[sID]) then
        auraRunning = true
        icons:UpdateAuraCounts() end
end

function icons:Init()
    self.tblFrame = {}

    tblBuffs = ns.ds:GetBuffs()
    self.tblBuffsByID = {}
    self.tblMultiBuffsByID = {}
    tblMultiBuffs = ns.ds:GetMutliBuffs()

    for _, v in pairs(tblBuffs) do self.tblBuffsByID[v.id] = true end
    for _, v in pairs(tblMultiBuffs) do self.tblBuffsByID[v.id] = true end

    self.tblInGroup = {}
    self.tblBuffsByClass = {}
end
function icons:SetShown(val)
    if not val then
        self.tblFrame.frame:SetShown(val)
        return
    end

    ns.observer:Register('SPELL_AURA', eventSpellAura)
    ns.observer:Register('GROUP_ROSTER_UPDATE', eventGroupRosterUpdate)

    if not self.tblFrame or not self.tblFrame.frame then
        self:Init()
        self:CreateIconFrames()
    end

    self.tblFrame.frame:SetShown(val)
    eventGroupRosterUpdate() -- Initial update
end
function icons:CreateIconFrames()
    local tblBase = ns.base.tblBase

    local function createIconRow(tbl, parentFrame, iconSize, spacing, tableUsed)
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
            overlay:SetAtlas(nil)
            overlay:SetVertexColor(1, 1, 1, 1)
            v.iconFrame.overlay = overlay

            local numberText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            numberText:SetPoint("CENTER", icon, "CENTER", 0, 0)
            numberText:SetFont(ns.MORPHEUS_FONT, 25, "OUTLINE")
            numberText:SetTextColor(1, 1, 1, 1)
            numberText:SetText('')
            v.iconFrame.text = numberText

            icon:SetScript('OnEnter', function(self) icons:CreateIconTooltip(k, tableUsed) end)
            icon:SetScript('OnLeave', function(self) GameTooltip:Hide() end)

            if k == 1 then icon:SetPoint("LEFT", parentFrame, "LEFT", startX, 0)
            else icon:SetPoint("LEFT", tbl[k-1].iconFrame, "RIGHT", spacing, 0) end
        end

        return tbl
    end

    local frame = ns.frames:CreateFrame('GLH_BuffIcons_Row1', ns.base.tblBase.frame)
    frame:SetPoint("TOPLEFT", tblBase.secondRow, "BOTTOMLEFT", 0, -5)
    frame:SetPoint("TOPRIGHT", tblBase.secondRow, "BOTTOMRIGHT", 0, -5)
    frame:SetHeight(40)
    frame:SetShown(true)

    self.tblBuffs = createIconRow(tblBuffs, frame, 40, 2, 'BUFFS')

    local multiHeight = 30
    local multiBuffFrame = ns.frames:CreateFrame('GLH_BuffIcons_Row2', ns.base.tblBase.frame)
    multiBuffFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -5)
    multiBuffFrame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -5)
    multiBuffFrame:SetHeight(multiHeight)
    multiBuffFrame:SetShown(true)

    self.tblMultiBuffs = createIconRow(tblMultiBuffs, multiBuffFrame, multiHeight, 2, 'MULTI')

    self.tblFrame.frame = frame
end

--* Update Routines
function icons:UpdateIcons()
    for _, v in pairs(self.tblBuffs) do
        v.iconFrame.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
        v.iconFrame.text:SetText('')

        local count = 0
        for key in pairs(v.class) do
            if self.tblInGroup[key] then
               count = count + self.tblInGroup[key]
                if count > 0 then
                    v.iconFrame.texture:SetVertexColor(1, 1, 1, 1)
                    if v.id == 80353 then v.iconFrame.text:SetText(count)
                    else v.iconFrame.overlay:SetAtlas(ns.RED_CHECK) end
                end
            end
        end
    end

    for _, v in pairs(self.tblMultiBuffs) do
        v.iconFrame.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
        v.iconFrame.text:SetText('')

        local count = 0
        for key in pairs(v.class) do
            if self.tblInGroup[key] then
                count = count + self.tblInGroup[key]
                if count > 0 then v.iconFrame.texture:SetVertexColor(1, 1, 1, 1) end
                if v.id ~= 465 then v.iconFrame.text:SetText(count)
                else v.iconFrame.overlay:SetAtlas(ns.RED_CHECK) end
            end
        end
    end
end
function icons:UpdateAuraCounts()
    for _, v in pairs(tblBuffs) do v.count = 0 end
    for _, v in pairs(tblMultiBuffs) do v.count = 0 end

    local function findBuff(tbl, spellId)
        for k, v in pairs(tbl) do
            if v.id == spellId then auraRunning = false return k end
        end
    end

    for i=1, GetNumGroupMembers() do
        local unit = GetRaidRosterInfo(i)
        if not unit then auraRunning = false return end

        AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId)
            if spellId == 465 then
                local index = (spellId and spellId ~= 80353) and findBuff(tblMultiBuffs, spellId) or nil
                if index then
                    tblMultiBuffs[index].count = tblMultiBuffs[index].count + 1
                    if tblMultiBuffs[index].count >= GetNumGroupMembers() then tblMultiBuffs[index].iconFrame.overlay:SetAtlas(ns.GREEN_CHECK)
                    else tblMultiBuffs[index].iconFrame.overlay:SetAtlas(ns.RED_CHECK) end
                end
            else
                local index = findBuff(tblBuffs, spellId)
                if index then
                    tblBuffs[index].count = tblBuffs[index].count + 1
                    if tblBuffs[index].count >= GetNumGroupMembers() then tblBuffs[index].iconFrame.overlay:SetAtlas(ns.GREEN_CHECK)
                    else tblBuffs[index].iconFrame.overlay:SetAtlas(ns.RED_CHECK) end
                end
            end
        end)
    end

    auraRunning = false
end
function icons:CreateIconTooltip(index, tableUsed)
    local tbl = tableUsed == 'BUFFS' and tblBuffs or tblMultiBuffs
    local v = tbl[index]
    if not v or not v.id then return end

    local title = v.name..' Buffed: '..v.count..'/'..GetNumGroupMembers()
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

function buffIcons:IsShown() return icons.tblFrame.frame:IsShown() end
function buffIcons:SetShown(val) icons:SetShown(val) end