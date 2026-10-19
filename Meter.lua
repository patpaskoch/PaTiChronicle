-- PaTiChronicle contribution reader (redesign step 9, owner 2026-10-19): damage, healing, interrupts and dispels per
-- member from WoW's own damage meter (C_DamageMeter). Read only, never reset: ResetAllCombatSessions would empty the
-- player's Blizzard meter. The probe (2026-10-19, Hall of the Thanes) showed every value secret during a fight and
-- readable after it, so this reads only out of combat: after every fight and once more after the run ends.
-- Each session goes into the run as one snapshot (Run.MeterSession). A session that is unreadable now is skipped
-- and read again at the next look, as long as WoW still lists it.
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

-- One session of one kind: { [name] = amount } for the run's members, or nil when it cannot be read completely.
local function readKind(meter, id, kind, members)
    local enum = Enum and Enum.DamageMeterType
    local meterType = enum and enum[TYPES[kind]]
    if meterType == nil then return nil end
    local ok, session = pcall(meter.GetCombatSessionFromID, id, meterType)
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
    return amounts
end

-- Reads every session of the run (never in combat). Sessions from before the run are left out by Run.MeterSession.
function Meter.Read(run)
    local meter = api()
    if not (meter and run and run.meter) or (InCombatLockdown and InCombatLockdown()) then return end
    for id in pairs(Meter.SessionIds() or {}) do
        if not run.meter.before[id] then
            local values, complete = {}, true
            for _, kind in ipairs(Run.METER_KINDS) do
                local amounts = readKind(meter, id, kind, run.members)
                if not amounts then complete = false; break end
                for name, amount in pairs(amounts) do
                    values[name] = values[name] or {}
                    values[name][kind] = amount
                end
            end
            if complete then
                run.data.meter = true
                Run.MeterSession(run, id, values)
            end
        end
    end
end

return Meter
