-- PaTiChronicle run report, tab "My performance": your achievements in this run and your development against your
-- own earlier runs in this dungeon and role (Chronicle.Development). Better shows in the success colour, worse only
-- as a plain "above your average" — never red, never a ranking (owner decision 2026-10-19).
local _, ns = ...
local UI, L, Logic, Chronicle, Report = ns.UI, ns.UI.L, ns.Logic, ns.Chronicle, ns.Report

local MAX_ACHIEVEMENTS = 4
local BAR_WIDTH, BAR_GAP, BAR_MAX = 6, 2, 16 -- the small history bars (last runs)
local STATE_COLOR = { better = "Success", same = "TextMuted", worse = "TextMuted", few = "TextMuted",
    missing = "TextMuted" }

local page = Report.pages.mine
local width = Report.CONTENT_WIDTH

local portrait = Report.Portrait(page, 40)
portrait.ring:SetPoint("TOPLEFT", 0, -UI.Spacing.SM)
local name = Report.Text(page, Report.FONT_LARGE)
name:SetPoint("TOPLEFT", portrait.ring, "TOPRIGHT", UI.Spacing.MD, -2)
local roleLine = Report.Text(page, UI.Fonts.Text, "TextMuted")
roleLine:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
local runLine = Report.Text(page, UI.Fonts.Text, "TextMuted")
runLine:SetPoint("TOPLEFT", roleLine, "BOTTOMLEFT", 0, -2)

local y = -76
local achievementsTitle = Report.SectionTitle(page, 0, y)
UI.BindText(achievementsTitle, "SECTION_ACHIEVEMENTS")
local noAchievement = Report.Text(page, UI.Fonts.Text, "TextMuted")
noAchievement:SetPoint("TOPLEFT", 0, y - 18)
UI.BindText(noAchievement, "NONE_MINE")
local achievements = {}
for index = 1, MAX_ACHIEVEMENTS do
    local entry = Report.Achievement(page, width)
    entry:SetPoint("TOPLEFT", 0, y - 18 - (index - 1) * 32)
    achievements[index] = entry
end

y = y - 18 - MAX_ACHIEVEMENTS * 32 - UI.Spacing.MD
local developmentTitle = Report.SectionTitle(page, 0, y)
UI.BindText(developmentTitle, "SECTION_DEVELOPMENT")
local lastRuns = Report.Text(page, UI.Fonts.Label, "TextMuted")
lastRuns:SetPoint("TOPRIGHT", 0, y)
UI.BindText(lastRuns, function() return L.LAST_RUNS:format(Chronicle.TREND_RUNS) end)

local METRIC_TEXT = { time = "DEV_TIME", deaths = "DEV_DEATHS", aggro = "DEV_AGGRO" }
local rows = {}
for index = 1, 3 do
    local row = CreateFrame("Frame", nil, page)
    row:SetSize(width, 34)
    row:SetPoint("TOPLEFT", 0, y - 18 - (index - 1) * 36)
    row.label = Report.Text(row, UI.Fonts.Text, "Text")
    row.label:SetPoint("TOPLEFT", 0, -2)
    row.value = Report.Text(row, UI.Fonts.Title, "Text")
    row.value:SetPoint("TOPLEFT", 150, -2)
    row.avg = Report.Text(row, UI.Fonts.Text, "TextMuted")
    row.avg:SetPoint("TOPLEFT", 240, -2)
    row.state = Report.Text(row, UI.Fonts.Label, "TextMuted")
    row.state:SetPoint("TOPLEFT", 240, -18)
    row.bars = {}
    for bar = 1, Chronicle.TREND_RUNS do
        local texture = row:CreateTexture(nil, "ARTWORK")
        texture:SetWidth(BAR_WIDTH)
        texture:SetPoint("BOTTOMRIGHT", row, "TOPRIGHT",
            -(Chronicle.TREND_RUNS - bar) * (BAR_WIDTH + BAR_GAP), -BAR_MAX - 2)
        row.bars[bar] = texture
    end
    local line = row:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT")
    line:SetSize(width, 1)
    UI.Paint(line, "SetColorTexture", "Border")
    rows[index] = row
end

local missingNote = Report.MissingNote(page)
missingNote:SetPoint("BOTTOMLEFT", 0, 0)

local function show(metric, value)
    if value == nil then return "-" end
    if metric == "time" then return Logic.Clock(value) end
    if math.floor(value) == value then return tostring(value) end
    return (("%.1f"):format(value):gsub("%.", L.DECIMAL))
end

-- The last runs as small bars (the newest = this run, in the accent colour); taller = more (time, deaths, aggro).
local function fillBars(row, trend)
    local most = 0
    for _, value in ipairs(trend) do most = math.max(most, value) end
    local first = Chronicle.TREND_RUNS - #trend
    for index, texture in ipairs(row.bars) do
        local value = trend[index - first]
        if value then
            texture:SetHeight(math.max(2, most > 0 and value / most * BAR_MAX or 2))
            UI.Paint(texture, "SetColorTexture", index == Chronicle.TREND_RUNS and "Accent" or "TextMuted", 0.8)
            texture:Show()
        else
            texture:Hide()
        end
    end
end

local function stateText(row, reason)
    if row.state == "missing" then return L["DEV_MISSING_" .. reason] end
    if row.state == "few" then return L.DEV_FEW:format(Chronicle.MIN_COMPARE - row.earlier) end
    return L["DEV_" .. row.state:upper()]
end

-- Why a value is missing: the run had gaps, the data was not readable, or (aggro) your role is unknown.
local function missingReason(run, metric)
    if metric == "time" then return "NOT_COUNTED" end
    if not run.complete then return "GAP" end
    if metric == "aggro" and (run.myRole == "NONE" or (run.myRole == "TANK" and not run.tank)) then return "ROLE" end
    return "DATA"
end

Report.views.mine = function(report)
    local run, result = report.run, report.result
    local me = run.members[run.me] or { name = run.me }
    portrait:Set(run.me, run.myRole, report.units and report.units[run.me])
    name:SetText(run.me or "")
    Report.ClassColor(name, me.classFile)
    local roleText = L[Report.ROLE_TEXT[run.myRole] or "ROLE_NONE"]
    local levelClass = Report.LevelClass(me)
    roleLine:SetText(levelClass ~= "" and ("%s · %s"):format(roleText, levelClass) or roleText)
    runLine:SetText(L.RUN_NUMBER:format(run.name or "", report.runNumber or 1))

    for index, entry in ipairs(achievements) do
        if result.mine[index] then entry:Set(result.mine[index]) else entry:Hide() end
    end
    noAchievement:SetShown(#result.mine == 0)

    for index, row in ipairs(rows) do
        local data = result.development[index]
        row.label:SetText(L[METRIC_TEXT[data.metric]])
        row.value:SetText(show(data.metric, data.value))
        row.avg:SetText(data.avg and data.state ~= "few" and data.state ~= "missing"
            and L.DEV_AVERAGE:format(show(data.metric, data.avg)) or "")
        row.state:SetText(stateText(data, missingReason(run, data.metric)))
        UI.Paint(row.state, "SetTextColor", STATE_COLOR[data.state] or "TextMuted")
        fillBars(row, data.value ~= nil and data.trend or {})
    end
    missingNote:Set(result.missing)
end
