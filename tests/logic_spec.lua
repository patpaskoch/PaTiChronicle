-- PaTiChronicle settings, SavedVariables migration, probe and clock text. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Logic.lua", {}).Logic
end

describe("Logic.Migrate", function()
    it("starts an empty schema 3 save with the default settings", function()
        local db = load().Migrate(nil)
        assert.same({ 3, "woforever", true, true, "AUTO" },
            { db.schema, db.theme, db.showHud, db.openReport, db.myRole })
        assert.same({ {}, {}, {}, {}, {}, {} },
            { db.runs, db.bests, db.groupBests, db.teams, db.streaks, db.endBosses })
        assert.same({ 0, 0 }, { db.probe.threat.readable, db.probe.fights })
    end)

    it("keeps the settings of a PaTiCompetition save (schema 1) and replaces its old probe", function()
        local old = { schema = 1, scale = 1.1, language = "deDE", opacity = 0.9, locked = true, theme = "dracula",
            x = 40, probe = { combatLog = { total = 3 }, players = {} } }
        local db = load().Migrate(old)
        assert.same({ 1.1, "deDE", 0.9, true, "dracula", 40 }, { db.scale, db.language, db.opacity, db.locked,
            db.theme, db.x })
        assert.is_nil(db.probe.combatLog)
        assert.equal(0, db.probe.deaths.readable)
    end)

    it("keeps a saved false, repairs broken values and drops a broken run or report", function()
        local Logic = load()
        local db = Logic.Migrate({ schema = 2, showHud = false, scale = "big", myRole = "BARD", runs = "x",
            run = { state = "completed" }, report = { run = "x" } })
        assert.same({ false, 1, "AUTO", {} }, { db.showHud, db.scale, db.myRole, db.runs })
        assert.is_nil(db.run)
        assert.is_nil(db.report)
        db.run = { state = "running" }
        assert.same({ state = "running" }, Logic.Migrate(db).run)
    end)

    it("schema 3 sets the old default opacity 0.75 to 1 once; a chosen value and a schema 3 save stay", function()
        local Logic = load()
        assert.same({ 1, 0.9, 0.75 }, { Logic.Migrate({ schema = 2, opacity = 0.75 }).opacity,
            Logic.Migrate({ schema = 2, opacity = 0.9 }).opacity,
            Logic.Migrate({ schema = 3, opacity = 0.75 }).opacity })
        assert.equal("survival", Logic.Migrate({ groupCategory = "x" }).groupCategory)
    end)

    it("restores the default settings and keeps runs, position and probe", function()
        local Logic = load()
        local db = Logic.Migrate({ scale = 1.25, theme = "dracula", x = 40 })
        db.bests["36"] = { time = 100 }
        db.probe.fights = 7
        Logic.RestoreDefaults(db)
        assert.same({ 1, "woforever", 40, 100, 7 }, { db.scale, db.theme, db.x, db.bests["36"].time, db.probe.fights })
    end)
end)

describe("Logic probe", function()
    it("counts readable and secret reads, keeps the last boss events", function()
        local Logic = load()
        local probe = Logic.NewProbe()
        Logic.RecordRead(probe, "threat", false, true)
        Logic.RecordRead(probe, "threat", true, true)
        Logic.RecordRead(probe, "deaths", false)
        assert.same({ 1, 1, 2, 1 }, { probe.threat.readable, probe.threat.secret, probe.threat.party,
            probe.deaths.readable })
        for index = 1, Logic.MAX_ENCOUNTERS + 2 do Logic.RecordEncounter(probe, "ENCOUNTER_END", index, "Boss") end
        assert.same({ Logic.MAX_ENCOUNTERS, 3 }, { #probe.encounters, probe.encounters[1].id })
    end)
end)

describe("Logic.Clock", function()
    it("formats hours, minutes, missing times and differences", function()
        local Logic = load()
        assert.same({ "1:02:05", "0:09", "-" }, { Logic.Clock(3725), Logic.Clock(9.7), Logic.Clock(nil) })
        assert.same({ "-0:48", "+1:05" }, { Logic.Delta(-48), Logic.Delta(65) })
    end)
end)
