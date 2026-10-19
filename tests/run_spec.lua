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
