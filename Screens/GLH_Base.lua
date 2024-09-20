local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.base = {}
local base, gBase = {}, ns.base

local locked = 'gficon-chest-evergreen-greatvault-incomplete' --'pvptalents-talentborder-locked' --'Professions_Specialization_Lock'
local unlocked = 'gficon-chest-evergreen-greatvault-complete' --'pvptalents-talentborder'
local highlight = 'gficon-chest-evergreen-greatvault-collect' --'pvptalents-talentborder-glow' --'Professions_Specialization_Lock_Glow'

--* Windows Dragging
local function OnDragStart(self)
    if base.isMoveLocked then return end
    self:StartMoving()
end
local function OnDragStop(self)
    self:StopMovingOrSizing()

    base.screenPos.point,_,_, base.screenPos.x, base.screenPos.y = self:GetPoint()
    ns.p.screenPos = base.screenPos
end

function base:Init()
    self.isMoveLocked = true
    self.screenPos = { point = 'CENTER', x = 0, y = 0 }

    self.tblFrame = {}
end
base:Init()

function base:SetShown(val)
    if not IsInGroup() then
        ns.code:fOut(L['NOT_IN_GROUP'], ns.GLHColor)
        return end

    if not val then
        if self.tblFrame.frame then self.tblFrame.frame:SetShown(val) end

        return
    end

    ns.obs:Register('GROUP_LEFT', function()
        self.tblFrame.frame:SetShown(false)
    end)

    if not self.tblFrame.frame then
        self:CreateBaseFrame()
        self:CreateButtonBar()
    end

    self.tblFrame.frame:SetShown(val)
    ns.groupInfo:SetShown(val)
    ns.iconBuffs:SetShown(val)
    gBase.tblBase = self.tblFrame
end
function base:CreateBaseFrame()
    local f = self.tblFrame.frame or CreateFrame('Frame', 'GLH_BaseFrame', UIParent, "BackdropTemplate")
    f:SetBackdrop(ns.BackdropTemplate())
    f:SetBackdropColor(0, 0, 0, 0.7)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    f:SetFrameStrata(ns.BACKGROUND_STRATA)
    f:SetClampedToScreen(true)
    f:SetSize(300, 150)
    f:SetPoint(ns.p.screenPos.point, ns.p.screenPos.x, ns.p.screenPos.y)
    f:SetMovable(false)
    f:EnableMouse(true)
    f:RegisterForDrag('LeftButton')
    self.tblFrame.frame = f

    f:SetScript('OnDragStart', OnDragStart)
    f:SetScript('OnDragStop', OnDragStop)

    local top = self.tblFrame.top or CreateFrame('Frame', 'GLH_BaseFrameTop', f)
    top:EnableMouse(false)
    top:SetPoint('BOTTOM', f, 'TOP', -2, -20)
    top:SetSize(f:GetWidth(), 40)
    self.tblFrame.top = top

    local texture = top:CreateTexture(nil, 'ARTWORK')
    texture:SetAtlas(UnitFactionGroup('player') == 'Horde' and ns.HORDE_HEADER or ns.ALLIANCE_HEADER)
    texture:SetAllPoints()
    texture:SetVertexColor(1, 1, 1, 1)

    gBase.tblBase = self.tblFrame
end
function base:CreateButtonBar()
    local bX, bY = 20, 20
    local f = CreateFrame('Button', 'GLH_CloseBase_Button', self.tblFrame.top)
    f:SetPoint('TOPRIGHT', self.tblFrame.top, 'BOTTOMRIGHT', -3, 0)
    f:SetSize(bX, bY)
    f:SetNormalAtlas(ns.CLOSE)
    f:SetPushedAtlas(ns.CLOSE_PRESSED)
    f:SetHighlightAtlas(ns.CLOSE_HIGHLIGHT)
    f:SetScript('OnClick', function() self:SetShown(false) end)

    local fMin = CreateFrame('Button', 'GLH_Minimize_Button', self.tblFrame.top)
    fMin:SetPoint('RIGHT', f, 'LEFT', 0, 0)
    fMin:SetSize(bX, bY)
    fMin:SetNormalAtlas(ns.MINIMIZE)
    fMin:SetPushedAtlas(ns.MINIMIZE_PRESSED)
    fMin:SetHighlightAtlas(ns.MINIMIZE_HIGHLIGHT)
    fMin:SetScript('OnClick', function() self.tblFrame.frame:SetShown(false) end)

    local fRefresh = CreateFrame('Button', 'GLH_Refresh_Button', self.tblFrame.top)
    fRefresh:SetPoint('RIGHT', fMin, 'LEFT', 0, 0)
    fRefresh:SetSize(bX, bY)
    fRefresh:SetNormalAtlas(ns.REFRESH)
    fRefresh:SetPushedAtlas(ns.REFRESH_PRESSED)
    fRefresh:SetHighlightAtlas(ns.REFRESH_HIGHLIGHT)
    fRefresh:SetScript('OnClick', function() ns.core:Refresh() end)

    local fLock = CreateFrame('Button', 'GLH_Lock_Button', self.tblFrame.top)
    fLock:SetPoint('RIGHT', fRefresh, 'LEFT', 0, 0)
    fLock:SetSize(bX, bY)
    fLock:SetNormalAtlas(locked)
    fLock:SetHighlightAtlas(highlight)
    fLock:SetScript('OnClick', function()
        self.isMoveLocked = not self.isMoveLocked
        gBase.tblBase.frame:SetMovable(not self.isMoveLocked)
        fLock:SetNormalAtlas(self.isMoveLocked and locked or unlocked)
    end)
    gBase.tblBase.fLock = fLock -- Used for group leader setpoint
end

function gBase:Init()
    gBase.tblBase = {}
end
gBase:Init()

function gBase:IsShown() return base.tblFrame.frame and base.tblFrame.frame:IsShown() or false end
function gBase:SetShown(val) base:SetShown(val) end