-- PaTiChronicle achievements, records, development and the example run. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    local ns = {}
    for _, file in ipairs({ "Logic.lua", "Run.lua", "Chronicle.lua", "Sample.lua" }) do wow.loadAddonFile(file, ns) end
    return ns
end

local DUNGEON = { key = "36", name = "Deadmines" }
local NAMES = { "Arden", "Kael", "Korr", "Mira", "Nyra" }
local T = 1000

-- A finished run: duration seconds, role, deaths { name = count }, readable data, aggro { mine, others }.
local function finished(ns, options)
    local Run = ns.Run
    local run = Run.New(DUNGEON, T, { name = "Kael", role = options.role or "DAMAGER" })
    run.tank = options.tank
    Run.FightStart(run, T + 10)
    for _, name in ipairs(NAMES) do Run.DeathState(run, name, false, false, T + 10) end
    for name, count in pairs(options.deaths or {}) do
        for _ = 1, count do
            Run.DeathState(run, name, true, false, T + 20)
            Run.DeathState(run, name, false, false, T + 30)
        end
    end
    if options.threat ~= false then Run.Threat(run, "Kael", 0, false, true, 0, T + 11) end
    run.aggro.mine, run.aggro.others = options.mine or 0, options.others or 0
    if options.gap then run.complete = false end
    if options.noDeathData then run.data.deaths = false end
    return Run.Finish(run, T + (options.time or 1500), "auto", 0)
end

