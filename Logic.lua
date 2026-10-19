-- PaTiChronicle logic: settings, SavedVariables migration, the probe (what this client really delivers) and the
-- clock text. Pure: no WoW calls. Tested in tests/logic_spec.lua. Runs: Run.lua; history and achievements:
-- Chronicle.lua.
local _, ns = ...
local Logic = {}
ns.Logic = Logic

Logic.SCHEMA = 3
Logic.MAX_ENCOUNTERS = 20 -- boss fight events kept by the probe
Logic.SCALES = { 0.8, 0.9, 1, 1.1, 1.25 }
Logic.ROLES = { "AUTO", "TANK", "HEALER", "DAMAGER" } -- myRole: AUTO = the group role the client reports

Logic.DEFAULTS = {
    opacity = 1, -- panel body opacity (PaTiShared window; 0.3–1). The report is a page to read: fully opaque
    groupCategory = "survival", -- tab "Group result": "survival" | "contribution"
    theme = "woforever", -- gold and bronze
    locked = false,
    scale = 1,
    language = "auto",
    showHud = true, -- the run clock line inside a dungeon
    openReport = true, -- open the run report when a run ends
    myRole = "AUTO",
    showMinimap = true, -- the minimap button (owner 2026-10-19)
    minimapAngle = 220, -- degrees around the minimap, 0 = right, counter-clockwise
}

-- The probe answers the open API questions (docs/WOW_API_COMPAT.md, tests T1–T7 in INGAME_TESTING.md).
-- readable / secret: how often a value could be read or came back secret.
function Logic.NewProbe()
    return { events = {}, encounters = {}, fights = 0,
        threat = { readable = 0, secret = 0, party = 0 }, deaths = { readable = 0, secret = 0, seen = 0 } }
end

local function isList(value) return type(value) == "table" end

-- SavedVariables: { schema, settings (DEFAULTS), position, hud (its position), probe, run, report, runs, bests,
-- groupBests, teams, streaks, endBosses, groupCategory }. Runs recorded before schema 3 have no per-member values
-- (they show "n/a"; Run.VERSION). Schema 1 (PaTiCompetition 0.1.0, copied over once by hand): settings
-- and position stay, the old probe (combat log totals) is replaced, the rest starts empty. Broken values are
-- replaced.
function Logic.Migrate(db)
    if type(db) ~= "table" then db = {} end
    local schema = db.schema or 1
    local oldProbe = schema < 2 or not isList(db.probe) or not isList(db.probe.threat)
    if oldProbe then db.probe = Logic.NewProbe() end
    -- Schema 3 (redesign 2026-10-19): the old default opacity 0.75 let the world shine through; it becomes 1 once.
    -- Any other saved value was the player's own choice and stays.
    if schema < 3 and db.opacity == 0.75 then db.opacity = 1 end
    for key, value in pairs(Logic.DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    -- A broken scale would make SetScale fail on login: only a sane number is kept.
    if type(db.scale) ~= "number" or db.scale < 0.5 or db.scale > 2 then db.scale = Logic.DEFAULTS.scale end
    local roleKnown = false
    for _, role in ipairs(Logic.ROLES) do roleKnown = roleKnown or db.myRole == role end
    if not roleKnown then db.myRole = "AUTO" end
    for _, key in ipairs({ "runs", "bests", "groupBests", "teams", "streaks", "endBosses" }) do
        if not isList(db[key]) then db[key] = {} end
    end
    if db.run ~= nil and (not isList(db.run) or db.run.state ~= "running") then db.run = nil end
    if type(db.minimapAngle) ~= "number" or db.minimapAngle ~= db.minimapAngle then
        db.minimapAngle = Logic.DEFAULTS.minimapAngle
    end
    db.minimapAngle = db.minimapAngle % 360
    if db.groupCategory ~= "survival" and db.groupCategory ~= "contribution" then db.groupCategory = "survival" end
    if db.report ~= nil and (not isList(db.report) or not isList(db.report.run)) then db.report = nil end
    db.schema = Logic.SCHEMA
    return db
end

-- "Restore Defaults": the settings back; position, runs, best times and the probe stay.
function Logic.RestoreDefaults(db)
    for key, value in pairs(Logic.DEFAULTS) do db[key] = value end
    return db
end

local function push(list, entry, max)
    list[#list + 1] = entry
    while #list > max do table.remove(list, 1) end
end

-- event: "ENCOUNTER_START" | "ENCOUNTER_END" | "BOSS_KILL"; success only for ENCOUNTER_END (1/true = killed).
function Logic.RecordEncounter(probe, event, id, name, success, instance)
    push(probe.encounters, { event = event, id = id, name = name, success = success, instance = instance },
        Logic.MAX_ENCOUNTERS)
end

-- kind: "threat" | "deaths"; secret: the value came back secret. party: the unit was party1-4 (T1 needs those).
function Logic.RecordRead(probe, kind, secret, party)
    local entry = probe[kind]
    if secret then entry.secret = entry.secret + 1 else entry.readable = entry.readable + 1 end
    if party and kind == "threat" then entry.party = entry.party + 1 end
end

-- Minimap button: the offset from the minimap centre for an angle (degrees) and radius, and back.
function Logic.MinimapOffset(angle, radius)
    local rad = math.rad(angle or Logic.DEFAULTS.minimapAngle)
    return math.cos(rad) * radius, math.sin(rad) * radius
end

function Logic.MinimapAngle(dx, dy)
    return math.deg(math.atan2(dy, dx)) % 360
end

-- 754 → "12:34", 3725 → "1:02:05", nil → "-".
function Logic.Clock(seconds)
    if type(seconds) ~= "number" then return "-" end
    seconds = math.floor(seconds)
    local h, m, s = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60
    if h > 0 then return ("%d:%02d:%02d"):format(h, m, s) end
    return ("%d:%02d"):format(m, s)
end

-- Meter amounts: 950 → "950", 12345 → "12.3k", 2400000 → "2.4M", nil → "-".
function Logic.Amount(value)
    if type(value) ~= "number" then return "-" end
    if value >= 1000000 then return ("%.1fM"):format(value / 1000000) end
    if value >= 1000 then return ("%.1fk"):format(value / 1000) end
    return tostring(math.floor(value + 0.5))
end

-- Signed difference in clock form: -48 → "-0:48", 65 → "+1:05".
function Logic.Delta(seconds)
    return (seconds < 0 and "-" or "+") .. Logic.Clock(math.abs(seconds))
end

return Logic
