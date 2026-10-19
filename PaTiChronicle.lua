-- PaTiChronicle — Every run tells a story. A chronicle of your dungeon runs: run clock, run report (overview, my
-- performance, timeline), best times, run history and achievements for teamplay, survival and personal bests.
-- We play together against our own earlier runs, not against each other. Display only: nothing is cast, targeted
-- or sent. This file: API adapters, events, runs. Rules: Run.lua, Chronicle.lua; UI: Report*.lua, Hud.lua;
-- settings and commands: Settings.lua.
local addonName, ns = ...
local UI, L, Logic, Run, Chronicle = ns.UI, ns.UI.L, ns.Logic, ns.Run, ns.Chronicle
local Report, Hud, Sample, Probe = ns.Report, ns.Hud, ns.Sample, ns.Probe

local DB
local window = Report.window
local memberUnits = {} -- { [unit] = name }: player and party1-4
local testMode = false -- runtime only: the report shows the example run
local meterInCombat = false -- probe: look at C_DamageMeter once during the next fight (test T6c)

local function say(key, ...)
    print("|cff68caffPaTiChronicle:|r " .. L[key]:format(...))
end

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end
local function readable(value) if not isSecret(value) then return value end end
local function flag(value) return not isSecret(value) and (value == true or value == 1) end

local function addonVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMetadata and getMetadata(addonName, "Version") or "?"
end

-- API adapters ---------------------------------------------------------------------------------------------------

-- A 5-player dungeon: { key, name }, else nil. GetInstanceInfo: name, type, …, 8th = instance ID.
local function currentInstance()
    if not (IsInInstance and flag(IsInInstance())) or not GetInstanceInfo then return nil end
    local name, instanceType, _, _, _, _, _, id = GetInstanceInfo()
    name, instanceType, id = readable(name), readable(instanceType), readable(id)
    if instanceType ~= "party" or type(name) ~= "string" then return nil end
    return { key = tostring(id or name), name = name }
end

local function readMembers()
    memberUnits = {}
    for _, unit in ipairs({ "player", "party1", "party2", "party3", "party4" }) do
        if UnitExists and flag(UnitExists(unit)) and UnitName then
            local name = readable(UnitName(unit))
            if type(name) == "string" then memberUnits[unit] = name end
        end
    end
end

local function myRole()
    if DB.myRole ~= "AUTO" then return DB.myRole end
    local role = UnitGroupRolesAssigned and readable(UnitGroupRolesAssigned("player"))
    if role == "TANK" or role == "HEALER" or role == "DAMAGER" then return role end
    return "NONE"
end

local function roleOf(unit)
    if unit == "player" then return myRole() end
    local role = UnitGroupRolesAssigned and readable(UnitGroupRolesAssigned(unit))
    if role == "TANK" or role == "HEALER" or role == "DAMAGER" then return role end
    return "NONE"
end

local function memberInfo(unit, name)
    local info = { name = name, role = roleOf(unit) }
    local level = UnitLevel and readable(UnitLevel(unit))
    if type(level) == "number" and level > 0 then info.level = level end
    if UnitClass then
        local className, classFile = UnitClass(unit)
        info.className = type(readable(className)) == "string" and className or nil
        info.classFile = type(readable(classFile)) == "string" and classFile or nil
    end
    return info
end

-- The tank: you (your role setting) or the member with the TANK role. nil = nobody known.
local function tankName()
    for unit, name in pairs(memberUnits) do
        if roleOf(unit) == "TANK" then return name end
    end
end

