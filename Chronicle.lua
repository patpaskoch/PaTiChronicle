-- PaTiChronicle: the chronicle — run history, best times, achievements and your development against your own
-- earlier runs. Pure: works on the saved tables. Tested in tests/chronicle_spec.lua.
--
-- Achievement rules (owner decision 2026-10-19, README "Achievements"): only for reliable data, never for missing
-- or incomplete data (then listed as "not checkable" with the reason), always positive, never a cause put on a
-- person, compared only with your own runs in the same dungeon and role.
local _, ns = ...
local Run = ns.Run
local Chronicle = {}
ns.Chronicle = Chronicle

Chronicle.MAX_RUNS = 20 -- kept per dungeon
Chronicle.AVERAGE_RUNS = 10 -- your average: the last runs of this dungeon and role
Chronicle.MIN_COMPARE = 3 -- earlier runs needed before comparing
Chronicle.TREND_RUNS = 5
Chronicle.TEAM_STEPS = { 3, 5, 10, 20, 50, 100 } -- "Well-rehearsed team ×N"
Chronicle.STREAK_FROM = 3 -- "Steadfast" names the streak from here on

-- Achievement ids → icon (classic icons every client has).
Chronicle.ICONS = {
    BEST_TIME = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    FIRST_TIME = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    SURVIVED_ALL = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02",
    NO_WIPE = "Interface\\Icons\\Spell_Holy_Resurrection",
    TEAM = "Interface\\Icons\\Ability_Warrior_BattleShout",
    STEADFAST = "Interface\\Icons\\Ability_Warrior_ShieldWall",
    IMPROVED = "Interface\\Icons\\Spell_ChargePositive",
    AGGRO_CONTROL = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    UNTOUCHED = "Interface\\Icons\\Ability_Stealth",
    CLEAN_AGGRO = "Interface\\Icons\\Ability_Rogue_Feint",
}

-- What the data of this run supports (see Run.lua "complete").
function Chronicle.Reliable(run)
    local data = run.data
    local deaths = run.complete and data.deaths and not data.deathsSecret
    local threat = run.complete and data.threat and not data.threatSecret
    local role = run.myRole
    return {
        deaths = deaths == true,
        mineAggro = threat == true and (role == "HEALER" or role == "DAMAGER"),
        othersAggro = threat == true and run.tank ~= nil,
        complete = run.complete == true,
    }
end

-- The value a run adds to your history (nil = not measured).
function Chronicle.Summary(run, size, names)
    local ok = Chronicle.Reliable(run)
    local aggro
    if run.myRole == "TANK" and ok.othersAggro then aggro = run.aggro.others
    elseif ok.mineAggro then aggro = run.aggro.mine end
    return { at = run.start, name = run.name, time = Run.Duration(run, run.now), counted = Run.Counted(run, size),
        complete = ok.complete, how = run.how, size = size, group = Run.GroupKey(names), role = run.myRole,
        deaths = ok.deaths and (run.deaths[run.me] or 0) or nil,
        groupDeaths = ok.deaths and Run.GroupDeaths(run) or nil, aggro = aggro }
end

