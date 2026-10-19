-- PaTiChronicle score and end-screen values: who counts as tank, the score 0-100, card order, short numbers and
-- the example values of /pchron test. Pure: no WoW calls. Tested in tests/score_spec.lua.
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
Score.PENALTY_BAR = 20 -- minus points that fill a penalty bar on the end screen (2 deaths or 4 pulled aggro)

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

-- The share counts once: the best of damage, healing and (tank only) damage taken. First one wins a tie.
local SHARE_KEYS = { "done", "heal", "taken" }

-- Adds row.tank, row.parts (points per value, the minus points negative) and row.score to every row.
-- Returns the most points each value can give ({ done = …, interrupts = …, deaths = PENALTY_BAR … }), for bars.
function Score.Apply(rows)
    Score.MarkTank(rows)
    local best = {}
    for _, key in ipairs({ "done", "heal", "taken", "interrupts", "kills" }) do best[key] = most(rows, key) end
    local shareWeight = Score.SHARE + (best.interrupts > 0 and 0 or Score.INTERRUPTS)
        + (best.kills > 0 and 0 or Score.KILLS)
    for _, row in ipairs(rows) do
        local parts = { done = 0, heal = 0, taken = 0 }
        local mainKey, main = nil, 0
        for _, key in ipairs(SHARE_KEYS) do
            local value = (key ~= "taken" or row.tank) and share(row[key], best[key]) or 0
            if value > main then mainKey, main = key, value end
        end
        if mainKey then parts[mainKey] = shareWeight * main end
        parts.interrupts = Score.INTERRUPTS * share(row.interrupts, best.interrupts)
        parts.kills = Score.KILLS * share(row.kills, best.kills)
        parts.deaths = -Score.DEATH * (row.deaths or 0)
        parts.aggro = row.tank and 0 or -Score.AGGRO * (row.aggro or 0)
        local points = Score.BASE
        for _, value in pairs(parts) do points = points + value end
        row.parts = parts
        row.score = math.max(0, math.min(100, math.floor(points + 0.5)))
    end
    return { done = shareWeight, heal = shareWeight, taken = shareWeight, interrupts = Score.INTERRUPTS,
        kills = Score.KILLS, deaths = Score.PENALTY_BAR, aggro = Score.PENALTY_BAR }
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

-- Example values for /pchron test (the owner's design, 2026-10-19), in classic dungeon sizes; level and class
-- (classFile: the client names it) since the owner's wish of 2026-10-19.
function Score.Sample()
    return {
        { name = "Arden", role = "TANK", level = 60, classFile = "WARRIOR",
            done = 18400, taken = 41200, heal = 3200, interrupts = 14, kills = 9, deaths = 0, aggro = 0 },
        { name = "Mira", role = "HEALER", level = 60, classFile = "PRIEST",
            done = 4800, taken = 6100, heal = 32600, interrupts = 2, kills = 1, deaths = 0, aggro = 1 },
        { name = "Kael", role = "DAMAGER", level = 59, classFile = "MAGE",
            done = 29700, taken = 9800, heal = 800, interrupts = 9, kills = 17, deaths = 1, aggro = 2 },
        { name = "Nyra", role = "DAMAGER", level = 60, classFile = "ROGUE",
            done = 31200, taken = 5200, heal = 1100, interrupts = 11, kills = 21, deaths = 0, aggro = 0 },
        { name = "Korr", role = "DAMAGER", level = 58, classFile = "HUNTER",
            done = 26500, taken = 14300, heal = 600, interrupts = 7, kills = 12, deaths = 2, aggro = 3 },
    }
end

return Score