local function ids(list)
    local out = {}
    for _, entry in ipairs(list) do out[#out + 1] = entry.id end
    return out
end

describe("Chronicle.Evaluate", function()
    it("first counted run: first time, survived together, steadfast, clean aggro", function()
        local ns = load()
        local db = ns.Logic.Migrate(nil)
        local result = ns.Chronicle.Evaluate(db, finished(ns, {}), 5, NAMES)
        assert.same({ "FIRST_TIME", "SURVIVED_ALL" }, ids(result.group))
        assert.same({ "STEADFAST", "CLEAN_AGGRO" }, ids(result.mine))
        assert.same({}, result.missing)
    end)

    it("new best time and team steps after earlier runs; no wipe with deaths", function()
        local ns = load()
        local db = ns.Logic.Migrate(nil)
        for _ = 1, 2 do
            local run = finished(ns, { time = 1600 })
            ns.Chronicle.Store(db, run, ns.Chronicle.Evaluate(db, run, 5, NAMES).summary)
        end
        local result = ns.Chronicle.Evaluate(db, finished(ns, { time = 1500, deaths = { Nyra = 1 } }), 5, NAMES)
        assert.same({ "BEST_TIME", "TEAM", "NO_WIPE" }, ids(result.group))
        assert.same({ -100, true, 3, 1 }, { result.group[1].args.delta, result.group[1].args.personal,
            result.group[2].args.count, result.group[3].args.deaths })
    end)

    it("gives nothing for missing data and says why; gaps give no 'nothing happened' achievement", function()
        local ns = load()
        local db = ns.Logic.Migrate(nil)
        local result = ns.Chronicle.Evaluate(db, finished(ns, { gap = true }), 5, NAMES)
        assert.same({ "FIRST_TIME" }, ids(result.group))
        assert.same({}, ids(result.mine))
        assert.same({ { id = "SURVIVED_ALL", reason = "GAP" }, { id = "STEADFAST", reason = "GAP" },
            { id = "CLEAN_AGGRO", reason = "GAP" } }, result.missing)
        result = ns.Chronicle.Evaluate(db, finished(ns, { noDeathData = true, threat = false }), 5, NAMES)
        assert.same({ "NO_DEATH_DATA", "NO_THREAT_DATA" }, { result.missing[1].reason, result.missing[3].reason })
    end)

    it("tank: aggro under control only with a known tank; unknown role is not checkable", function()
        local ns = load()
        local db = ns.Logic.Migrate(nil)
        local result = ns.Chronicle.Evaluate(db, finished(ns, { role = "TANK", tank = "Kael" }), 5, NAMES)
        assert.same({ "STEADFAST", "AGGRO_CONTROL" }, ids(result.mine))
        result = ns.Chronicle.Evaluate(db, finished(ns, { role = "TANK" }), 5, NAMES)
        assert.equal("AGGRO_CONTROL", result.missing[1].id)
        result = ns.Chronicle.Evaluate(db, finished(ns, { role = "NONE" }), 5, NAMES)
        assert.same({ id = "ROLE", reason = "NO_ROLE" }, result.missing[1])
    end)

    it("fewer than MIN_COUNTED players: no best time, no team, no steadfast", function()
        local ns = load()
        local result = ns.Chronicle.Evaluate(ns.Logic.Migrate(nil), finished(ns, {}), 2, { "Kael", "Mira" })
        assert.same({ "SURVIVED_ALL" }, ids(result.group))
        assert.same({ "CLEAN_AGGRO" }, ids(result.mine))
    end)
end)

describe("Chronicle development", function()
    it("compares with at least MIN_COMPARE earlier runs of the same role; picks the clearest gain", function()
        local ns = load()
        local db = ns.Logic.Migrate(nil)
        for index, aggro in ipairs({ 2, 2, 1 }) do
            local run = finished(ns, { time = 1500 + index * 10, mine = aggro })
            ns.Chronicle.Store(db, run, ns.Chronicle.Evaluate(db, run, 5, NAMES).summary)
            local healer = finished(ns, { role = "HEALER", mine = 9 })
            ns.Chronicle.Store(db, healer, ns.Chronicle.Evaluate(db, healer, 5, NAMES).summary)
        end
        local result = ns.Chronicle.Evaluate(db, finished(ns, { time = 1600, mine = 0 }), 5, NAMES)
        local rows = {}
        for _, row in ipairs(result.development) do rows[row.metric] = row end
        assert.same({ "worse", "same", "better" }, { rows.time.state, rows.deaths.state, rows.aggro.state })
        assert.equal(3, rows.aggro.earlier) -- the healer runs do not count for the damage role
        assert.same({ 2, 2, 1, 0 }, rows.aggro.trend)
        local improved = result.mine[#result.mine]
        assert.same({ "IMPROVED", "aggro", 0 }, { improved.id, improved.args.metric, improved.args.value })
    end)

    it("keeps MAX_RUNS per dungeon, the best time and the survival streak", function()
        local ns = load()
        local db = ns.Logic.Migrate(nil)
        for index = 1, ns.Chronicle.MAX_RUNS + 2 do
            local run = finished(ns, { time = 2000 - index, deaths = index == 4 and { Kael = 1 } or nil })
            ns.Chronicle.Store(db, run, ns.Chronicle.Evaluate(db, run, 5, NAMES).summary)
        end
        assert.same({ ns.Chronicle.MAX_RUNS, 2000 - ns.Chronicle.MAX_RUNS - 2 },
            { #db.runs["36"], db.bests["36"].time })
        assert.equal(ns.Chronicle.MAX_RUNS + 2 - 4, db.streaks.DAMAGER)
    end)

    it("learns the end boss from a manual end right after a boss", function()
        local ns = load()
        local db = ns.Logic.Migrate(nil)
        local run = ns.Run.New(DUNGEON, T, { name = "Kael", role = "DAMAGER" })
        ns.Run.BossEnd(run, T + 100, "Edwin VanCleef", true, 1279)
        assert.is_true(ns.Chronicle.LearnEndBoss(db, run, T + 150))
        assert.is_false(ns.Chronicle.LearnEndBoss(db, run, T + 160))
        assert.equal(1279, db.endBosses["36"])
    end)
end)

describe("Chronicle group table and highlights", function()
    it("one row per name in the given order; missing values carry a reason, never 0", function()
        local ns = load()
        local run = finished(ns, { tank = "Arden", deaths = { Korr = 1 } })
        run.members.Arden = { name = "Arden", role = "TANK" }
        ns.Run.FightStart(run, T + 40)
        ns.Run.Threat(run, "Korr", 2, false, false, 0, T + 40)
        ns.Run.FightEnd(run, T + 45, 5)
        local rows, total = ns.Chronicle.PlayerRows(run, { "Arden", "Mira", "Korr" })
        assert.same({ "Arden", "Mira", "Korr" }, { rows[1].name, rows[2].name, rows[3].name })
        assert.same({ "TANK", 0, 1, 1 }, { rows[1].attackedReason, rows[2].attacked, rows[3].attacked, rows[3].deaths })
        assert.same({ 10, 1, 1 }, { rows[3].deadTime, total.deaths, total.attacked })
        run.complete = false
        rows = ns.Chronicle.PlayerRows(run, { "Mira" })
        assert.same({ nil, "GAP", "GAP" }, { rows[1].deaths, rows[1].deathsReason, rows[1].attackedReason })
    end)

    it("without a known tank only your own attacks are counted", function()
        local ns = load()
        local rows = ns.Chronicle.PlayerRows(finished(ns, {}), { "Kael", "Korr" })
        assert.same({ 0, "NO_TANK" }, { rows[1].attacked, rows[2].attackedReason })
    end)

    it("highlights: the fight with the most deaths and the longest fight, in time order", function()
        local report = load().Sample.Report("Die Todesminen")
        local list = load().Chronicle.Highlights(report.run)
        assert.same({ "HL_DEATHS", 2, 10 }, { list[1].id, list[1].args.count, list[1].args.fight })
        assert.same({ "HL_LONG_BOSS", "Edwin VanCleef", 113 }, { list[2].id, list[2].args.boss, list[2].args.seconds })
    end)

    it("contribution from the meter: per member and the group total; without meter data n/a", function()
        local report = load().Sample.Report("Die Todesminen")
        local rows, total = load().Chronicle.PlayerRows(report.run, report.names)
        assert.same({ 27030, 21465, 6, 4 }, { rows[3].damage, rows[2].healing, rows[3].interrupts, rows[2].dispels })
        assert.equal(14310 + 3180 + 27030 + 23055 + 24645, total.damage)
        local ns = load()
        local plain = ns.Chronicle.PlayerRows(finished(ns, {}), { "Kael" })
        assert.same({ nil, "METER" }, { plain[1].damage, plain[1].damageReason })
    end)

    it("the example run: per member values and your best run time here", function()
        local report = load().Sample.Report("Die Todesminen")
        local rows = load().Chronicle.PlayerRows(report.run, report.names)
        assert.same({ 39, 42, 1 }, { rows[5].deadTime, rows[4].deadTime, rows[4].attacked })
        assert.is_true(report.result.development[1].best)
    end)
end)

describe("Sample.Report", function()
    it("the example run gives the achievements the report shows in test mode", function()
        local report = load().Sample.Report("Die Todesminen")
        assert.same({ "BEST_TIME", "TEAM", "NO_WIPE" }, ids(report.result.group))
        assert.same({ "STEADFAST", "CLEAN_AGGRO", "IMPROVED" }, ids(report.result.mine))
        -- Deaths and aggro both improved by 100 %: the larger average (aggro 1.75 vs. deaths 0.25) is named.
        assert.equal("aggro", report.result.mine[3].args.metric)
        assert.same({ 5, 2, 1453, 5 }, { report.result.group[2].args.count + 2, report.result.summary.groupDeaths,
            report.result.summary.time, report.result.mine[1].args.streak })
    end)
end)