local function groupNames()
    local names = {}
    for _, name in pairs(memberUnits) do names[#names + 1] = name end
    table.sort(names)
    return names
end

local function noteMembers(run)
    for unit, name in pairs(memberUnits) do Run.AddMember(run, memberInfo(unit, name)) end
    run.tank = tankName() or run.tank
    Run.Presence(run, groupNames(), time())
end

-- Runs -----------------------------------------------------------------------------------------------------------

local refresh -- defined below (HUD)

-- The order on the report: tank, healer, damage, then names; only members still in the group.
local ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3 }
local function lineup(run, names)
    local list = {}
    for _, name in ipairs(names) do list[#list + 1] = name end
    table.sort(list, function(a, b)
        local ra = ROLE_ORDER[(run.members[a] or {}).role] or 4
        local rb = ROLE_ORDER[(run.members[b] or {}).role] or 4
        if ra ~= rb then return ra < rb end
        return a < b
    end)
    return list
end

local function units()
    local map = {}
    for unit, name in pairs(memberUnits) do map[name] = unit end
    return map
end

local function runNumber(key, role)
    local count = 0
    for _, entry in ipairs(DB.runs[key] or {}) do
        if entry.role == role then count = count + 1 end
    end
    return count
end

local function showReport(report, tab)
    report.units = units()
    report.models = DB.probe.model == "ok" -- 3D characters only where the probe saw PlayerModel:SetUnit work
    Report.Show(report, tab)
end

-- how: "auto" (the learned end boss) or "manual" (your click).
local function finishRun(how)
    local run = DB.run
    if not run then return end
    local now = time()
    noteMembers(run)
    if how == "manual" and Chronicle.LearnEndBoss(DB, run, now) then say("END_BOSS_LEARNED", run.name) end
    Run.Finish(run, now, how, GetTime())
    local names = groupNames()
    local result = Chronicle.Evaluate(DB, run, #names, names)
    Chronicle.Store(DB, run, result.summary)
    DB.run = nil
    DB.report = { run = run, result = result, size = #names, names = lineup(run, names),
        best = Chronicle.BestTime(DB, run.key), runNumber = runNumber(run.key, run.myRole) }
    say("RUN_COMPLETED", run.name, Logic.Clock(result.summary.time))
    if DB.openReport then testMode = false; showReport(DB.report, "overview") end
    refresh()
end

-- Aborted runs are not saved in the history and give no achievements; their timeline stays viewable.
local function abortRun(reason)
    local run = DB.run
    if not run then return end
    Run.Abort(run, time(), reason)
    local names = groupNames()
    local result = Chronicle.Evaluate(DB, run, #names, names)
    result.group, result.mine, result.missing = {}, {}, {}
    DB.run = nil
    DB.report = { run = run, result = result, size = #names, names = lineup(run, names),
        best = Chronicle.BestTime(DB, run.key), runNumber = runNumber(run.key, run.myRole) + 1 }
    say("RUN_ABORTED", run.name, L["ABORT_" .. reason:upper()] or reason)
    refresh()
end

-- The running run as a report (achievements only at the end).
local function liveReport()
    local run = DB.run
    run.now = time()
    local names = groupNames()
    local result = Chronicle.Evaluate(DB, run, #names, names)
    result.group, result.mine, result.missing = {}, {}, {}
    return { run = run, result = result, size = #names, names = lineup(run, names),
        best = Chronicle.BestTime(DB, run.key), runNumber = runNumber(run.key, run.myRole) + 1 }
end

local function currentReport()
    if testMode then
        local sample = Sample.Report(L.SAMPLE_DUNGEON)
        sample.runNumber, sample.best = 5, 1453
        return sample
    end
    if DB.run then return liveReport() end
    return DB.report
end

local function setShown(shown) -- no secure frames: fine in combat
    if not shown then window:Hide(); return true end
    local report = currentReport()
    if not report then Report.ShowEmpty(); return true end
    showReport(report)
    return true
end

-- The HUD line: inside a 5-player dungeon (and switched on), with the running or the last run of this dungeon.
refresh = function()
    local instance = DB and DB.showHud and currentInstance()
    if not instance then Hud.Update(nil); return end
    local run = DB.run
    local last = DB.report and DB.report.run
    if not run and last and last.key == instance.key and last.state == "completed" then run = last end
    Hud.Update({ name = instance.name, run = run, best = Chronicle.BestTime(DB, instance.key),
        open = function() setShown(not window:IsShown()) end, menu = function()
        local items = {}
        if DB.run then
            items[#items + 1] = { text = "END_RUN", onClick = function() finishRun("manual") end }
            items[#items + 1] = { text = "ABORT_RUN", onClick = function() abortRun("click") end }
        end
        items[#items + 1] = { text = "OPEN_REPORT", onClick = function() setShown(true) end }
        items[#items + 1] = { text = "HIDE_HUD", onClick = function() DB.showHud = false; refresh() end }
        return items
    end })
end

-- Events ---------------------------------------------------------------------------------------------------------

-- Optional events: RegisterEvent raises an error for unknown names, so each is tried once. Never
-- COMBAT_LOG_EVENT_UNFILTERED: this client reserves it for the Blizzard UI (forbidden popup, 2026-10-19).
local OPTIONAL = { "ENCOUNTER_START", "ENCOUNTER_END", "BOSS_KILL", "UNIT_THREAT_SITUATION_UPDATE" }
local registered = {}
local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_LOGOUT", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
    "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UNIT_HEALTH", "PLAYER_DEAD",
    "PLAYER_UNGHOST", "PLAYER_ALIVE" }) do
    events:RegisterEvent(event)
end
for _, event in ipairs(OPTIONAL) do registered[event] = pcall(events.RegisterEvent, events, event) end

-- What this client offers (the probe, /pchron probe).
local function noteClient(probe)
    for _, name in ipairs(OPTIONAL) do probe.events[name] = registered[name] == true end
    probe.events.C_DamageMeter = C_DamageMeter ~= nil
    probe.damageMeter = nil
    if type(C_DamageMeter) == "table" then
        local names = {}
        for key in pairs(C_DamageMeter) do names[#names + 1] = tostring(key) end
        table.sort(names)
        probe.damageMeter = table.concat(names, ", ") -- only the function names; nothing is called (test T6)
    end
    Probe.Client(probe)
    probe.client = GetBuildInfo and ("%s / %s"):format(tostring((GetBuildInfo())), tostring(select(4, GetBuildInfo())))
        or "?"
end

local function deathCheck(unit)
    local run, name = DB.run, memberUnits[unit]
    if not run or not name or not UnitIsDeadOrGhost then return end
    local dead = UnitIsDeadOrGhost(unit)
    Logic.RecordRead(DB.probe, "deaths", isSecret(dead))
    if isSecret(dead) then Run.DeathState(run, name, nil, false, time()); return end
    local allDead = true
    for other in pairs(memberUnits) do
        local value = UnitIsDeadOrGhost(other)
        if isSecret(value) or not value then allDead = false end
    end
    Run.DeathState(run, name, dead and true or false, allDead, time())
end

local function onThreat(unit)
    local run, name = DB.run, unit and memberUnits[unit]
    if not run or not name or not UnitThreatSituation then return end
    local ok, status = pcall(UnitThreatSituation, unit)
    if not ok then return end
    Logic.RecordRead(DB.probe, "threat", isSecret(status), unit ~= "player")
    if meterInCombat and InCombatLockdown and InCombatLockdown() then
        meterInCombat = false
        Probe.DamageMeter(DB.probe, true)
    end
    if isSecret(status) then Run.Threat(run, name, nil, false, false, GetTime(), time()); return end
    local tank, mine = run.tank, unit == "player"
    -- Without a known tank the others' moments cannot be told apart from tanking: only yours count then.
    if not tank and not mine then return end
    Run.Threat(run, name, type(status) == "number" and status or 0, name == tank, mine, GetTime(), time())
end

local function onEncounter(event, id, name, ...)
    id, name = readable(id), readable(name)
    local success
    if event == "ENCOUNTER_END" then success = flag((select(3, ...))) end
    if event == "BOSS_KILL" then success = true end
    local instance = currentInstance()
    Logic.RecordEncounter(DB.probe, event, id, name, success, instance and instance.name)
    local run = DB.run
    if not run then return end
    if event == "ENCOUNTER_START" then Run.BossStart(run); return end
    if event == "BOSS_KILL" and registered.ENCOUNTER_END then return end -- the same kill, already counted
    Run.BossEnd(run, time(), name, success, id)
    if success and id and DB.endBosses[run.key] == id then finishRun("auto") end
end

-- Zone changes: back in the run's dungeon, left it (as a ghost or not), or another dungeon.
local function onLocation()
    local run, instance, now = DB.run, currentInstance(), time()
    if run then
        if instance then
            local resumed, reason = Run.Resume(run, instance, now)
            if not resumed and reason then abortRun(reason) end
        elseif not Run.StillWaiting(run, now) then
            abortRun("left")
        elseif not run.leftAt then
            Run.Leave(run, now, UnitIsGhost and flag(UnitIsGhost("player")))
        end
    end
    refresh()
end

local function onFightStart()
    local instance = currentInstance()
    if not instance then return end
    local now = time()
    if not DB.run then
        DB.run = Run.New(instance, now, { name = memberUnits.player or "?", role = myRole() })
        say("RUN_STARTED", instance.name)
    end
    DB.probe.fights = DB.probe.fights + 1
    meterInCombat = true
    noteMembers(DB.run)
    Run.FightStart(DB.run, now)
    for unit in pairs(memberUnits) do deathCheck(unit) end
    refresh()
end

events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        PaTiChronicleDB = Logic.Migrate(PaTiChronicleDB)
        DB = PaTiChronicleDB
        UI.SetLanguage(DB.language)
        window:Attach(DB, 0, 60)
        window:SetScale(DB.scale)
        Hud.Attach(DB)
        noteClient(DB.probe)
        readMembers()
        if DB.run and not Run.Login(DB.run, time()) then abortRun("logout") end
        if ns.OnLogin then ns.OnLogin() end -- Settings.lua: minimap button
        return
    end
    if not DB then return end
    if event == "UNIT_HEALTH" then
        local unit = ...
        if memberUnits[unit] then deathCheck(unit) end
    elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
        deathCheck("player")
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" then
        onThreat(...)
    elseif event == "ENCOUNTER_START" or event == "ENCOUNTER_END" or event == "BOSS_KILL" then
        onEncounter(event, ...)
    elseif event == "PLAYER_REGEN_DISABLED" then
        onFightStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if DB.run then
            Run.FightEnd(DB.run, time(), GetTime())
            Probe.DamageMeter(DB.probe, false)
        end
    elseif event == "PLAYER_LOGOUT" then
        if DB.run then Run.Logout(DB.run, time()) end
    elseif event == "GROUP_ROSTER_UPDATE" then
        readMembers()
        if DB.run then noteMembers(DB.run) end
    else -- PLAYER_ENTERING_WORLD, ZONE_CHANGED_NEW_AREA
        readMembers()
        onLocation()
    end
end)

ns.Commands = { -- for Settings.lua
    say = say, setShown = setShown, refresh = refresh, finishRun = finishRun, abortRun = abortRun,
    toggleTest = function()
        testMode = not testMode
        if testMode or window:IsShown() then setShown(true) end
    end,
    isTest = function() return testMode end,
    db = function() return DB end,
    noteClient = noteClient,
    version = addonVersion,
}
Report.onSample = ns.Commands.toggleTest
UI.OnLanguageChanged(Report.Refresh)
