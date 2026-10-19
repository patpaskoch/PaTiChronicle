-- PaTiCompetition score and end-screen values: who counts as tank, the score 0-100, card order, short numbers and
-- the example values of /pcomp test. Pure: no WoW calls. Tested in tests/score_spec.lua.
local _, ns = ...
local Score = {}
ns.Score = Score

-- Score 0-100 per member, relative to the group of this run (owner 2026-10-19; tune after real runs):
--   BASE
-- + SHARE × the best share: damage / most damage, healing / most healing; the tank also damage taken / most taken
-- + INTERRUPTS × interrupts / most interrupts      (nobody interrupted: these points go to the share)
-- + KILLS × killing blows / most killing blows     (nobody struck one: the same)
-- − DEATH per death, − AGGRO per pulled aggro (not for the tank)
Score.BASE, Score.SHARE, Score.INTERRUPTS, Score.KILLS = 20, 50, 15, 15
Score.DEATH, Score.AGGRO = 10, 5

local function most(rows, key)
    local best = 0
    for _, row in ipairs(rows) do best = math.max(best, row[key] or 0) end
    return best
end

local function share(value, best) return best > 0 and (value or 0) / best or 0 end

-- The tank: role TANK; without role selection the member who took the most damage (if anyone took some).
function Score.MarkTank(rows)
    local anyRole = false
    for _, row in ipairs(rows) do
        row.tank = row.role == "TANK"
        anyRole = anyRole or row.tank
    end
    if anyRole then return end
    local tank, taken = nil, 0
    for _, row in ipairs(rows) do
        if (row.taken or 0) > taken then tank, taken = row, row.taken end
    end
    if tank then tank.tank = true end
end

-- Adds row.tank and row.score to every row.
function Score.Apply(rows)
    Score.MarkTank(rows)
    local bestDone, bestHeal, bestTaken = most(rows, "done"), most(rows, "heal"), most(rows, "taken")
    local bestInterrupts, bestKills = most(rows, "interrupts"), most(rows, "kills")
    local shareWeight = Score.SHARE + (bestInterrupts > 0 and 0 or Score.INTERRUPTS)
        + (bestKills > 0 and 0 or Score.KILLS)
    for _, row in ipairs(rows) do
        local part = math.max(share(row.done, bestDone), share(row.heal, bestHeal),
            row.tank and share(row.taken, bestTaken) or 0)
        local points = Score.BASE + shareWeight * part
            + Score.INTERRUPTS * share(row.interrupts, bestInterrupts) + Score.KILLS * share(row.kills, bestKills)
            - Score.DEATH * (row.deaths or 0) - (row.tank and 0 or Score.AGGRO * (row.aggro or 0))
        row.score = math.max(0, math.min(100, math.floor(points + 0.5)))
    end
end

-- Index of the best score (the first one on a tie), or nil without rows.
function Score.Best(rows)
    local best
    for index, row in ipairs(rows) do
        if not best or (row.score or 0) > (rows[best].score or 0) then best = index end
    end
    return best
end

-- Card order: tank, healers, then by damage (most first), then by name.
local function rank(row)
    if row.tank then return 1 end
    if row.role == "HEALER" then return 2 end
    return 3
end

function Score.Order(rows)
    table.sort(rows, function(a, b)
        if rank(a) ~= rank(b) then return rank(a) < rank(b) end
        if (a.done or 0) ~= (b.done or 0) then return (a.done or 0) > (b.done or 0) end
        return a.name < b.name
    end)
    return rows
end

-- 950 → "950", 18420 → "18.4k", 2500000 → "2.5M". format: { thousand = "%sk", million = "%sM", decimal = "." }.
function Score.Short(value, format)
    value = math.floor(value or 0)
    if value < 10000 then return tostring(value) end
    local pattern, scaled = format.thousand, value / 1000
    if value >= 1000000 then pattern, scaled = format.million, value / 1000000 end
    local text = ("%.1f"):format(scaled):gsub("%.0$", ""):gsub("%.", format.decimal)
    return pattern:format(text)
end

-- Example values for /pcomp test (the owner's design, 2026-10-19), in classic dungeon sizes.
function Score.Sample()
    return {
        { name = "Arden", role = "TANK", done = 18400, taken = 41200, heal = 3200, interrupts = 14, kills = 9,
            deaths = 0, aggro = 0 },
        { name = "Mira", role = "HEALER", done = 4800, taken = 6100, heal = 32600, interrupts = 2, kills = 1,
            deaths = 0, aggro = 1 },
        { name = "Kael", role = "DAMAGER", done = 29700, taken = 9800, heal = 800, interrupts = 9, kills = 17,
            deaths = 1, aggro = 2 },
        { name = "Nyra", role = "DAMAGER", done = 31200, taken = 5200, heal = 1100, interrupts = 11, kills = 21,
            deaths = 0, aggro = 0 },
        { name = "Korr", role = "DAMAGER", done = 26500, taken = 14300, heal = 600, interrupts = 7, kills = 12,
            deaths = 2, aggro = 3 },
    }
end

return Score
