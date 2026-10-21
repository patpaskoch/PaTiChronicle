-- PaTiChronicle contribution reader against a stand-in C_DamageMeter. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local ENUM = { DamageMeterType = { DamageDone = 0, HealingDone = 1, Interrupts = 2, Dispels = 3 },
    DamageMeterSessionType = { Overall = 0, Current = 1 } }

-- byId / current: { [meterType] = { { name =, totalAmount = }, … } } for every listed session / for type Current.
local function meterWith(ids, byId, current)
    local list = {}
    for _, id in ipairs(ids) do list[#list + 1] = { sessionID = id, name = "fight", durationSeconds = 10 } end
    return {
        GetAvailableCombatSessions = function() return list end,
        GetCombatSessionFromID = function(_, meterType) return { combatSources = byId[meterType] or {} } end,
        GetCombatSessionFromType = function(_, meterType) return { combatSources = current[meterType] or {} } end,
    }
end

local function load(meter)
    wow.install()
    _G.Enum, _G.C_DamageMeter = ENUM, meter
    local ns = {}
    for _, file in ipairs({ "Run.lua", "Meter.lua" }) do wow.loadAddonFile(file, ns) end
    local run = ns.Run.New({ key = "36", name = "Deadmines" }, 1000, { name = "Kael", role = "DAMAGER" })
    run.members.Kael, run.members.Mira = { name = "Kael" }, { name = "Mira" }
    ns.Run.MeterStart(run, { [5] = true })
    return ns, run
end

describe("Meter.Read", function()
    it("reads members by session ID; sessions from before the run and other sources stay out", function()
        local ns, run = load(meterWith({ 5, 6 }, {
            [0] = { { name = "Kael-Realm", totalAmount = 500 }, { name = "Stranger", totalAmount = 900 } },
            [1] = { { name = "Mira", totalAmount = 300 } } }, {}))
        ns.Meter.Read(run, true)
        local totals = ns.Run.MeterTotals(run)
        assert.same({ 500, 300, 1 }, { totals.Kael.damage, totals.Mira.healing, run.meter.count })
    end)

    it("an empty read by ID falls back to type Current for the newest session and never stores nothing", function()
        local ns, run = load(meterWith({ 5, 6, 7 }, {}, { [0] = { { name = "Kael", totalAmount = 250 } } }))
        ns.Meter.Read(run, false)
        assert.is_nil(ns.Run.MeterTotals(run)) -- not right after a fight: Current is not used
        ns.Meter.Read(run, true)
        assert.same({ 250, 1 }, { ns.Run.MeterTotals(run).Kael.damage, run.meter.count })
        assert.truthy(run.meter.sessions[7])
        assert.matches("by id 0 sources, current 1 sources", run.meter.diag)
        ns.Meter.Read(run, false) -- read again later: the empty read by ID keeps the stored snapshot
        assert.equal(250, ns.Run.MeterTotals(run).Kael.damage)
    end)

    it("reads nothing in combat", function()
        local ns, run = load(meterWith({ 6 }, { [0] = { { name = "Kael", totalAmount = 500 } } }, {}))
        wow.state.inCombat = true
        ns.Meter.Read(run, true)
        assert.is_nil(ns.Run.MeterTotals(run))
    end)
end)
_G.Enum, _G.C_DamageMeter = nil, nil
