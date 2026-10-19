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

-- instance: { key, name } (key = instance ID or name); me: { name, role } (role: TANK/HEALER/DAMAGER/NONE).
function Run.New(instance, now, me)
    return { key = instance.key, name = instance.name, start = now, state = "running", complete = true,
        me = me.name, myRole = me.role or "NONE", members = {}, fights = {}, events = {}, deaths = {},
        wipes = 0, aggro = { mine = 0, others = 0 }, open = {},
        data = { deaths = false, deathsSecret = false, threat = false, threatSecret = false, bosses = false } }
end

-- member: { name, role, classFile, className, level }. Joins keep their first entry; facts are filled in later.
function Run.AddMember(run, member)
    local entry = run.members[member.name]
    if not entry then
        entry = { name = member.name }
        run.members[member.name] = entry
    end
    for key, value in pairs(member) do
        if entry[key] == nil then entry[key] = value end
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

-- clock: GetTime() (seconds, fractions), used only to time aggro moments in memory.
local function closeAggro(run, name, clock, now)
    local open = run.open[name]
    if not open then return end
    run.open[name] = nil
    local seconds = clock - open.since
    if seconds < Run.AGGRO_SECONDS then return end
    if open.mine then run.aggro.mine = run.aggro.mine + 1 else run.aggro.others = run.aggro.others + 1 end
    -- Only your own moments carry a name: the others' are never put on a person (owner decision).
    event(run, now - seconds, "aggro", { mine = open.mine, seconds = math.floor(seconds + 0.5) })
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
    if not dead or wasDead then return end
    run.deaths[name] = (run.deaths[name] or 0) + 1
    event(run, now, "death", { name = name })
    local fight = currentFight(run)
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

function Run.Finish(run, now, how, clock)
    Run.FightEnd(run, now, clock or 0)
    run.state, run.finish, run.how = "completed", now, how
    return run
end

function Run.Abort(run, now, reason)
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

return Run
