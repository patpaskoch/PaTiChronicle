-- PaTiCompetition combat-log parsing, totals, run clock and SavedVariables. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Logic.lua", {}).Logic
end

local SECRET = {} -- stands in for a restricted value
local function isSecret(value) return value == SECRET end

local ME, HEALER, MOB = "Player-1-0001", "Player-1-0002", "Creature-0-1-2-3-639-0000AB"
local MEMBERS = { [ME] = "Pati", [HEALER] = "Heali" }

-- Builds a combat-log entry in the client's order (timestamp, subevent, hideCaster, source…, dest…, suffix…).
local function entry(sub, source, dest, ...)
    return 1, sub, false, source, "src", 0, 0, dest, "Edwin", 0, 0, ...
end

describe("Logic.Parse", function()
    it("reads swing, spell and environmental damage without the overkill part", function()
        local Logic = load()
        assert.equal(100, Logic.Parse(isSecret, entry("SWING_DAMAGE", ME, MOB, 100, -1)).amount)
        assert.equal(70, Logic.Parse(isSecret, entry("SPELL_DAMAGE", ME, MOB, 133, "Fireball", 4, 100, 30)).amount)
        assert.equal(25, Logic.Parse(isSecret, entry("ENVIRONMENTAL_DAMAGE", nil, ME, "Falling", 25)).amount)
    end)

    it("counts only the effective healing (overhealing removed)", function()
        local parsed = load().Parse(isSecret, entry("SPELL_HEAL", HEALER, ME, 2061, "Heal", 2, 500, 120))
        assert.same({ "heal", 380 }, { parsed.kind, parsed.amount })
    end)

    it("ignores subevents it does not count and marks secret values", function()
        local Logic = load()
        assert.is_nil(Logic.Parse(isSecret, entry("SPELL_CAST_START", ME, MOB)))
        assert.is_true(Logic.Parse(isSecret, entry("SPELL_DAMAGE", ME, MOB, 1, "x", 1, SECRET, 0)).secret)
        assert.is_true(Logic.Parse(isSecret, entry("SWING_DAMAGE", SECRET, MOB, 10, 0)).secret)
        assert.is_true(Logic.Parse(isSecret, 1, SECRET).secret)
    end)
end)