local function values(history, metric, role)
    local list = {}
    for _, entry in ipairs(history) do
        local fits = metric == "time" and entry.counted or (entry.complete and entry.role == role)
        if fits and type(entry[metric]) == "number" then list[#list + 1] = entry[metric] end
    end
    return list
end

local function average(list, count)
    local total, n = 0, 0
    for index = math.max(1, #list - count + 1), #list do total, n = total + list[index], n + 1 end
    return n > 0 and total / n or nil, n
end

-- Your development: time (counted runs, any group), your deaths, your aggro moments (tank: the group's).
-- Lower is better for all three. state: "few" (fewer than MIN_COMPARE earlier runs), "better", "same", "worse".
function Chronicle.Development(history, summary)
    local rows = {}
    for _, metric in ipairs({ "time", "deaths", "aggro" }) do
        local value = summary[metric]
        if metric == "time" and not summary.counted then value = nil end
        local earlier = values(history, metric, summary.role)
        local avg, n = average(earlier, Chronicle.AVERAGE_RUNS)
        local trend = {}
        for index = math.max(1, #earlier - Chronicle.TREND_RUNS + 2), #earlier do trend[#trend + 1] = earlier[index] end
        if value ~= nil then trend[#trend + 1] = value end
        local state = "few"
        if value ~= nil and #earlier >= Chronicle.MIN_COMPARE then
            local margin = metric == "time" and avg * 0.01 or 0.05
            if value < avg - margin then state = "better" elseif value > avg + margin then state = "worse"
            else state = "same" end
        end
        rows[#rows + 1] = { metric = metric, value = value, avg = avg, n = n, earlier = #earlier, trend = trend,
            state = value == nil and "missing" or state }
    end
    return rows
end

local function add(list, id, args) list[#list + 1] = { id = id, args = args or {} } end

local function teamStep(count)
    for _, step in ipairs(Chronicle.TEAM_STEPS) do
        if step == count then return true end
    end
    return false
end

-- Evaluates a finished run against the saved records BEFORE they are updated (Chronicle.Store).
-- Returns { group = {…}, mine = {…}, missing = { { id, reason } }, development = rows, summary }.
function Chronicle.Evaluate(db, run, size, names)
    local summary = Chronicle.Summary(run, size, names)
    local ok = Chronicle.Reliable(run)
    local result = { group = {}, mine = {}, missing = {}, summary = summary }
    local function missing(id, reason) result.missing[#result.missing + 1] = { id = id, reason = reason } end
    local deathReason = not ok.complete and "GAP" or "NO_DEATH_DATA"

    if summary.counted then
        local best = db.bests[run.key]
        local groupBest = db.groupBests[run.key] and db.groupBests[run.key][summary.group]
        if not best then
            add(result.group, "FIRST_TIME", { time = summary.time })
        elseif summary.time < best.time then
            add(result.group, "BEST_TIME", { delta = summary.time - best.time, personal = true })
        elseif groupBest and summary.time < groupBest then
            add(result.group, "BEST_TIME", { delta = summary.time - groupBest, personal = false })
        end
        local together = (db.teams[summary.group] or 0) + 1
        if teamStep(together) then add(result.group, "TEAM", { count = together }) end
    end
    if ok.deaths then
        if summary.groupDeaths == 0 then add(result.group, "SURVIVED_ALL")
        elseif run.wipes == 0 then add(result.group, "NO_WIPE", { deaths = summary.groupDeaths }) end
    else
        missing("SURVIVED_ALL", deathReason)
    end

    if ok.deaths and summary.counted then
        if summary.deaths == 0 then
            local streak = (db.streaks[summary.role] or 0) + 1
            add(result.mine, "STEADFAST", { streak = streak >= Chronicle.STREAK_FROM and streak or nil })
        end
    elseif not ok.deaths then
        missing("STEADFAST", deathReason)
    end

    local role = summary.role
    if role == "TANK" then
        if ok.othersAggro then
            if run.aggro.others == 0 and #run.fights > 0 then add(result.mine, "AGGRO_CONTROL") end
        else missing("AGGRO_CONTROL", not ok.complete and "GAP" or "NO_THREAT_DATA") end
    elseif role == "HEALER" or role == "DAMAGER" then
        local id = role == "HEALER" and "UNTOUCHED" or "CLEAN_AGGRO"
        if ok.mineAggro then
            if run.aggro.mine == 0 and #run.fights > 0 then add(result.mine, id) end
        else missing(id, not ok.complete and "GAP" or "NO_THREAT_DATA") end
    else
        missing("ROLE", "NO_ROLE")
    end

    result.development = Chronicle.Development(db.runs[run.key] or {}, summary)
    local bestGain, bestRow = 0, nil
    for _, row in ipairs(result.development) do
        if row.state == "better" and row.avg and row.avg > 0 then
            local gain = (row.avg - row.value) / row.avg
            -- Same gain: the value with the larger average says more ("aggro 0, average 1.8" beats "deaths 0, 0.2").
            if gain > bestGain or (bestRow and gain == bestGain and row.avg > bestRow.avg) then
                bestGain, bestRow = gain, row
            end
        end
    end
    if bestRow then
        add(result.mine, "IMPROVED", { metric = bestRow.metric, value = bestRow.value, avg = bestRow.avg })
    end
    return result
end

-- Saves the run into the history and records (after Evaluate).
function Chronicle.Store(db, run, summary)
    local history = db.runs[run.key] or {}
    db.runs[run.key] = history
    history[#history + 1] = summary
    while #history > Chronicle.MAX_RUNS do table.remove(history, 1) end
    if summary.counted then
        local best = db.bests[run.key]
        if not best or summary.time < best.time then
            db.bests[run.key] = { time = summary.time, at = summary.at, group = summary.group, how = summary.how }
        end
        local groups = db.groupBests[run.key] or {}
        db.groupBests[run.key] = groups
        if not groups[summary.group] or summary.time < groups[summary.group] then
            groups[summary.group] = summary.time
        end
        db.teams[summary.group] = (db.teams[summary.group] or 0) + 1
        if summary.deaths ~= nil then
            db.streaks[summary.role] = summary.deaths == 0 and (db.streaks[summary.role] or 0) + 1 or 0
        end
    end
end

-- Ended by hand right after a boss: that boss is the end boss of this dungeon from now on (the next run ends by
-- itself there). Returns true when a new end boss was learned.
Chronicle.END_BOSS_WITHIN = 300 -- seconds between the boss kill and the click
function Chronicle.LearnEndBoss(db, run, now)
    local id = ns.Run.LastBoss(run, now, Chronicle.END_BOSS_WITHIN)
    if not id or db.endBosses[run.key] == id then return false end
    db.endBosses[run.key] = id
    return true
end

-- Best time for the HUD (nil without one).
function Chronicle.BestTime(db, key)
    local best = db.bests[key]
    return best and best.time or nil
end

return Chronicle
