-- PaTiChronicle run rules: start, continue, end, abort, counted, complete; deaths, wipes, aggro moments, bosses.
-- Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Run.lua", {}).Run
end

local DUNGEON = { key = "36", name = "Deadmines" }
local T = 1000 -- run start (time())

local function newRun(Run, role)
    return Run.New(DUNGEON, T, { name = "Kael", role = role or "DAMAGER" })
end

describe("Run lifecycle", function()
    it("continues after leaving as a ghost, stays complete; any other exit leaves a gap", function()
        local Run = load()
        local run = newRun(Run)
        Run.Leave(run, T + 100, true)
        assert.equal(run, Run.Resume(run, DUNGEON, T + 300))
        assert.is_true(run.complete)
        Run.Leave(run, T + 400, false)
        assert.equal(run, Run.Resume(run, DUNGEON, T + 500))
        assert.is_false(run.complete)
    end)

    it("is aborted in another dungeon or after LEAVE_GRACE outside", function()
        local Run = load()
        local run = newRun(Run)
        local resumed, reason = Run.Resume(run, { key = "43" }, T + 10)
        assert.same({ nil, "other" }, { resumed, reason })
        Run.Leave(run, T + 10, true)
        assert.is_true(Run.StillWaiting(run, T + 10 + Run.LEAVE_GRACE))
        assert.is_false(Run.StillWaiting(run, T + 11 + Run.LEAVE_GRACE))
        resumed, reason = Run.Resume(run, DUNGEON, T + 11 + Run.LEAVE_GRACE)
        assert.same({ nil, "left" }, { resumed, reason })
    end)

    it("a login continues with a gap; after LOGOUT_GRACE it is too late", function()
        local Run = load()
        local run = newRun(Run)
        Run.Logout(run, T + 50)
        assert.equal(run, Run.Login(run, T + 60))
        assert.is_false(run.complete)
        Run.Logout(run, T + 100)
        local resumed, reason = Run.Login(run, T + 101 + Run.LOGOUT_GRACE)
        assert.same({ nil, "logout" }, { resumed, reason })
    end)

    it("counts for best times only when completed with at least MIN_COUNTED members", function()
        local Run = load()
        local run = newRun(Run)
        assert.is_false(Run.Counted(run, 5))
        Run.Finish(run, T + 1453, "manual", 0)
        assert.same({ true, false, 1453, "manual" }, { Run.Counted(run, 3), Run.Counted(run, 2), Run.Duration(run),
            run.how })
        local aborted = Run.Abort(newRun(Run), T + 60, "click")
        assert.is_false(Run.Counted(aborted, 5))
    end)

    it("names a group by its sorted member names", function()
        assert.equal("Arden,Kael,Mira", load().GroupKey({ "Mira", "Arden", "Kael" }))
    end)
end)

describe("Run per member (schema 3)", function()
    it("keeps death times, time dead (also still dead at the end) and attacks per member", function()
        local Run = load()
        local run = newRun(Run)
        Run.FightStart(run, T)
        Run.DeathState(run, "Nyra", false, false, T)
        Run.DeathState(run, "Nyra", true, false, T + 20)
        Run.DeathState(run, "Nyra", false, false, T + 59)
        Run.DeathState(run, "Korr", true, false, T + 100)
        Run.Threat(run, "Korr", 2, false, false, 1, T + 1)
        Run.Threat(run, "Korr", 0, false, false, 5, T + 5)
        Run.Finish(run, T + 130, "manual", 6)
        assert.same({ { 20 }, 39, 30, 1, 4, { 1 } }, { run.deathTimes.Nyra, run.deadTime.Nyra, run.deadTime.Korr,
            run.attacked.Korr.count, run.attacked.Korr.seconds, run.attacked.Korr.times })
    end)

    it("counts the time in the group across leaving and coming back", function()
        local Run = load()
        local run = newRun(Run)
        Run.Presence(run, { "Kael", "Nyra" }, T)
        Run.Presence(run, { "Kael" }, T + 100)
        Run.Presence(run, { "Kael", "Nyra" }, T + 200)
        Run.Finish(run, T + 300, "manual", 0)
        assert.same({ 300, 200 }, { Run.PresentSeconds(run, "Kael"), Run.PresentSeconds(run, "Nyra") })
        assert.is_nil(Run.PresentSeconds(run, "Mira"))
    end)

    it("a run saved before version 3 still works without the new tables", function()
        local Run = load()
        local run = newRun(Run)
        for _, key in ipairs({ "version", "attacked", "deathTimes", "deadSince", "deadTime", "present" }) do
            run[key] = nil
        end
        Run.FightStart(run, T)
        Run.DeathState(run, "Nyra", true, false, T + 5)
        Run.Threat(run, "Korr", 2, false, false, 0, T)
        Run.Presence(run, { "Kael" }, T)
        Run.Finish(run, T + 10, "manual", 9)
        assert.same({ 1, 1 }, { run.deaths.Nyra, run.aggro.others })
    end)
end)

