-- PaTiCompetition 0.1.0: the probe. Before the dungeon competition (run clock, end screen with damage, damage taken,
-- healing and a score) is built, this finds out what the WoW Forever client really delivers: a source for the
-- numbers (the combat log is reserved for the Blizzard UI here) and the boss fight events.
-- Display only: nothing is cast, targeted or sent.
-- Results stay in PaTiCompetitionDB.probe (SavedVariables) and are shown with /pcomp probe.
local addonName, ns = ...
local UI, L, Logic, Score, Results = ns.UI, ns.UI.L, ns.Logic, ns.Score, ns.Results

local DB
local window = Results.window -- the end screen (Results.lua)
local memberUnits = {} -- { [unit] = name }: player and party (whose threat status is watched)
local threatStatus = {} -- { [unit] = last UnitThreatSituation }, runtime only

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

local function addMember(unit)
    if not UnitExists or not flag(UnitExists(unit)) or not UnitName then return end
    local name = UnitName(unit)
    if name and not isSecret(name) then memberUnits[unit] = name end
end

local function readMembers()
    memberUnits = {}
    addMember("player")
    for index = 1, 4 do addMember("party" .. index) end
end

-- Events ---------------------------------------------------------------------------------------------------------

-- Events that may not exist in this client: RegisterEvent raises an error for unknown names, so each is tried once.
-- Never COMBAT_LOG_EVENT_UNFILTERED: this client reserves it for the Blizzard UI; registering it shows the
-- "blocked" popup (ADDON_ACTION_FORBIDDEN, owner 2026-10-19), which pcall does not prevent.
local OPTIONAL = { "ENCOUNTER_START", "ENCOUNTER_END", "BOSS_KILL", "UNIT_THREAT_SITUATION_UPDATE" }
local registered = {}
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
    "PLAYER_REGEN_DISABLED" }) do
    events:RegisterEvent(event)
end
for _, event in ipairs(OPTIONAL) do registered[event] = pcall(events.RegisterEvent, events, event) end

-- UnitThreatSituation(unit) without an enemy: the highest status against any enemy (nil out of combat).
local function onThreat(unit)
    local name = unit and memberUnits[unit]
    if not name or not UnitThreatSituation then return end
    local ok, status = pcall(UnitThreatSituation, unit)
    if not ok or isSecret(status) then return end
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
    if isSecret(role) then role = nil end
    Logic.RecordThreat(DB.probe, name, role, threatStatus[unit], status)
    threatStatus[unit] = status
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
    -- Blizzard's own damage meter data (Retail 12.0) as a possible source: only whether it exists, nothing is called.
    probe.events.C_DamageMeter = C_DamageMeter ~= nil
    probe.events.issecretvalue = issecretvalue ~= nil
    probe.client = GetBuildInfo and ("%s / %s"):format(tostring((GetBuildInfo())), tostring(select(4, GetBuildInfo())))
        or "?"
end

events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        PaTiCompetitionDB = Logic.Migrate(PaTiCompetitionDB)
        DB = PaTiCompetitionDB
        UI.SetLanguage("auto")
        window:Attach(DB, 0, 80)
        noteClient(DB.probe)
        readMembers()
        return
    end
    if not DB then return end
    if event == "ENCOUNTER_START" or event == "ENCOUNTER_END" or event == "BOSS_KILL" then
        onEncounter(event, ...)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        onThreat(...)
    elseif event == "PLAYER_REGEN_DISABLED" then
        local instance = currentInstance()
        if instance and Logic.StartRun(DB.probe, instance, GetTime()) then say("PROBE_RUN_STARTED", instance) end
    else
        readMembers()
    end
end)

-- End screen ----------------------------------------------------------------------------------------------------

local function unitOf(name)
    for unit, memberName in pairs(memberUnits) do
        if memberName == name then return unit end
    end
end

-- The current run (or, without a run, everything since the last reset). sample: the example values.
local function showResults(sample)
    local rows = sample and Score.Sample() or Logic.Ranking(DB.probe)
    if not sample then
        for _, row in ipairs(rows) do
            row.unit = unitOf(row.name)
            local role = row.unit and UnitGroupRolesAssigned and UnitGroupRolesAssigned(row.unit)
            if role and not isSecret(role) then row.role = role end
        end
    end
    Score.Apply(rows)
    Score.Order(rows)
    local best = Score.Best(rows)
    local run = DB.probe.run
    local subtitle = L.RESULTS_SUBTITLE
    if sample then subtitle = L.RESULTS_SUBTITLE_RUN:format(L.SAMPLE_DUNGEON, "24:13")
    elseif run then
        subtitle = L.RESULTS_SUBTITLE_RUN:format(run.instance, Logic.Clock(Logic.RunTime(DB.probe, GetTime())))
    end
    Results.Show(rows, best, { subtitle = subtitle, sample = sample })
end

window:SetMenu(function()
    if not DB then return {} end
    return {
        { text = window:IsLocked() and "UNLOCK" or "LOCK",
            onClick = function() window:SetLocked(not window:IsLocked()) end },
        { text = "HIDE", onClick = function() window:Hide() end },
    }
end)
-- PaTiSuite "show": the end screen with the current values (an empty window would say nothing).
window.suiteSetShown = function(shown)
    if not DB then return false end
    if shown then showResults(false) else window:Hide() end
end

-- Commands -------------------------------------------------------------------------------------------------------

local function yesNo(value) return value and L.YES or L.NO end

local function printProbe()
    local probe = DB.probe
    say("PROBE_HEADER", tostring(probe.client))
    local seen = probe.events
    say("PROBE_EVENTS", yesNo(seen.C_DamageMeter), yesNo(seen.CombatLogGetCurrentEventInfo),
        yesNo(seen.issecretvalue))
    say("PROBE_BOSS_EVENTS", yesNo(seen.ENCOUNTER_START), yesNo(seen.ENCOUNTER_END), yesNo(seen.BOSS_KILL))
    local log = probe.combatLog
    say("PROBE_LOG", log.total, log.counted, log.secret)
    if probe.run then
        say("PROBE_RUN", probe.run.instance, Logic.Clock(Logic.RunTime(probe, GetTime())))
    end
    for _, row in ipairs(Logic.Ranking(probe)) do
        say("PROBE_PLAYER", row.name, tostring(row.role or "-"), row.done, row.taken, row.heal, row.interrupts,
            row.kills, row.deaths, row.aggro)
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
    elseif command == "show" then showResults(false)
    elseif command == "test" then showResults(true)
    elseif command == "reset" then
        DB.probe = Logic.NewProbe()
        noteClient(DB.probe)
        say("PROBE_RESET")
    elseif command == "version" then say("VERSION", addonVersion())
    else say("HELP"); say("HELP_MORE") end
end
