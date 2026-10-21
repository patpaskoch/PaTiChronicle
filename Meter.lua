-- PaTiChronicle contribution reader (redesign step 9, owner 2026-10-19): damage, healing, interrupts and dispels per
-- member from WoW's own damage meter (C_DamageMeter). Read only, never reset: ResetAllCombatSessions would empty the
-- player's Blizzard meter. The probe (2026-10-19, Hall of the Thanes) showed every value secret during a fight and
-- readable after it, so this reads only out of combat: after every fight and once more after the run ends.
-- Each session goes into the run as one snapshot (Run.MeterSession). A session that is unreadable now is skipped
-- and read again at the next look, as long as WoW still lists it.
-- Owner run 2026-10-20 (reported 2026-10-21): every session read by its ID came back without a single member, while the probe's read by
-- type (Current) right after combat saw the players. So the newest session is also read by type after each fight,
-- and run.meter.diag keeps what each way returned (for the next look into the SavedVariables).
local _, ns = ...
local Run = ns.Run
local Meter = {}
ns.Meter = Meter

-- Run.METER_KINDS → the names in Enum.DamageMeterType (probe: Interrupts, Dispels, DamageDone, HealingDone, …).
local TYPES = { damage = "DamageDone", healing = "HealingDone", interrupts = "Interrupts", dispels = "Dispels" }

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end

local function api()
    if type(C_DamageMeter) == "table" and type(C_DamageMeter.GetCombatSessionFromID) == "function"
        and type(C_DamageMeter.GetAvailableCombatSessions) == "function" then
        return C_DamageMeter
    end
end

function Meter.Available() return api() ~= nil end

-- The IDs of the sessions WoW lists now, as a set; nil when they cannot be read.
function Meter.SessionIds()
    local meter = api()
    if not meter then return nil end
    local ok, list = pcall(meter.GetAvailableCombatSessions)
    if not ok or type(list) ~= "table" or isSecret(list) then return nil end
    local ids = {}
    for _, session in ipairs(list) do
        local id = type(session) == "table" and session.sessionID
        if type(id) == "number" and not isSecret(id) then ids[id] = true end
    end
    return ids
end

-- One session of one kind through fetch(meterType): { [name] = amount } for the run's members and the number of
-- sources WoW returned, or nil when it cannot be read completely.
local function readKind(fetch, kind, members)
    local enum = Enum and Enum.DamageMeterType
    local meterType = enum and enum[TYPES[kind]]
    if meterType == nil then return nil end
    local ok, session = pcall(fetch, meterType)
    if not ok or type(session) ~= "table" or isSecret(session) then return nil end
    local sources = session.combatSources
    if type(sources) ~= "table" or isSecret(sources) then return nil end
    local amounts = {}
    for _, source in ipairs(sources) do
        local name, amount = source.name, source.totalAmount
        if isSecret(name) or isSecret(amount) then return nil end
        if type(name) == "string" and type(amount) == "number" then
            local short = name:match("^[^%-]+") or name -- "Name-Realm" → "Name", as the run keeps members
            if members[short] then amounts[short] = (amounts[short] or 0) + amount end
        end
    end
    return amounts, #sources
end

-- All kinds of one session: { [name] = { damage = n, … } } and the sources of the first kind; nil when incomplete.
local function readSession(fetch, members)
    local values, sources = {}, nil
    for _, kind in ipairs(Run.METER_KINDS) do
        local amounts, count = readKind(fetch, kind, members)
        if not amounts then return nil end
        sources = sources or count
        for name, amount in pairs(amounts) do
            values[name] = values[name] or {}
            values[name][kind] = amount
        end
    end
    return values, sources
end

local function store(run, id, values)
    if values and Run.MeterSession(run, id, values) then run.data.meter = true end
end

-- Reads every session of the run (never in combat). Sessions from before the run are left out by Run.MeterSession.
-- afterFight: called right after combat, when type Current is the fight that just ended.
function Meter.Read(run, afterFight)
    local meter = api()
    if not (meter and run and run.meter) or (InCombatLockdown and InCombatLockdown()) then return end
    local ids, newest, byId = Meter.SessionIds() or {}, nil, nil
    for id in pairs(ids) do
        if not run.meter.before[id] and (not newest or id > newest) then newest = id end
    end
    for id in pairs(ids) do
        if not run.meter.before[id] then
            local values, sources = readSession(function(meterType)
                return meter.GetCombatSessionFromID(id, meterType)
            end, run.members)
            if id == newest then byId = sources end
            store(run, id, values)
        end
    end
    local types = Enum and Enum.DamageMeterSessionType
    local current = types and types.Current
    if not (afterFight and newest and current ~= nil and type(meter.GetCombatSessionFromType) == "function") then
        return
    end
    local values, sources = readSession(function(meterType)
        return meter.GetCombatSessionFromType(current, meterType)
    end, run.members)
    if not run.meter.sessions[newest] then store(run, newest, values) end
    run.meter.diag = ("newest %d: by id %s sources, current %s sources, stored %s"):format(newest,
        tostring(byId), tostring(sources), run.meter.sessions[newest] and "yes" or "no")
end

return Meter
