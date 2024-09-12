local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.base = {}
local base, gBase = {}, ns.base

local tblFrame = {}
local locked = 'gficon-chest-evergreen-greatvault-incomplete'
local unlocked = 'gficon-chest-evergreen-greatvault-complete'

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
end
function base:SetShown(val)
    if not val then
        tblFrame.frame:Hide()
        ns.observer:Notify('OPEN_SCREENS')
    end

    self.screenPos = ns.p.screenPos or self.pos
    if not tblFrame.frame then
        self:CreateFirstRowFrame()
        self:CreateSecondRowFrame()
    end

    tblFrame.frame:SetShown(val)
end
function base:CreateFirstRowFrame() --* Frame and group comp, lock and close
    --* Create the main frame
    local f = ns.frames:CreateFrame('GLH_Base_Frame', UIParent, true)
    f:SetSize(350, 150)
    f:SetPoint(self.screenPos.point, self.screenPos.x, self.screenPos.y)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag('LeftButton')
    f:SetScript('OnDragStart', OnDragStart)
    f:SetScript('OnDragStop', OnDragStop)
    f:SetScript('OnHide', function()
        ns.observer:Notify('CLOSE_SCREENS')
    end)
    tblFrame.frame = f
    gBase.tblFrame = tblFrame

    --* Create the top frame components
    local b = ns.frames:CreateFrame('GLH_Base_Close', f, false, nil, 'Button')
    b:SetSize(30, 30)
    b:SetPoint('TOPRIGHT', 0, 0)
    b:SetNormalTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Up')
    b:SetPushedTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Down')
    b:SetHighlightTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight')
    b:SetScript('OnClick', function() base:SetShown(false) end)
    tblFrame.close = b

    local bLock = ns.frames:CreateFrame('GLH_Base_Lock', f, false, nil, 'Button')
    bLock:SetSize(20, 20)
    bLock:SetPoint('RIGHT', b, 'LEFT', 0, 0)
    bLock:SetNormalTexture(base.isMoveLocked and locked or unlocked)
    --bLock:SetPushedTexture(ns.frames.BUTTON_LOCKED)
    bLock:SetHighlightTexture(unlocked)
    bLock:SetScript('OnClick', function()
        base.isMoveLocked = not base.isMoveLocked
        bLock:SetNormalTexture(base.isMoveLocked and locked or unlocked)
        --bLock:SetPushedTexture(base.isMoveLocked and ns.frames.BUTTON_UNLOCKED or ns.frames.BUTTON_LOCKED)
        bLock:SetHighlightTexture(base.isMoveLocked and unlocked or locked)
    end)

    --* Create Group Comp
    local t = ns.frames:CreateFrame('GLH_Base_Title', f, false, nil, 'Button')
    t:SetHeight(20)
    t:SetPoint('LEFT', f, 'LEFT', 5, 0)
    t:SetPoint('TOPRIGHT', bLock, 'TOPLEFT', -5, 0)
    t:SetHighlightTexture(ns.BLUE_LONG_HIGHLIGHT)
    tblFrame.tFrame = t

    local txt = t:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    txt:SetText('Group Lead Helper')
    txt:SetPoint('LEFT', 7, 0)
    tblFrame.tText = txt

    local fadeOutGroup = txt:CreateAnimationGroup()
    local fadeOut = fadeOutGroup:CreateAnimation('Alpha')
    fadeOut:SetFromAlpha(1)  -- Start fully visible
    fadeOut:SetToAlpha(0)    -- End fully invisible
    fadeOut:SetDuration(2)
    fadeOut:SetSmoothing("OUT")

    local fadeInGroup = txt:CreateAnimationGroup()
    local fadeIn = fadeInGroup:CreateAnimation('Alpha')
    fadeIn:SetFromAlpha(0)  -- Start fully visible
    fadeIn:SetToAlpha(1)    -- End fully invisible
    fadeIn:SetDuration(2)
    fadeIn:SetSmoothing("IN")

    fadeOutGroup:SetScript('OnFinished', function() fadeInGroup:Play() end)

    local originalSettext = txt.SetText
    function txt:SetText(text, skipFade)
        if not text or text == '' then
            originalSettext(self, 'Group Lead Helper '..ns.versionOut)
            return
        else originalSettext(self, text) end

        if skipFade then return end
        fadeOutGroup:Stop()
        fadeOutGroup:Play()
    end
    ns.groupComp = txt
    ns.groupComp:SetText()
end
function base:CreateSecondRowFrame()
    local f = ns.frames:CreateFrame('GLH_Base_SecondRow', tblFrame.frame)
    f:SetPoint('TOPLEFT', tblFrame.tFrame, 'BOTTOMLEFT', 3, 0)
    f:SetPoint('RIGHT', tblFrame.close, 'RIGHT', -5, 0)
    f:SetHeight(20)

    --* Difficulty Text
    local txt = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    txt:SetText('')
    txt:SetPoint('LEFT', 7, 0)
    tblFrame.tText = txt

    ns.frames:FadeSetText(txt, 'Difficulty: Normal')

    ns.difficulty = txt
    ns.difficulty:SetText()

    --* Instance Text
    

    --ns.instance = txt2
    --ns.instance:SetText('Raid: Castle Nathria')

    C_Timer.After(12, function()
        print('Setting text')
        ns.frames:FadeSetText(ns.difficulty, 'Difficulty: Mythic')
        --ns.instance:SetText('Raid: Sanctum of Domination2')
    end)
end
base:Init()

function gBase:IsShown() return tblFrame.frame and tblFrame.frame:IsShown() or false end
function gBase:SetShown(val) base:SetShown(val) end