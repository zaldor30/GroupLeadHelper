local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.code, ns.observer = {}, {}
local code, observer = ns.code, ns.observer

--* Console print routines
function code:consolePrint(msg, color, noPrefix)
    if msg == '' or not msg then return end

    local prefix = not noPrefix and self:cText(ns.GLHColor, 'RLH: ') or ''

    color = strlen(color) == 6 and 'FF'..color or color
    DEFAULT_CHAT_FRAME:AddMessage(prefix..code:cText(color or 'FFFFFFFF', msg))
end
function code:cOut(msg, color, noPrefix) -- Console print routine
    if msg == '' or not msg then return end

    --!Check to show console messages
    code:consolePrint(msg, (color or '97FFFFFF'), noPrefix)
end
function code:dOut(msg, color, noPrefix) -- Debug print routine
    if msg == '' or not ns.debug then return end
    code:consolePrint(msg, (color or 'FFD845D8'), noPrefix)
end
function code:fOut(msg, color, noPrefix) -- Force console print routine)
    if msg == '' then return

    else code:consolePrint(msg, (color or '97FFFFFF'), noPrefix) end
end

--* Text Color Routines
function code:cText(color, text)
    if text == '' then return end

    color = (not color or color == '') and 'FFFFFFFF' or color
    return '|c'..color..text..'|r'
end
function code:cPlayer(name, class, color) -- Colorize player names
    if name == '' or ((not class or class == '') and (not color or color == '')) or not name then return end
    local c = (not class or class == '') and color or select(4, GetClassColor(class))

    if c then return code:cText(c, name)
    else return end
end

-- *Tooltip Routine
function code:createTooltip(text, body, force, frame)
    if not force and not ns.gSettings.showToolTips then return end
    local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
    if frame then uiScale, x, y = 0, 0, 0 end
    CreateFrame("GameTooltip", nil, nil, "GameTooltipTemplate")
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR") -- Attaches the tooltip to cursor
    GameTooltip:SetPoint("BOTTOMLEFT", (frame or nil), "BOTTOMLEFT", (uiScale ~= 0 and (x / uiScale) or 0),  (uiScale ~= 0  and (y / uiScale) or 0))
    GameTooltip:SetText(text)
    if body then GameTooltip:AddLine(body,1,1,1) end
    GameTooltip:Show()
end

--* Observer Functions
function observer:Init()
    self.tblObservers = {}
end
function observer:Register(event, callback)
    if not event or not callback then return end

    if not self.tblObservers[event] then self.tblObservers[event] = {} end
    table.insert(self.tblObservers[event], callback)
end
function observer:Unregister(event, callback)
    if not event or not callback then return end
    if not self.tblObservers[event] then return end
    for i=#self.tblObservers[event],1,-1 do
        if self.tblObservers[event][i] == callback then
            table.remove(self.tblObservers[event], i)
        end
    end
end
function observer:UnregisterAll(event)
    if not event then return end
    if not self.tblObservers[event] then return end
    for i=#self.tblObservers[event],1,-1 do
        table.remove(self.tblObservers[event], i)
    end
end
function observer:Notify(event, ...)
    if not event or not self.tblObservers[event] then return end

    for i=1,#self.tblObservers[event] do
        if self.tblObservers[event][i] then
            self.tblObservers[event][i](...) end
    end
end
observer:Init()