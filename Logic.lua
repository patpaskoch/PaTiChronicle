-- PaTiChronicle logic: combat-log entries → totals per group member, plus the probe record (what the client
-- really delivers). Pure: no WoW calls, everything comes in as plain values. Tested in tests/logic_spec.lua.
local _, ns = ...
local Logic = {}
ns.Logic = Logic

Logic.SCHEMA = 1
Logic.MAX_DEATHS = 40 -- NPC deaths kept by the probe (to find out the end bosses' NPC IDs)
Logic.MAX_ENCOUNTERS = 20 -- boss fight events kept by the probe

-- Positions in a COMBAT_LOG_EVENT_UNFILTERED entry (CombatLogGetCurrentEventInfo, or the event's own arguments):
-- 1 timestamp, 2 subevent, 3 hideCaster, 4 sourceGUID, 5 sourceName, 6 sourceFlags, 7 sourceRaidFlags,
-- 8 destGUID, 9 destName, 10 destFlags, 11 destRaidFlags, then the suffix: SWING 12 amount, 13 overkill;
-- ENVIRONMENTAL 12 type, 13 amount; SPELL/RANGE 12 spellId, 13 name, 14 school, 15 amount, 16 overkill/overhealing.
local SOURCE_GUID, SOURCE_NAME, DEST_GUID, DEST_NAME = 4, 5, 8, 9
local KINDS = {
    SWING_DAMAGE = { kind = "damage", amount = 12, over = 13 },
    ENVIRONMENTAL_DAMAGE = { kind = "damage", amount = 13 },
    RANGE_DAMAGE = { kind = "damage", amount = 15, over = 16 },
    SPELL_DAMAGE = { kind = "damage", amount = 15, over = 16 },
    SPELL_PERIODIC_DAMAGE = { kind = "damage", amount = 15, over = 16 },
    DAMAGE_SHIELD = { kind = "damage", amount = 15, over = 16 },
    SPELL_HEAL = { kind = "heal", amount = 15, over = 16 },
    SPELL_PERIODIC_HEAL = { kind = "heal", amount = 15, over = 16 },
    SPELL_INTERRUPT = { kind = "interrupt" },
    PARTY_KILL = { kind = "kill" }, -- killing blow: source = who struck it, dest = the victim
    UNIT_DIED = { kind = "death" },
}

-- Amount without the overkill / overhealing part (the client sends -1 or 0 when there is none).
local function effective(amount, over)
    if type(amount) ~= "number" then return nil end
    if type(over) == "number" and over > 0 then amount = amount - over end
    return amount > 0 and amount or 0
end

-- One combat-log entry → { sub, kind, source, sourceName, dest, destName, amount } or nil when it is not
-- one we count. secret = true when a field we need is a restricted (secret) value; such entries are only counted.
function Logic.Parse(isSecret, ...)
    local sub = (select(2, ...))
    if sub == nil or isSecret(sub) then return { secret = true } end
    local spec = KINDS[sub]
    if not spec then return nil end
    local source, dest = (select(SOURCE_GUID, ...)), (select(DEST_GUID, ...))
    local amount = spec.amount and (select(spec.amount, ...)) or nil
    local over = spec.over and (select(spec.over, ...)) or nil
    if isSecret(source) or isSecret(dest) or (amount ~= nil and isSecret(amount))
        or (over ~= nil and isSecret(over)) then
        return { sub = sub, secret = true }
    end
    local sourceName, destName = (select(SOURCE_NAME, ...)), (select(DEST_NAME, ...))
    return { sub = sub, kind = spec.kind, source = source, dest = dest, amount = effective(amount, over),
        sourceName = not isSecret(sourceName) and sourceName or nil,
        destName = not isSecret(destName) and destName or nil }
end

-- "Creature-0-1-2-3-<npcId>-<spawn>" → npcId (number); nil for players, pets of players and anything else.
function Logic.NpcId(guid)
    if type(guid) ~= "string" then return nil end
    local unitType, npcId = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcId)
end

function Logic.NewProbe()
    return { events = {}, combatLog = { total = 0, counted = 0, secret = 0, bySub = {} },
        players = {}, encounters = {}, deaths = {} }
end

local function push(list, entry, max)
    list[#list + 1] = entry
    while #list > max do table.remove(list, 1) end
end

local function player(probe, name)
    local entry = probe.players[name]
    if not entry then
        entry = { done = 0, taken = 0, heal = 0, deaths = 0, aggro = 0, interrupts = 0, kills = 0 }
        probe.players[name] = entry
    end
    return entry
end

-- members: { [guid] = name } — the player, the party and their pets (a pet counts for its owner).
function Logic.Record(probe, entry, members)
    local log = probe.combatLog
    log.total = log.total + 1
    if not entry then return end
    if entry.secret then log.secret = log.secret + 1; return end
    log.counted = log.counted + 1
    log.bySub[entry.sub] = (log.bySub[entry.sub] or 0) + 1
    local from, to = members[entry.source], members[entry.dest]
    if entry.kind == "damage" and entry.amount then
        if from then local p = player(probe, from); p.done = p.done + entry.amount end
        if to then local p = player(probe, to); p.taken = p.taken + entry.amount end
    elseif entry.kind == "heal" and entry.amount then
        if from then local p = player(probe, from); p.heal = p.heal + entry.amount end
    elseif entry.kind == "interrupt" then
        if from then local p = player(probe, from); p.interrupts = (p.interrupts or 0) + 1 end
    elseif entry.kind == "kill" then
        if from and not to then local p = player(probe, from); p.kills = (p.kills or 0) + 1 end
    elseif entry.kind == "death" then
        if to then
            local p = player(probe, to); p.deaths = p.deaths + 1
        elseif Logic.NpcId(entry.dest) then
            push(probe.deaths, { id = Logic.NpcId(entry.dest), name = entry.destName }, Logic.MAX_DEATHS)
        end
    end
end

-- Pulled aggro: a member's threat status (UnitThreatSituation 0-3; 2 and 3 = an enemy attacks them) rises from
-- below 2 to 2 or more. Counted for every role; the score (later) gives minus points except for the tank.
function Logic.RecordThreat(probe, name, role, previous, status)
    if type(status) ~= "number" then return end
    local entry = player(probe, name)
    entry.role = role or entry.role
    if status >= 2 and (type(previous) ~= "number" or previous < 2) then entry.aggro = (entry.aggro or 0) + 1 end
end

-- The run clock: starts with the first fight inside an instance, restarts in another instance. now = GetTime().
-- A new run starts the members' totals from zero (the end screen shows one run).
function Logic.StartRun(probe, instance, now)
    local run = probe.run
    if run and run.instance == instance then return false end
    probe.run = { instance = instance, start = now }
    probe.players = {}
    return true
end

-- Seconds since the run started (nil without a run).
function Logic.RunTime(probe, now)
    return probe.run and now - probe.run.start or nil
end

-- event: "ENCOUNTER_START" | "ENCOUNTER_END" | "BOSS_KILL"; success only for ENCOUNTER_END (1/true = killed).
function Logic.RecordEncounter(probe, event, id, name, success, instance, now)
    push(probe.encounters, { event = event, id = id, name = name, success = success, instance = instance,
        at = Logic.RunTime(probe, now) },
        Logic.MAX_ENCOUNTERS)
end

-- 754 → "12:34", 3725 → "1:02:05", nil → "-".
function Logic.Clock(seconds)
    if type(seconds) ~= "number" then return "-" end
    seconds = math.floor(seconds)
    local h, m, s = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60
    if h > 0 then return ("%d:%02d:%02d"):format(h, m, s) end
    return ("%d:%02d"):format(m, s)
end

-- Members sorted by damage done (largest first), for the chat summary.
function Logic.Ranking(probe)
    local list = {}
    for name, entry in pairs(probe.players) do
        list[#list + 1] = { name = name, done = entry.done, taken = entry.taken, heal = entry.heal,
            deaths = entry.deaths, aggro = entry.aggro or 0, interrupts = entry.interrupts or 0,
            kills = entry.kills or 0, role = entry.role }
    end
    table.sort(list, function(a, b)
        if a.done ~= b.done then return a.done > b.done end
        return a.name < b.name
    end)
    return list
end

Logic.SCALES = { 0.8, 0.9, 1, 1.1, 1.25 }

-- The settings (owner 2026-10-19: "Einstellungen wie die anderen"); like PaTiDungeon's.
Logic.DEFAULTS = {
    opacity = 0.75, -- panel body opacity (PaTiShared window; 0.3–1)
    theme = "woforever", -- gold and bronze, like the owner's end screen design
    locked = false,
    scale = 1,
    language = "auto",
}

-- SavedVariables: { schema, probe, settings (DEFAULTS), window position }. Unknown or broken values are replaced;
-- a saved probe is kept. Schema 1 stays: the settings are only new keys with defaults.
function Logic.Migrate(db)
    if type(db) ~= "table" then db = {} end
    if type(db.probe) ~= "table" or type(db.probe.combatLog) ~= "table" then db.probe = Logic.NewProbe() end
    for key, value in pairs(Logic.DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    -- A broken scale would make SetScale fail on login: only a sane number is kept.
    if type(db.scale) ~= "number" or db.scale < 0.5 or db.scale > 2 then db.scale = Logic.DEFAULTS.scale end
    db.schema = Logic.SCHEMA
    return db
end

-- "Restore Defaults": the settings back; position and the test results stay.
function Logic.RestoreDefaults(db)
    for key, value in pairs(Logic.DEFAULTS) do db[key] = value end
    return db
end

return Logic
