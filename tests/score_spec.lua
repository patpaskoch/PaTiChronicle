-- PaTiCompetition score, tank, card order and short numbers. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Score.lua", {}).Score
end

local function row(name, role, values)
    values.name, values.role = name, role
    return values
end

describe("Score.MarkTank", function()
    it("takes the TANK role, else the member who took the most damage", function()
        local Score = load()
        local rows = { row("A", "TANK", { taken = 1 }), row("B", "DAMAGER", { taken = 9 }) }
        Score.MarkTank(rows)
        assert.same({ true, false }, { rows[1].tank, rows[2].tank })
        rows = { row("A", "NONE", { taken = 1 }), row("B", nil, { taken = 9 }) }
        Score.MarkTank(rows)
        assert.same({ false, true }, { rows[1].tank, rows[2].tank })
        rows = { row("A", nil, { taken = 0 }) }
        Score.MarkTank(rows)
        assert.is_false(rows[1].tank)
    end)
end)

describe("Score.Apply", function()
    it("gives the best in every category 100 and takes points for deaths and pulled aggro", function()
        local Score = load()
        local rows = {
            row("Tank", "TANK", { done = 50, taken = 100, interrupts = 2, kills = 1, aggro = 9 }),
            row("Heal", "HEALER", { heal = 80, interrupts = 0, kills = 0, deaths = 1 }),
            row("Dps", "DAMAGER", { done = 100, interrupts = 2, kills = 4, aggro = 2 }),
        }
        Score.Apply(rows)
        -- Tank: 20 + 50×1 (taken) + 15×1 + 15×0.25 = 88.75; aggro does not count for the tank.
        -- Heal: 20 + 50×1 − 10 = 60. Dps: 20 + 50 + 15 + 15 − 2×5 = 90.
        assert.same({ 89, 60, 90 }, { rows[1].score, rows[2].score, rows[3].score })
        assert.equal(3, Score.Best(rows))
    end)

    it("gives the interrupt and killing blow points to the share when nobody has any; stays within 0-100", function()
        local Score = load()
        local rows = { row("A", "DAMAGER", { done = 10 }), row("B", "DAMAGER", { done = 5, deaths = 9 }) }
        Score.Apply(rows)
        assert.same({ 100, 0 }, { rows[1].score, rows[2].score })
    end)

    it("Best: first one on a tie, nil without rows", function()
        local Score = load()
        assert.equal(1, Score.Best({ { score = 5 }, { score = 5 } }))
        assert.is_nil(Score.Best({}))
    end)
end)

describe("Score.Order", function()
    it("tank, healer, then damage by damage done and name", function()
        local Score = load()
        local rows = { row("Z", "DAMAGER", { done = 5 }), row("H", "HEALER", { done = 9 }),
            row("A", "DAMAGER", { done = 5 }), row("T", "TANK", { done = 1, tank = true }),
            row("X", "DAMAGER", { done = 7 }) }
        local names = {}
        for _, entry in ipairs(Score.Order(rows)) do names[#names + 1] = entry.name end
        assert.same({ "T", "H", "X", "A", "Z" }, names)
    end)
end)

describe("Score.Short", function()
    it("shortens thousands and millions in the language's format", function()
        local Score = load()
        local en = { thousand = "%sk", million = "%sM", decimal = "." }
        local de = { thousand = "%s Tsd.", million = "%s Mio.", decimal = "," }
        assert.same({ "950", "9999", "18.4k", "20k", "2.5M" }, { Score.Short(950, en), Score.Short(9999, en),
            Score.Short(18420, en), Score.Short(20000, en), Score.Short(2500000, en) })
        assert.same({ "18,4 Tsd.", "18,4 Mio." }, { Score.Short(18420, de), Score.Short(18400000, de) })
    end)

    it("the example values have five members, one of each role at least", function()
        local roles = {}
        for _, entry in ipairs(load().Sample()) do roles[entry.role] = true end
        assert.same({ 5, true, true, true }, { #load().Sample(), roles.TANK, roles.HEALER, roles.DAMAGER })
    end)
end)
