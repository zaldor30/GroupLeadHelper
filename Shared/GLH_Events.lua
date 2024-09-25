local _, ns = ... -- Namespace (myaddon, namespace)
local L = LibStub("AceLocale-3.0"):GetLocale('GroupLeadHelper')

ns.events, ns.obs = {}, {}
local events, obs = ns.events, ns.obs

--* Event Functions
local function eventGROUP_ROSTER_UPDATE()
    local groupType, groupOut = IsInRaid() and 'RAID' or 'PARTY', IsInRaid() and L['RAID'] or L['PARTY']

    ns.GroupRoster = {
        leader = nil,
        assistants = {},
        groupType = groupType,
        groupOut = groupOut,
        roster = {},
    }
    local GroupRoster = ns.GroupRoster

    for i=1,GetNumGroupMembers() do
        local rosterRec = { GetRaidRosterInfo(i) }
        GroupRoster.roster[rosterRec[1]] = {
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
        if GroupRoster.rank == 2 then ns.GroupRoster.leader = { GroupRoster.name, class }
        elseif GroupRoster.rank == 1 then table.insert(GroupRoster.assistants, { GroupRoster.name, class }) end
    end

    obs:Notify('GROUP_ROSTER_UPDATE')
end
local function eventCOMBAT_LOG_EVENT_UNFILTERED()
end

local function eventGROUP_LEFT() events:NotInAGroup() end
function events:InAGroup()
    if not IsInGroup() then
        ns.code:dOut('Group Joined, but not in group (events:InAGroup).')
        return
    end

    eventGROUP_ROSTER_UPDATE()

    GLH:UnregisterAllEvents()
    GLH:RegisterEvent('GROUP_LEFT', eventGROUP_LEFT)

    GLH:RegisterEvent('GROUP_ROSTER_UPDATE', eventGROUP_ROSTER_UPDATE)
    GLH:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', eventCOMBAT_LOG_EVENT_UNFILTERED)

    if not ns.base:IsShown() then ns.base:SetShown(true) end
end
local function eventGROUP_JOINED() events:InAGroup() end
function events:NotInAGroup()
    ns.GroupRoster = nil

    obs:Notify('GROUP_LEFT')
    obs:UnregisterAll()

    GLH:UnregisterAllEvents()
    GLH:RegisterEvent('GROUP_JOINED', eventGROUP_JOINED)
end

local lastRefresh = nil
function events:Refresh()
    if lastRefresh and time() - lastRefresh < 1 then return end

    lastRefresh = time()
    ns.code:fOut('Refreshing Group Lead Helper...', ns.GLHColor, true)
    eventGROUP_ROSTER_UPDATE()
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