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

--* Base Functions
function base:Init()
    self.isMoveLocked = true
    self.screenPos = { point = 'CENTER', x = 0, y = 0 }

    self.tblFrame = {}
end
function base:IsShown() return (self.tblFrame and self.tblFrame.frame) and self.tblFrame.frame:IsShown() or false end
function base:SetShown(val)
    if not val and not base:IsShown() then return
    elseif not val then
        self.tblFrame.frame:SetShown(val)
        --ns.groupInfo:SetShown(val)
        --ns.iconBuffs:SetShown(val)

        return
    end
end