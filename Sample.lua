-- PaTiChronicle test mode: an example run (Deadmines, five players) that goes through the same rules as a real one
-- (Run.lua, Chronicle.lua), so the report shows what those rules give. Pure. Tested in tests/chronicle_spec.lua.
local _, ns = ...
local Run, Chronicle = ns.Run, ns.Chronicle
local Sample = {}
ns.Sample = Sample

local MEMBERS = {
    { name = "Arden", role = "TANK", classFile = "WARRIOR", level = 21 },
    { name = "Mira", role = "HEALER", classFile = "PRIEST", level = 20 },
    { name = "Kael", role = "DAMAGER", classFile = "MAGE", level = 20 },
    { name = "Korr", role = "DAMAGER", classFile = "HUNTER", level = 19 },
    { name = "Nyra", role = "DAMAGER", classFile = "ROGUE", level = 21 },
}
local ME = "Kael"
local START = 1000000 -- any epoch second; the report shows offsets only

-- Fights as { start, end } offsets in seconds; boss fights carry the boss name.
local FIGHTS = {
    { 15, 52 }, { 80, 121 }, { 160, 190 }, { 241, 289 }, { 330, 384, "Rhahk'Zor" }, { 430, 470 }, { 520, 571 },
    { 610, 655 }, { 700, 742 }, { 790, 868 }, { 905, 950 }, { 985, 1032, "Mr. Smite" }, { 1080, 1121 },
    { 1170, 1215 }, { 1262, 1300 }, { 1340, 1453, "Edwin VanCleef" },
}

-- The history before the example run: four earlier runs as a mage, best time 25:01, twice with this group.
local function history(group)
    local runs = {}
    for index, entry in ipairs({ { 1720, 1, 2 }, { 1610, 0, 2 }, { 1501, 0, 1 }, { 1580, 0, 2 } }) do
        runs[index] = { at = START - index * 86400, time = entry[1], counted = true, complete = true, size = 5,
            group = group, role = "DAMAGER", deaths = entry[2], groupDeaths = entry[2] + 1, aggro = entry[3] }
    end
    return runs
end

-- dungeonName: localized. Returns a report like the saved one: { run, result, size, names, sample = true }.
function Sample.Report(dungeonName)
    local run = Run.New({ key = "36", name = dungeonName }, START, { name = ME, role = "DAMAGER" })
    run.tank = "Arden"
    local names = {}
    for _, member in ipairs(MEMBERS) do
        Run.AddMember(run, member)
        names[#names + 1] = member.name
        Run.DeathState(run, member.name, false, false, START)
    end
    Run.Presence(run, names, START)
    for _, fight in ipairs(FIGHTS) do
        Run.FightStart(run, START + fight[1])
        if fight[3] then Run.BossStart(run) end
        Run.Threat(run, "Arden", 3, true, false, fight[1], START + fight[1])
        if fight[1] == 520 then
            Run.Threat(run, "Korr", 2, false, false, 553, START + 553)
            Run.Threat(run, "Korr", 0, false, false, 557, START + 557)
        end
        if fight[1] == 790 then
            Run.DeathState(run, "Nyra", true, false, START + 842)
            Run.DeathState(run, "Korr", true, false, START + 845)
            Run.DeathState(run, "Nyra", false, false, START + 881)
            Run.DeathState(run, "Korr", false, false, START + 887)
        end
        if fight[3] then Run.BossEnd(run, START + fight[2], fight[3], true) end
        Run.FightEnd(run, START + fight[2], fight[2])
    end
    Run.Threat(run, ME, 0, false, true, 1453, START + 1453)
    Run.Finish(run, START + 1453, "auto", 1453)

    local group = Run.GroupKey(names)
    local db = { runs = { ["36"] = history(group) }, bests = { ["36"] = { time = 1501 } },
        groupBests = { ["36"] = { [group] = 1501 } }, teams = { [group] = 2 }, streaks = { DAMAGER = 4 } }
    return { run = run, result = Chronicle.Evaluate(db, run, #names, names), size = #names, names = names,
        members = MEMBERS, sample = true }
end

return Sample
