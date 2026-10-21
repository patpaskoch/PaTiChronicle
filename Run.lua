-- PaTiChronicle: one dungeon run — when it starts, ends, is aborted and counts for best times, plus what happened
-- in it (fights, bosses, deaths, aggro moments). Pure: every time comes in as a number. Tested in tests/run_spec.lua.
--
-- Rules (owner decision 2026-10-19, README "Run rules"):
--   start      the first fight inside a 5-player dungeon (now = time() in seconds)
--   continues  through deaths, wipes, running back as a ghost, /reload and disconnects
--   completed  the player's own click "End run – end boss defeated", or ENCOUNTER_END of the end boss this dungeon
--              learned from such a click (Chronicle.LearnEndBoss)
--   aborted    the player's click, another dungeon, more than LEAVE_GRACE outside, or a login more than
--              LOGOUT_GRACE after the logout
--   counted    completed and at least MIN_COUNTED members at the end (best times, streaks, teams)
--   complete   ("lückenlos") nothing was missed: no /reload or disconnect, never left except as a ghost.
--              Achievements that say "nothing happened" (no death, no aggro) need a complete run.
local _, ns = ...
local Run = {}
ns.Run = Run

Run.LEAVE_GRACE = 15 * 60
Run.LOGOUT_GRACE = 30 * 60
Run.MIN_COUNTED = 3
Run.AGGRO_SECONDS = 3 -- an aggro moment: an enemy attacks a non-tank for at least this long without a break
Run.MAX_EVENTS = 200
Run.MAX_FIGHTS = 300
Run.MAX_TIMES = 10 -- death and attack times kept per member
-- Your own death ends combat for you (PLAYER_REGEN_ENABLED) before the last member dies (owner 2026-10-19: "all
-- dead, no wipe shown"): a wipe still belongs to the last fight when it ended at most this long ago.
Run.WIPE_GRACE = 60
Run.VERSION = 3 -- runs from version 3 on carry per-member values (attacked, dead time, presence); older: "n/a"

-- instance: { key, name } (key = instance ID or name); me: { name, role } (role: TANK/HEALER/DAMAGER/NONE).
function Run.New(instance, now, me)
    return { key = instance.key, name = instance.name, start = now, state = "running", complete = true,
        me = me.name, myRole = me.role or "NONE", members = {}, fights = {}, events = {}, deaths = {},
        wipes = 0, aggro = { mine = 0, others = 0 }, open = {}, version = Run.VERSION,
        attacked = {}, deathTimes = {}, deadSince = {}, deadTime = {}, present = {},
        data = { deaths = false, deathsSecret = false, threat = false, threatSecret = false, bosses = false } }
end

-- member: { name, role, classFile, className, level }. Joins keep their first entry; facts are filled in later.
function Run.AddMember(run, member)
    local entry = run.members[member.name]
    if not entry then
        entry = { name = member.name }
        run.members[member.name] = entry
    end
    -- The latest reading wins (owner 2026-10-19: a changed healer was not taken over); an unknown role ("NONE",
    -- e.g. not assigned yet) never replaces a known one.
    for key, value in pairs(member) do
        if not (key == "role" and value == "NONE" and entry.role) then entry[key] = value end
    end
end

local function offset(run, now) return math.max(0, now - run.start) end

local function event(run, now, kind, fields)
    local entry = fields or {}
    entry.t, entry.kind = offset(run, now), kind
    entry.fight = #run.fights
    run.events[#run.events + 1] = entry
    while #run.events > Run.MAX_EVENTS do table.remove(run.events, 1) end
    return entry
end

-- Back in a dungeon (login, zone change). Returns the run to continue, or nil and the reason it was aborted
-- (the caller then aborts it): "other" dungeon, "left" too long ago.
function Run.Resume(run, instance, now)
    if not run or run.state ~= "running" then return nil end
    if run.key ~= instance.key then return nil, "other" end
    if run.leftAt and now - run.leftAt > Run.LEAVE_GRACE then return nil, "left" end
    run.leftAt = nil
    return run
end

-- Left the dungeon. A ghost running back keeps the run complete; any other exit does not.
function Run.Leave(run, now, ghost)
    run.leftAt = run.leftAt or now
    if not ghost then run.complete = false end
end

-- Outside the dungeon: still in time to come back? false = abort ("left").
function Run.StillWaiting(run, now)
    return not run.leftAt or now - run.leftAt <= Run.LEAVE_GRACE
end

-- Login or /reload with a running run: events in between were missed. nil + "logout" = too late, abort.
function Run.Login(run, now)
    if run.loggedOutAt and now - run.loggedOutAt > Run.LOGOUT_GRACE then return nil, "logout" end
    run.loggedOutAt = nil
    run.complete = false
    run.open = {} -- open aggro moments cannot be timed across a reload
    return run
end

function Run.Logout(run, now) run.loggedOutAt = now end

function Run.FightStart(run, now)
    run.fights[#run.fights + 1] = { s = offset(run, now) }
    while #run.fights > Run.MAX_FIGHTS do table.remove(run.fights, 1) end
end

local function currentFight(run)
    local fight = run.fights[#run.fights]
    if fight and not fight.e then return fight end
end

-- The fight a wipe belongs to: the open one, or the last one that ended within WIPE_GRACE.
local function wipeFight(run, now)
    local fight = run.fights[#run.fights]
    if not fight then return nil end
    if not fight.e or offset(run, now) - fight.e <= Run.WIPE_GRACE then return fight end
end

-- clock: GetTime() (seconds, fractions), used only to time aggro moments in memory.
local function closeAggro(run, name, clock, now)
    local open = run.open[name]
    if not open then return end
    run.open[name] = nil
    local seconds = clock - open.since
    if seconds < Run.AGGRO_SECONDS then return end
    if open.mine then run.aggro.mine = run.aggro.mine + 1 else run.aggro.others = run.aggro.others + 1 end
    local start = now - seconds
    -- Timeline: only your own moments carry a name (owner decision). The group table counts per member
    -- (owner wish 2026-10-19: "Tode und Aggro pro Spieler"), shown as attacks, never as a cause.
    event(run, start, "aggro", { mine = open.mine, seconds = math.floor(seconds + 0.5) })
    if run.attacked then
        local entry = run.attacked[name] or { count = 0, seconds = 0, times = {} }
        run.attacked[name] = entry
        entry.count, entry.seconds = entry.count + 1, entry.seconds + math.floor(seconds + 0.5)
        if #entry.times < Run.MAX_TIMES then entry.times[#entry.times + 1] = offset(run, start) end
    end
end

function Run.FightEnd(run, now, clock)
    local fight = currentFight(run)
    if fight then fight.e = offset(run, now) end
    for name in pairs(run.open) do closeAggro(run, name, clock, now) end
end

-- A member's threat status (UnitThreatSituation 0-3, 2/3 = an enemy attacks them). status nil = secret or unknown.
-- isTank: this member is the group's tank (never counted); mine: it is you.
function Run.Threat(run, name, status, isTank, mine, clock, now)
    if status == nil then run.data.threatSecret = true; return end
    run.data.threat = true
    if isTank then closeAggro(run, name, clock, now); return end
    if status >= 2 then
        if not run.open[name] then run.open[name] = { since = clock, mine = mine } end
    else
        closeAggro(run, name, clock, now)
    end
end

-- dead: true/false, nil = secret. allDead: every member of the group is dead now (a wipe).
function Run.DeathState(run, name, dead, allDead, now)
    if dead == nil then run.data.deathsSecret = true; return end
    run.data.deaths = true
    run.alive = run.alive or {}
    local wasDead = run.alive[name] == false
    run.alive[name] = not dead
    if not dead and wasDead and run.deadSince and run.deadSince[name] then
        run.deadTime[name] = (run.deadTime[name] or 0) + offset(run, now) - run.deadSince[name]
        run.deadSince[name] = nil
    end
    if not dead or wasDead then return end
    run.deaths[name] = (run.deaths[name] or 0) + 1
    if run.deathTimes then
        local times = run.deathTimes[name] or {}
        run.deathTimes[name] = times
        if #times < Run.MAX_TIMES then times[#times + 1] = offset(run, now) end
        run.deadSince[name] = offset(run, now)
    end
    event(run, now, "death", { name = name })
    local fight = wipeFight(run, now)
    if allDead and fight and not fight.wipe then
        fight.wipe = true
        run.wipes = run.wipes + 1
        event(run, now, "wipe")
    end
end

-- ENCOUNTER_START / ENCOUNTER_END: boss fights. A won fight is an event; isEnd = the dungeon's end boss.
function Run.BossStart(run)
    run.data.bosses = true
    local fight = currentFight(run)
    if fight then fight.boss = true end
end

-- id: the encounter ID (learned as the dungeon's end boss when you end the run by hand right after it).
function Run.BossEnd(run, now, name, success, id)
    run.data.bosses = true
    if success then event(run, now, "boss", { boss = name, id = id }) end
end

-- The encounter ID of a boss won at most `within` seconds before now (nil if none).
function Run.LastBoss(run, now, within)
    for index = #run.events, 1, -1 do
        local entry = run.events[index]
        if entry.kind == "boss" and entry.id and offset(run, now) - entry.t <= within then return entry.id end
    end
end

-- Who is in the group now (names): newcomers start their time, those gone end it; a return continues it.
function Run.Presence(run, names, now)
    if not run.present then return end
    local here = {}
    for _, name in ipairs(names) do
        here[name] = true
        local entry = run.present[name]
        if not entry then
            run.present[name] = { from = offset(run, now) }
        elseif entry.to then -- back again: the time before counts too
            entry.seconds = (entry.seconds or 0) + entry.to - entry.from
            entry.from, entry.to = offset(run, now), nil
        end
    end
    for name, entry in pairs(run.present) do
        if not here[name] and not entry.to then entry.to = offset(run, now) end
    end
end

-- Seconds a member was in the group during the run (nil = not recorded).
function Run.PresentSeconds(run, name)
    local entry = run.present and run.present[name]
    if not entry then return nil end
    local stop = entry.to or Run.Duration(run, run.now)
    return (entry.seconds or 0) + math.max(0, stop - entry.from)
end

-- The end: members still dead count their time until now.
local function closeDeadTimes(run, now)
    if not run.deadSince then return end
    for name, since in pairs(run.deadSince) do
        run.deadTime[name] = (run.deadTime[name] or 0) + offset(run, now) - since
        run.deadSince[name] = nil
    end
end

function Run.Finish(run, now, how, clock)
    Run.FightEnd(run, now, clock or 0)
    closeDeadTimes(run, now)
    run.state, run.finish, run.how = "completed", now, how
    return run
end

function Run.Abort(run, now, reason)
    closeDeadTimes(run, now)
    run.state, run.finish, run.how = "aborted", now, reason
    return run
end

function Run.Duration(run, now)
    return math.max(0, (run.finish or now or run.start) - run.start)
end

-- size: members still in the group at the end.
function Run.Counted(run, size)
    return run.state == "completed" and (size or 0) >= Run.MIN_COUNTED
end

-- The group by its members' names (sorted): the same five again = the same key.
function Run.GroupKey(names)
    local list = {}
    for _, name in ipairs(names) do list[#list + 1] = name end
    table.sort(list)
    return table.concat(list, ",")
end

-- How many members died (nil without readable death data).
function Run.GroupDeaths(run)
    if not run.data.deaths then return nil end
    local total = 0
    for _, count in pairs(run.deaths) do total = total + count end
    return total
end

-- Contribution (redesign step 9, owner 2026-10-19): damage, healing, interrupts and dispels from WoW's damage meter,
-- read by Meter.lua after every fight. One snapshot per meter session ({ [name] = { damage = n, … } }), replaced
-- while WoW still lists the session (a growing session is never counted twice) and kept once it expires.
-- before: the session IDs that existed before the run; they never count.
Run.METER_KINDS = { "damage", "healing", "interrupts", "dispels" }
Run.MAX_SESSIONS = 150

function Run.MeterStart(run, before)
    run.meter = { before = before or {}, sessions = {}, count = 0 }
end

-- Stores one session snapshot; true when stored. A snapshot without any member (WoW returned no players) is never
-- stored: it would replace a good earlier read of the same session.
function Run.MeterSession(run, id, values)
    local meter = run.meter
    if not meter or meter.before[id] or next(values) == nil then return false end
    if not meter.sessions[id] then
        if meter.count >= Run.MAX_SESSIONS then return false end
        meter.count = meter.count + 1
    end
    meter.sessions[id] = values
    return true
end

-- { [name] = { damage = n, … } } summed over the run's sessions; nil without readable meter data.
function Run.MeterTotals(run)
    if not (run.meter and run.data.meter) then return nil end
    local totals = {}
    for _, values in pairs(run.meter.sessions) do
        for name, kinds in pairs(values) do
            local sum = totals[name] or {}
            totals[name] = sum
            for kind, amount in pairs(kinds) do sum[kind] = (sum[kind] or 0) + amount end
        end
    end
    if next(totals) == nil then return nil end -- earlier versions kept empty snapshots
    return totals
end

return Run
