-- PaTiCompetition 0.1.0: the probe. Before the dungeon competition (run clock, end screen with damage, damage taken,
-- healing and a score) is built, this finds out what the WoW Forever client really delivers: the combat log, its
-- numbers in combat (secret or readable) and the boss fight events. Display only: nothing is cast, targeted or sent.
-- Results stay in PaTiCompetitionDB.probe (SavedVariables) and are shown with /pcomp probe.
local addonName, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic

local DB
local members = {} -- { [guid] = name }: player, party and their pets (a pet counts for its owner)

local function say(key, ...)
    print("|cff68caffPaTiCompetition:|r " .. L[key]:format(...))
end

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end
local function flag(value) return not isSecret(value) and (value == true or value == 1) end

local function addonVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMetadata and getMetadata(addonName, "Version") or "?"
end

-- API adapters ---------------------------------------------------------------------------------------------------

-- "Deadmines (36)" or nil outside an instance. GetInstanceInfo: name, type, …, 8th = instance ID.
local function currentInstance()
    if not (IsInInstance and flag(IsInInstance())) or not GetInstanceInfo then return nil end
    local name, _, _, _, _, _, _, id = GetInstanceInfo()
    if isSecret(name) or isSecret(id) then return nil end
    return ("%s (%s)"):format(tostring(name), tostring(id))
end

local function addMember(unit, ownerUnit)
    if not UnitExists or not flag(UnitExists(unit)) or not UnitGUID or not UnitName then return end
    local guid, name = UnitGUID(unit), UnitName(ownerUnit or unit)
    if guid and name and not isSecret(guid) and not isSecret(name) then members[guid] = name end
end

local function readMembers()
    members = {}
    addMember("player"); addMember("pet", "player")
    for index = 1, 4 do addMember("party" .. index); addMember("partypet" .. index, "party" .. index) end
end

-- Events ---------------------------------------------------------------------------------------------------------

-- Events that may not exist in this client: RegisterEvent raises an error for unknown names, so each is tried once.
local OPTIONAL = { "COMBAT_LOG_EVENT_UNFILTERED", "ENCOUNTER_START", "ENCOUNTER_END", "BOSS_KILL" }
local registered = {}
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UNIT_PET",
    "PLAYER_REGEN_DISABLED" }) do
    events:RegisterEvent(event)
end
for _, event in ipairs(OPTIONAL) do registered[event] = pcall(events.RegisterEvent, events, event) end

local function onCombatLog(...)
    local entry
    if CombatLogGetCurrentEventInfo then entry = Logic.Parse(isSecret, CombatLogGetCurrentEventInfo())
    else entry = Logic.Parse(isSecret, ...) end -- older clients pass the entry as the event's arguments
    Logic.Record(DB.probe, entry, members)
end

local function onEncounter(event, id, name, ...)
    -- ENCOUNTER_END: id, name, difficulty, group size, success. ENCOUNTER_START / BOSS_KILL: no success.
    local success
    if event == "ENCOUNTER_END" then success = (select(3, ...)) end
    if isSecret(id) then id = nil end
    if isSecret(name) then name = nil end
    if isSecret(success) then success = nil end
    Logic.RecordEncounter(DB.probe, event, id, name, success, currentInstance(), GetTime())
    if event == "ENCOUNTER_END" or event == "BOSS_KILL" then
        say("PROBE_ENCOUNTER", tostring(name), tostring(id), Logic.Clock(Logic.RunTime(DB.probe, GetTime())))
    end
end

-- What this client offers, written into the probe at login and after a reset.
local function noteClient(probe)
    for _, name in ipairs(OPTIONAL) do probe.events[name] = registered[name] == true end
    probe.events.CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo ~= nil
    probe.events.issecretvalue = issecretvalue ~= nil
    probe.client = GetBuildInfo and ("%s / %s"):format(tostring((GetBuildInfo())), tostring(select(4, GetBuildInfo())))
        or "?"
end

events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        PaTiCompetitionDB = Logic.Migrate(PaTiCompetitionDB)
        DB = PaTiCompetitionDB
        UI.SetLanguage("auto")
        noteClient(DB.probe)
        readMembers()
        return
    end
    if not DB then return end
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        onCombatLog(...)
    elseif event == "ENCOUNTER_START" or event == "ENCOUNTER_END" or event == "BOSS_KILL" then
        onEncounter(event, ...)
    elseif event == "PLAYER_REGEN_DISABLED" then
        local instance = currentInstance()
        if instance and Logic.StartRun(DB.probe, instance, GetTime()) then say("PROBE_RUN_STARTED", instance) end
    else
        readMembers()
    end
end)

-- Commands -------------------------------------------------------------------------------------------------------

local function yesNo(value) return value and L.YES or L.NO end

local function printProbe()
    local probe = DB.probe
    say("PROBE_HEADER", tostring(probe.client))
    local seen = probe.events
    say("PROBE_EVENTS", yesNo(seen.COMBAT_LOG_EVENT_UNFILTERED), yesNo(seen.CombatLogGetCurrentEventInfo),
        yesNo(seen.issecretvalue))
    say("PROBE_BOSS_EVENTS", yesNo(seen.ENCOUNTER_START), yesNo(seen.ENCOUNTER_END), yesNo(seen.BOSS_KILL))
    local log = probe.combatLog
    say("PROBE_LOG", log.total, log.counted, log.secret)
    if probe.run then
        say("PROBE_RUN", probe.run.instance, Logic.Clock(Logic.RunTime(probe, GetTime())))
    end
    for _, row in ipairs(Logic.Ranking(probe)) do
        say("PROBE_PLAYER", row.name, row.done, row.taken, row.heal, row.deaths)
    end
    for _, fight in ipairs(probe.encounters) do
        say("PROBE_FIGHT", fight.event, tostring(fight.name), tostring(fight.id), tostring(fight.success),
            Logic.Clock(fight.at), tostring(fight.instance))
    end
    local last = probe.deaths[#probe.deaths]
    say("PROBE_DEATHS", #probe.deaths, last and ("%s #%s"):format(tostring(last.name), tostring(last.id)) or "-")
    say("PROBE_SAVED")
end

SLASH_PATICOMPETITION1 = "/paticompetition"
SLASH_PATICOMPETITION2 = "/pcomp"
SlashCmdList.PATICOMPETITION = function(message)
    local command = (message or ""):lower():match("^%s*(%S*)")
    if not DB then return end
    if command == "probe" then printProbe()
    elseif command == "reset" then
        DB.probe = Logic.NewProbe()
        noteClient(DB.probe)
        say("PROBE_RESET")
    elseif command == "version" then say("VERSION", addonVersion())
    else say("HELP") end
end
