local _, ns = ... -- Namespace (myaddon, namespace)

ns.code = {}
local code = ns.code

--* Console print routines
function code:consolePrint(msg, color, noPrefix)
    if msg == '' or not msg then return end

    local prefix = not noPrefix and self:cText(ns.GLHColor, 'GLH: ') or ''

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
    if name == '' or ((not class or class == '') and (not color or color == '')) or not name then return name end
    local c = (not class or class == '') and color or select(4, GetClassColor(class))

    if c then return code:cText(c, name)
    else return end
end

--* Local Wordwrap
function code:wordWrap(inputString, maxLineLength)
    local lines = {}
    local currentLine = ""

    maxLineLength = maxLineLength or 50
    for word in inputString:gmatch("%S+") do
        if #currentLine + #word <= maxLineLength then
            currentLine = currentLine .. " " .. word
        else
            table.insert(lines, currentLine)
            currentLine = word
        end
    end

    table.insert(lines, currentLine)
    return table.concat(lines, "\n")
end

-- *Tooltip Routine
function code:createTooltip(text, body, force, frame)
    if not force and not ns.g.showTooltips then return end
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

--* GROUP_ROSTER_UPDATE Routines
function code:GetGroupRoles()
    if not ns.roster or not ns.groupInfo.groupType then return end

    local tank, healer, dps, unknown, tblTanks, tblHealers = 0, 0, 0, 0, {}, {}

    for k, r in pairs(ns.roster) do
        local role = UnitGroupRolesAssigned(k)

        if role == 'TANK' then
            tank = tank + 1
            tinsert(tblTanks, r)
        elseif role == 'HEALER' then
            healer = healer + 1
            tinsert(tblHealers, r)
        elseif role == 'DAMAGER' then dps = dps + 1
        else unknown = unknown + 1 end
    end

    return tank, healer, dps, unknown, tblTanks, tblHealers
end

--* Data Routines
function code:sortTableByField(tbl, sortField, reverse, showit)
    if not tbl then return end

    local keyArray = {}
    for key, rec in pairs(tbl) do
        if type(key) == 'string' then
            if sortField then rec.key = key
            elseif not sortField then rec = key end

            table.insert(keyArray, rec and rec or tbl[key])
        end
    end

    local sortFunc = nil
    reverse = reverse or false
    if not sortField then
        sortFunc = function(a, b)
            if reverse then return a < b
            else return a > b end
        end
    else
        sortFunc = function(a, b)
            if a[sortField] and b[sortField] then
                if reverse then return a[sortField] > b[sortField]
                else return a[sortField] < b[sortField] end
            end
        end
    end

    table.sort(keyArray, sortFunc)
    return keyArray
end
function code:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[code:DeepCopy(orig_key)] = code:DeepCopy(orig_value)
        end
    else -- Non-table types are copied by value
        copy = orig
    end
    return copy
end