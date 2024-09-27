local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.base = {}
local base = ns.base

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

--* Observer Functions
local function obsGROUP_LEFT() base:SetShown(false) end

function base:Init()
    self.isMoveLocked = true
    self.screenPos = { point = 'CENTER', x = 0, y = 0 }

    self.tblFrame = {}
end
function base:IsShown() return (self.tblFrame and self.tblFrame.frame) and self.tblFrame.frame:IsShown() or false end
function base:SetShown(val)
    if not val then
        if self.tblFrame.frame then
            self.tblFrame.frame:SetShown(val)
            ns.gi:SetShown(val)
            ns.iconBuffs:SetShown(val)
        end

        return
    end

    ns.obs:Register('GROUP_LEFT', obsGROUP_LEFT)

    if not self.tblFrame.frame then
        self:CreateBaseFrame()
        self:CreateButtonBar()
    end

    self.tblFrame.frame:SetShown(val)
    ns.gi:SetShown(val)
    ns.iconBuffs:SetShown(val)
end
function base:CreateBaseFrame()
    --* Create the Base Frame
    local f = ns.frames:CreateFrame('Frame', 'GLH_BaseFrame', UIParent, 'USE_BACKDROP')
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

    --* Create the Top Frame (Horde/Alliance)
    local top = ns.frames:CreateFrame('Frame', 'GLH_BaseFrameTop', f)
    top:EnableMouse(false)
    top:SetPoint('BOTTOM', f, 'TOP', -2, -20)
    top:SetSize(f:GetWidth(), 40)
    self.tblFrame.top = top

    local texture = top:CreateTexture(nil, 'ARTWORK')
    texture:SetAtlas(UnitFactionGroup('player') == 'Horde' and ns.HORDE_HEADER or ns.ALLIANCE_HEADER)
    texture:SetAllPoints()
    texture:SetVertexColor(1, 1, 1, 1)
end
function base:CreateButtonBar()
    --* Close Button
    local bX, bY = 20, 20 -- Button X, Button Y (Size)
    local f = ns.frames:CreateFrame('Button', 'GLH_CloseBase_Button', self.tblFrame.top)
    f:SetSize(bX, bY)
    f:SetPoint('TOPRIGHT', self.tblFrame.top, 'BOTTOMRIGHT', -3, 0)
    f:SetNormalAtlas(ns.CLOSE)
    f:SetPushedAtlas(ns.CLOSE_PRESSED)
    f:SetHighlightAtlas(ns.CLOSE_HIGHLIGHT)

    f:SetScript('OnClick', function() self:SetShown(false) end)

    --* Minimize Button
    local fMin = ns.frames:CreateFrame('Button', 'GLH_MinimizeBase_Button', self.tblFrame.top)
    fMin:SetSize(bX, bY)
    fMin:SetPoint('RIGHT', f, 'LEFT', 0, 0)
    fMin:SetNormalAtlas(ns.MINIMIZE)
    fMin:SetPushedAtlas(ns.MINIMIZE_PRESSED)
    fMin:SetHighlightAtlas(ns.MINIMIZE_HIGHLIGHT)

    fMin:SetScript('OnClick', function() self.tblFrame.frame:SetShown(false) end)

    --* Refresh Button
    local fRefresh = ns.frames:CreateFrame('Button', 'GLH_RefreshBase_Button', self.tblFrame.top)
    fRefresh:SetSize(bX, bY)
    fRefresh:SetPoint('RIGHT', fMin, 'LEFT', 0, 0)
    fRefresh:SetNormalAtlas(ns.REFRESH)
    fRefresh:SetPushedAtlas(ns.REFRESH_PRESSED)
    fRefresh:SetHighlightAtlas(ns.REFRESH_HIGHLIGHT)

    fRefresh:SetScript('OnClick', function() ns.events:Refresh() end)

    --* Lock Button
    local waitTimer = nil
    local fLock = ns.frames:CreateFrame('Button', 'GLH_LockBase_Button', self.tblFrame.top)
    fLock:SetSize(bX, bY)
    fLock:SetPoint('RIGHT', fRefresh, 'LEFT', 0, 0)
    fLock:SetNormalAtlas(ns.MOVE_LOCKED)
    fLock:SetHighlightAtlas(ns.MOVE_LOCK_HIGHLIGHT)

    fLock:SetScript('OnClick', function()
        self.isMoveLocked = not self.isMoveLocked

        local function setLockState()
            ns.obs:Notify('MOVING_FRAME', self.isMoveLocked)
            base.tblFrame.frame:SetMovable(not self.isMoveLocked)
            fLock:SetNormalAtlas(self.isMoveLocked and ns.MOVE_LOCKED or ns.MOVE_UNLOCKED)
        end
        setLockState()

        if self.isMoveLocked then
            if waitTimer then
                GLH:CancelTimer(waitTimer)
                waitTimer = nil
            end
            return
        end

        waitTimer = GLH:ScheduleTimer(function()
            if not waitTimer then return end

            GLH:CancelTimer(waitTimer)
            self.isMoveLocked = true
            setLockState()
            ns.obs:Notify('MOVING_FRAME', self.isMoveLocked)
            ns.code:fOut('Moving GLH expired.  GLH window has re-locked.', ns.GLHColor)
        end, 15)
    end)
    base.tblFrame.fLock = fLock -- Used for group leader setpoint
end
base:Init()