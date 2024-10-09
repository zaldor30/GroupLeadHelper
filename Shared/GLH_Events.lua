local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.events, ns.obs = {}, {}
local events, obs = ns.events, ns.obs

local function eventsGROUP_LEFT() events:GroupStatusChanged() end
local function eventsGROUP_JOINED() events:GroupStatusChanged() end
local function eventsGROUP_ROSTER_UPDATE() events:GroupRosterUpdated() end
local function eventsPLAYER_DIFFICULTY_CHANGED()
    if (IsInGroup() and not IsInRaid() and GetDungeonDifficultyID() == 208) or events.isInDelve then events:InADelve()
    else obs:Notify('PLAYER_DIFFICULTY_CHANGED') end
end

--* Event Functions
function events:Init()
    ns.groupType = 'STARTUP'

    self.isEnabled = false
    self.isInDelve = false
    self.currentDifficulty = nil
end
local leftDelveMessage = 'Exited delve, Group Lead Helper is |cFF00FF00enabled|r.'
function events:InADelve()
    local inDelve = (GetDungeonDifficultyID() == 208) or false

    if inDelve and inDelve ~= self.isInDelve then
        self.isInDelve = inDelve
        GLH:UnregisterAllEvents()
        GLH:RegisterEvent('GROUP_LEFT', eventsGROUP_LEFT)
        GLH:RegisterEvent('PLAYER_DIFFICULTY_CHANGED', eventsPLAYER_DIFFICULTY_CHANGED)
        ns.code:fOut('Group Lead Helper is |cFFFF0000disabled|r during delves.', ns.GLHColor, true)

        --ns.base:SetShown(false)
    elseif not inDelve and inDelve ~= self.isInDelve then
        self.isInDelve = inDelve
        ns.code:fOut(leftDelveMessage, ns.GLHColor, true)

        self:GroupStatusChanged()
    end
end
function events:GroupRosterUpdated(refresh, skipDelveCheck, retryCounter)
    if ns.roster and self.currentDifficulty ~= GetDungeonDifficultyID() then return end

    retryCounter = retryCounter or 1

    ns.groupType = IsInRaid() and 'RAID' or 'PARTY'
    ns.groupTypeOut = IsInRaid() and L['RAID'] or L['PARTY']

    ns.roster = {}
    ns.groupInfo = {
        leader = nil,
        assistants = {},
        groupType = ns.groupType,
        groupOut = ns.groupTypeOut,
    }

    local retry = false
    for i=1, GetNumGroupMembers() do
        local rosterRec = { GetRaidRosterInfo(i) }
        if not rosterRec[1] then retry = true break end

        ns.roster[rosterRec[1]] = {
            name = rosterRec[1],
            rank = rosterRec[2],
            subParty = rosterRec[3],
            level = rosterRec[4],
            class = rosterRec[5],
            classFile = rosterRec[6],
            zone = rosterRec[7],
            isOnline = rosterRec[8],
            isDead = rosterRec[9],
        }

        if rosterRec[2] == 2 then ns.groupInfo.leader = { rosterRec[1], rosterRec[6] }
        elseif rosterRec[2] == 1 then table.insert(ns.groupInfo.assistants, { rosterRec[1], rosterRec[6] }) end
    end

    if retry and retryCounter > 15 then return
    elseif retry then
        C_Timer.After(.5, function() events:GroupRosterUpdated(refresh, skipDelveCheck, retryCounter+1) end)
    else obs:Notify('GROUP_ROSTER_UPDATE', refresh) end
end
local groupTimer = nil
function events:NoGroup()
    GLH:UnregisterAllEvents()
    GLH:RegisterEvent('GROUP_JOINED', eventsGROUP_JOINED)

    ns.groupType, ns.roster, ns.groupInfo, self.isInDelve = nil, nil, nil, false
    obs:Notify('GROUP_LEFT')
end
function events:GroupActive()
    if groupTimer then
        GLH:CancelTimer(groupTimer)
        groupTimer = nil
    end

    GLH:UnregisterAllEvents()
    GLH:RegisterEvent('GROUP_LEFT', eventsGROUP_LEFT)
    GLH:RegisterEvent('GROUP_ROSTER_UPDATE', eventsGROUP_ROSTER_UPDATE)
    GLH:RegisterEvent('PLAYER_DIFFICULTY_CHANGED', eventsPLAYER_DIFFICULTY_CHANGED)

    self:GroupRosterUpdated('DO_REFRESH', 'SKIP_DELVE_CHECK')
    obs:Notify('GROUP_JOINED')
end
function events:GroupStatusChanged(retryCount)
    if IsInGroup() and GetDungeonDifficultyID() == 208 then self:InADelve()
    elseif retryCount and retryCount > 600 then events:NoGroup() -- Retry every .1s for 60s
    elseif IsInGroup() and GetNumGroupMembers() <= 1 then
        groupTimer = GLH:ScheduleTimer(function() self:GroupStatusChanged((retryCount or 1)+1) end, .1)
    elseif (ns.groupType == 'STARTUP' or not ns.groupType) and IsInGroup() and GetNumGroupMembers() > 1 then
        events:GroupActive()
    elseif ns.groupType and not IsInGroup() then
        if self.isInDelve then
            self.isInDelve = false
            ns.code:fOut(leftDelveMessage, ns.GLHColor, true)
        end
        events:NoGroup()
    end
end
events:Init()
--? End of Event Functions

--* notify Functions
local tblNotify = {}
function obs:Register(event, callback)
    if not event or not callback then return end

    if not tblNotify[event] then tblNotify[event] = {} end
    table.insert(tblNotify[event], callback)
end
function obs:Unregister(event, callback)
    if not event or not callback then return end
    if not tblNotify[event] then return end
    for i=#tblNotify[event],1,-1 do
        if tblNotify[event][i] == callback then
            table.remove(tblNotify[event], i)
        end
    end
end
function obs:UnregisterAll(event)
    if not event then return end
    if not tblNotify[event] then return end
    for i=#tblNotify[event],1,-1 do
        table.remove(tblNotify[event], i)
    end
end
function obs:Notify(event, ...)
    if not event or not tblNotify[event] then return end

    for i=1,#tblNotify[event] do
        if tblNotify[event][i] then
            tblNotify[event][i](...) end
    end
end