describe("Logic.Record", function()
    it("adds damage done, damage taken, healing and deaths per member; NPC deaths keep the NPC ID", function()
        local Logic = load()
        local probe = Logic.NewProbe()
        local function record(...) Logic.Record(probe, Logic.Parse(isSecret, ...), MEMBERS) end
        record(entry("SWING_DAMAGE", ME, MOB, 100, -1))
        record(entry("SPELL_DAMAGE", MOB, ME, 1, "Smash", 1, 40, 0))
        record(entry("SPELL_HEAL", HEALER, ME, 2061, "Heal", 2, 50, 10))
        record(entry("UNIT_DIED", nil, MOB))
        record(entry("UNIT_DIED", nil, HEALER))
        record(entry("SPELL_DAMAGE", ME, MOB, 1, "x", 1, SECRET, 0))
        record(entry("SPELL_CAST_START", ME, MOB))
        record(entry("SPELL_INTERRUPT", ME, MOB, 1766, "Kick", 1, 133, "Fireball", 4))
        record(entry("PARTY_KILL", ME, MOB))
        assert.same({ done = 100, taken = 40, heal = 0, deaths = 0, aggro = 0, interrupts = 1, kills = 1 },
            probe.players.Pati)
        assert.same({ done = 0, taken = 0, heal = 40, deaths = 1, aggro = 0, interrupts = 0, kills = 0 },
            probe.players.Heali)
        assert.same({ { id = 639, name = "Edwin" } }, probe.deaths)
        assert.same({ 9, 7, 1 }, { probe.combatLog.total, probe.combatLog.counted, probe.combatLog.secret })
    end)

    it("keeps only the last MAX_DEATHS enemy deaths", function()
        local Logic = load()
        local probe = Logic.NewProbe()
        for index = 1, Logic.MAX_DEATHS + 5 do
            Logic.Record(probe, { sub = "UNIT_DIED", kind = "death", dest = "Creature-0-1-2-3-" .. index .. "-0" }, {})
        end
        assert.same({ Logic.MAX_DEATHS, 6 }, { #probe.deaths, probe.deaths[1].id })
    end)

    it("ranks members by damage done, then by name", function()
        local Logic = load()
        local probe = Logic.NewProbe()
        probe.players = { B = { done = 5, taken = 0, heal = 0, deaths = 0 }, A = { done = 5, taken = 0, heal = 0,
            deaths = 0 }, C = { done = 9, taken = 0, heal = 0, deaths = 0 } }
        local names = {}
        for _, row in ipairs(Logic.Ranking(probe)) do names[#names + 1] = row.name end
        assert.same({ "C", "A", "B" }, names)
    end)
end)

describe("Logic.RecordThreat", function()
    it("counts pulled aggro when the status rises to 2 or more, keeps the role", function()
        local Logic = load()
        local probe = Logic.NewProbe()
        for _, step in ipairs({ { nil, 0 }, { 0, 3 }, { 3, 2 }, { 2, nil }, { nil, 2 }, { 2, 1 }, { 1, 3 } }) do
            Logic.RecordThreat(probe, "Pati", "DAMAGER", step[1], step[2])
        end
        assert.same({ 3, "DAMAGER" }, { probe.players.Pati.aggro, probe.players.Pati.role })
    end)

    it("reads an older saved entry without aggro", function()
        local Logic = load()
        local probe = Logic.NewProbe()
        probe.players.Old = { done = 1, taken = 0, heal = 0, deaths = 0 }
        assert.equal(0, Logic.Ranking(probe)[1].aggro)
        Logic.RecordThreat(probe, "Old", nil, 0, 3)
        assert.equal(1, probe.players.Old.aggro)
    end)
end)

describe("Logic.NpcId", function()
    it("reads the NPC ID of creatures only", function()
        local Logic = load()
        assert.same({ 639, nil, nil }, { Logic.NpcId(MOB), Logic.NpcId(ME), Logic.NpcId(nil) })
        assert.is_nil(Logic.NpcId("Pet-0-1-2-3-416-0"))
    end)
end)

describe("run clock", function()
    it("starts once per instance and times boss fights from the start", function()
        local Logic = load()
        local probe = Logic.NewProbe()
        assert.is_true(Logic.StartRun(probe, "Deadmines (36)", 100))
        assert.is_false(Logic.StartRun(probe, "Deadmines (36)", 200))
        Logic.RecordEncounter(probe, "ENCOUNTER_END", 1279, "Edwin", 1, "Deadmines (36)", 854)
        assert.same({ 754, "12:34" }, { probe.encounters[1].at, Logic.Clock(probe.encounters[1].at) })
        probe.players.Pati = { done = 5, taken = 0, heal = 0, deaths = 0 }
        assert.is_true(Logic.StartRun(probe, "Wailing Caverns (43)", 900))
        assert.equal(900, probe.run.start)
        assert.is_nil(next(probe.players)) -- a new run starts the totals from zero
    end)

    it("formats hours and missing times", function()
        local Logic = load()
        assert.same({ "1:02:05", "0:09", "-" }, { Logic.Clock(3725), Logic.Clock(9.7), Logic.Clock(nil) })
    end)
end)

describe("Logic.Migrate", function()
    it("creates an empty probe and keeps a saved one", function()
        local Logic = load()
        local db = Logic.Migrate(nil)
        assert.same({ 1, 0 }, { db.schema, db.probe.combatLog.total })
        db.probe.combatLog.total = 12
        assert.equal(12, Logic.Migrate(db).probe.combatLog.total)
        assert.equal(0, Logic.Migrate({ probe = "broken" }).probe.combatLog.total)
    end)
end)
