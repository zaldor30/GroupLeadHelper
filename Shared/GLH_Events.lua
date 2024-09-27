local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.events, ns.obs = {}, {}
local events, obs = ns.events, ns.obs

--* Event Functions
ns.cleuEvents = {}
local function eventGROUP_ROSTER_UPDATE(refresh)
    local groupType, groupOut = IsInRaid() and 'RAID' or 'PARTY', IsInRaid() and L['RAID'] or L['PARTY']

    ns.roster = {}
    ns.groupInfo = {
        leader = nil,
        assistants = {},
        groupType = groupType,
        groupOut = groupOut,
        roster = {},
    }

    local retry = false
    local function getRoster(try)
        for i=1,GetNumGroupMembers() do
            local rosterRec = { GetRaidRosterInfo(i) }
            if not rosterRec[1] then
                retry = true
                break
            end
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

        if try > 10 then
            ns.code:dOut('Failed to get roster after 10 tries (eventGROUP_ROSTER_UPDATE).')
            return
        elseif retry then C_Timer.After(1, function() getRoster(try + 1) end) end

        obs:Notify('GROUP_ROSTER_UPDATE', refresh)
    end
    getRoster(1)
end
local cleuRunning = false
local function eventCOMBAT_LOG_EVENT_UNFILTERED()
    if cleuRunning then return end

    local _, event = CombatLogGetCurrentEventInfo()
    if not ns.cleuEvents[event] then return end
    cleuRunning = true

    local tblCLEU = { CombatLogGetCurrentEventInfo() }
    C_Timer.After(.2, function()
        obs:Notify('CLEU', tblCLEU)
        cleuRunning = false
    end)
end

local function eventGROUP_LEFT() events:NotInAGroup() end
function events:InAGroup()
    if not IsInGroup() then
        ns.code:dOut('Group Joined, but not in group (events:InAGroup).')
        return
    end

    C_Timer.After(.5, function()
        eventGROUP_ROSTER_UPDATE()

        GLH:UnregisterAllEvents()
        GLH:RegisterEvent('GROUP_LEFT', eventGROUP_LEFT)

        GLH:RegisterEvent('GROUP_ROSTER_UPDATE', function()
            C_Timer.After(.1, eventGROUP_ROSTER_UPDATE)
        end)
        GLH:RegisterEvent('UPDATE_INSTANCE_INFO', function() ns.obs:Notify('UPDATE_INSTANCE_INFO') end)
        GLH:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', eventCOMBAT_LOG_EVENT_UNFILTERED)

        if not ns.base:IsShown() then ns.base:SetShown(true) end
    end)
end
local function eventGROUP_JOINED() events:InAGroup() end
function events:NotInAGroup()
    ns.roster = nil

    obs:Notify('GROUP_LEFT')
    obs:UnregisterAll()

    GLH:UnregisterAllEvents()
    GLH:RegisterEvent('GROUP_JOINED', eventGROUP_JOINED)

    if ns.base:IsShown() then ns.base:SetShown(false) end
end

local lastRefresh = nil
function events:Refresh()
    if lastRefresh and time() - lastRefresh < 1 then return end

    lastRefresh = time()
    ns.code:fOut('Refreshing Group Lead Helper...', ns.GLHColor, true)
    eventGROUP_ROSTER_UPDATE(true)
    C_Timer.After(1, function() ns.code:fOut('Group Lead Helper Refreshed.', ns.GLHColor, true) end)
end
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