describe("Run events", function()
    it("counts a death once, a wipe once per fight, and notes unreadable deaths", function()
        local Run = load()
        local run = newRun(Run)
        Run.FightStart(run, T + 10)
        Run.DeathState(run, "Nyra", false, false, T + 11)
        Run.DeathState(run, "Nyra", true, false, T + 20)
        Run.DeathState(run, "Nyra", true, false, T + 21) -- still dead: no second death
        Run.DeathState(run, "Korr", true, true, T + 22)
        Run.DeathState(run, "Kael", true, true, T + 23)
        assert.same({ 1, 1, 1, 3, 1 }, { run.deaths.Nyra, run.deaths.Korr, run.wipes, Run.GroupDeaths(run),
            run.events[1].fight })
        assert.same({ "death", 20 }, { run.events[1].kind, run.events[1].t })
        Run.DeathState(run, "Mira", nil, false, T + 30)
        assert.is_true(run.data.deathsSecret)
    end)

    it("a member's newer role, class and level replace the old ones; an unknown role keeps the known one", function()
        local Run = load()
        local run = newRun(Run)
        Run.AddMember(run, { name = "Mira", role = "DAMAGER", level = 19 })
        Run.AddMember(run, { name = "Mira", role = "HEALER", level = 20, classFile = "PRIEST" })
        Run.AddMember(run, { name = "Mira", role = "NONE" })
        assert.same({ "HEALER", 20, "PRIEST" }, { run.members.Mira.role, run.members.Mira.level,
            run.members.Mira.classFile })
    end)

    it("a wipe still counts when your own death ended combat first, but not long after the fight", function()
        local Run = load()
        local run = newRun(Run)
        Run.FightStart(run, T + 10)
        Run.DeathState(run, "Kael", true, false, T + 20)
        Run.FightEnd(run, T + 20, 20) -- dead: WoW ends combat for you
        Run.DeathState(run, "Korr", true, false, T + 25)
        Run.DeathState(run, "Nyra", true, true, T + 30)
        assert.same({ 1, true }, { run.wipes, run.fights[1].wipe })
        local late = newRun(Run)
        Run.FightStart(late, T + 10)
        Run.FightEnd(late, T + 20, 20)
        Run.DeathState(late, "Nyra", true, true, T + 20 + Run.WIPE_GRACE + 1)
        assert.same(0, late.wipes)
    end)

    it("an aggro moment needs AGGRO_SECONDS without a break; the tank never counts; only yours carry you", function()
        local Run = load()
        local run = newRun(Run)
        Run.FightStart(run, T)
        Run.Threat(run, "Korr", 2, false, false, 1.0, T + 1)
        Run.Threat(run, "Korr", 1, false, false, 2.5, T + 2) -- 1.5 s: too short
        Run.Threat(run, "Arden", 3, true, false, 3.0, T + 3) -- the tank
        Run.Threat(run, "Kael", 3, false, true, 4.0, T + 4)
        Run.Threat(run, "Korr", 2, false, false, 5.0, T + 5)
        Run.FightEnd(run, T + 9, 9.0) -- the end of the fight closes open moments
        assert.same({ 1, 1 }, { run.aggro.mine, run.aggro.others })
        local mine, others = 0, 0
        for _, entry in ipairs(run.events) do
            if entry.kind == "aggro" then
                if entry.mine then mine = mine + 1 else others = others + 1 end
                assert.is_nil(entry.name)
            end
        end
        assert.same({ 1, 1 }, { mine, others })
        Run.Threat(run, "Korr", nil, false, false, 10, T + 10)
        assert.is_true(run.data.threatSecret)
    end)

    it("marks boss fights and remembers the last won boss for learning the end boss", function()
        local Run = load()
        local run = newRun(Run)
        Run.FightStart(run, T + 100)
        Run.BossStart(run)
        Run.BossEnd(run, T + 160, "Edwin VanCleef", true, 1279)
        Run.FightEnd(run, T + 160, 0)
        assert.is_true(run.fights[1].boss)
        assert.equal(1279, Run.LastBoss(run, T + 200, 300))
        assert.is_nil(Run.LastBoss(run, T + 600, 300))
    end)
end)

describe("Run meter (contribution)", function()
    it("sums one snapshot per session; a session read again replaces itself; earlier sessions never count", function()
        local Run = load()
        local run = newRun(Run)
        assert.is_nil(Run.MeterTotals(run))
        Run.MeterStart(run, { [7] = true })
        run.data.meter = true
        Run.MeterSession(run, 7, { Kael = { damage = 999 } }) -- before the run
        Run.MeterSession(run, 8, { Kael = { damage = 100, interrupts = 1 }, Mira = { healing = 50 } })
        Run.MeterSession(run, 8, { Kael = { damage = 120, interrupts = 1 }, Mira = { healing = 60 } }) -- grew
        Run.MeterSession(run, 9, { Kael = { damage = 30 } })
        local totals = Run.MeterTotals(run)
        assert.same({ 150, 1, 60, 2 }, { totals.Kael.damage, totals.Kael.interrupts, totals.Mira.healing,
            run.meter.count })
    end)
end)
