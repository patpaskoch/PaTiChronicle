-- PaTiChronicle run report, tab "My performance": what you can be proud of (your achievements), your development
-- against your own earlier runs in this dungeon and role (Chronicle.Development), and where there is room left.
-- Redesign 2026-10-19: no mini bar charts — every value with its change in words and numbers. Better in the success
-- colour, worse only as a plain sentence (never red, never a ranking).
local _, ns = ...
local UI, L, Chronicle, Report = ns.UI, ns.UI.L, ns.Chronicle, ns.Report

local page = Report.pages.mine
local width = Report.CONTENT_WIDTH
local MAX_PROUD = 3
local MAX_ROOM = 2
local VALUE_X, CHANGE_X = 150, 250
local METRIC_TEXT = { time = "DEV_TIME", deaths = "DEV_DEATHS", aggro = "DEV_AGGRO" }

local portrait = Report.Portrait(page, 48)
portrait.ring:SetPoint("TOPLEFT", 0, -2)
local name = Report.Text(page, "Display")
name:SetPoint("TOPLEFT", portrait.ring, "TOPRIGHT", 14, -2)
local roleLine = Report.Text(page, "Body", "TextMuted")
roleLine:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
local runLine = Report.Text(page, "Caption", "TextMuted")
runLine:SetPoint("TOPLEFT", roleLine, "BOTTOMLEFT", 0, -3)

local y = -84
Report.Divider(page, y)
Report.SectionTitle(page, 0, y - 16, "SECTION_PROUD")
local missingNote = Report.MissingNote(page)
missingNote:SetPoint("TOPRIGHT", 0, y - 14)
local noAchievement = Report.Text(page, "Body", "TextMuted")
noAchievement:SetPoint("TOPLEFT", 0, y - 38)
UI.BindText(noAchievement, "NONE_MINE")
local proud = {}
local medallion = (width - 2 * 16) / 3
for index = 1, MAX_PROUD do
    local entry = Report.Medallion(page, medallion)
    entry:SetPoint("TOPLEFT", (index - 1) * (medallion + 16), y - 38)
    proud[index] = entry
end

y = y - 38 - Report.MEDALLION_HEIGHT - Report.GAP
Report.SectionTitle(page, 0, y, "SECTION_DEVELOPMENT")
local compared = Report.Text(page, "Caption", "TextMuted")
compared:SetPoint("TOPRIGHT", 0, y)
Report.Divider(page, y - 18)

local rows = {}
for index = 1, 3 do
    local row = CreateFrame("Frame", nil, page)
    row:SetSize(width, 44)
    row:SetPoint("TOPLEFT", 0, y - 26 - (index - 1) * 46)
    row.label = Report.Text(row, "Body", "TextMuted")
    row.label:SetPoint("TOPLEFT", 0, -4)
    row.value = Report.Text(row, "Heading", "Text")
    row.value:SetPoint("TOPLEFT", VALUE_X, -2)
    row.change = Report.Text(row, "Body", "Text")
    row.change:SetPoint("TOPLEFT", CHANGE_X, -4)
    row.change:SetWidth(width - CHANGE_X)
    row.change:SetJustifyH("LEFT")
    row.best = Report.Text(row, "Caption", "Accent")
    row.best:SetPoint("TOPLEFT", row.change, "BOTTOMLEFT", 0, -4)
    rows[index] = row
end

y = y - 26 - 3 * 46 - 4
Report.Divider(page, y)
Report.SectionTitle(page, 0, y - 16, "SECTION_ROOM")
local room = {}
for index = 1, MAX_ROOM do
    local line = Report.Text(page, "Body", "Text")
    line:SetPoint("TOPLEFT", 0, y - 36 - (index - 1) * 22)
    line:SetWidth(width)
    line:SetJustifyH("LEFT")
    room[index] = line
end

-- Why a value is missing: the run had gaps, the data was not readable, or (aggro) your role or the tank is unknown.
local function missingReason(run, metric)
    if metric == "time" then return "NOT_COUNTED" end
    if not run.complete then return "GAP" end
    if metric == "aggro" and (run.myRole == "NONE" or (run.myRole == "TANK" and not run.tank)) then return "ROLE" end
    return "DATA"
end

-- "2:29 faster than your average (26:42)", "1.8 less than your average", "like your average (0.2)".
local function changeText(row)
    local value, avg = row.value, row.avg
    if row.state == "few" then return L.DEV_FEW:format(Chronicle.MIN_COMPARE - row.earlier), "TextMuted" end
    local clock = row.metric == "time"
    local shownAvg = Report.Value(row.metric, avg)
    local difference = Report.Value(row.metric, math.abs(value - avg))
    if row.state == "better" then
        return (clock and L.CHANGE_TIME_BETTER or L.CHANGE_COUNT_BETTER):format(difference, shownAvg), "Success"
    elseif row.state == "worse" then
        return (clock and L.CHANGE_TIME_WORSE or L.CHANGE_COUNT_WORSE):format(difference, shownAvg), "TextMuted"
    end
    return L.CHANGE_SAME:format(shownAvg), "TextMuted"
end

local ROOM_TEXT = { time = "ROOM_TIME", deaths = "ROOM_DEATHS", aggro = "ROOM_AGGRO" }

Report.views.mine = function(report)
    local run, result = report.run, report.result
    local me = run.members[run.me] or { name = run.me }
    portrait:Set(run.me, run.myRole, report.units and report.units[run.me])
    name:SetText(run.me or "")
    Report.ClassColor(name, me.classFile)
    local parts = { Report.ClassName(me), L[Report.ROLE_TEXT[run.myRole] or "ROLE_NONE"],
        me.level and L.LEVEL:format(me.level) or nil }
    local line = {}
    for _, part in ipairs(parts) do if part then line[#line + 1] = part end end
    roleLine:SetText(table.concat(line, " · "))
    runLine:SetText(L.RUN_NUMBER:format(run.name or "", report.runNumber or 1))

    for index, entry in ipairs(proud) do
        if result.mine[index] then entry:Set(result.mine[index]) else entry:Hide() end
    end
    noAchievement:SetShown(#result.mine == 0)
    missingNote:Set(result.missing)

    local earlierRuns, roomLines = 0, {}
    for index, row in ipairs(rows) do
        local data = result.development[index]
        earlierRuns = math.max(earlierRuns, data.earlier or 0)
        row.label:SetText(L[METRIC_TEXT[data.metric]])
        row.value:SetText(Report.Value(data.metric, data.value))
        UI.Paint(row.value, "SetTextColor", data.value == nil and "TextMuted" or "Text")
        local text, color
        if data.state == "missing" then
            text, color = L["DEV_MISSING_" .. missingReason(run, data.metric)], "TextMuted"
        else
            text, color = changeText(data)
        end
        row.change:SetText(text)
        UI.Paint(row.change, "SetTextColor", color)
        row.best:SetText(data.best and L.BEST_HERE or "")
        if data.state == "worse" and #roomLines < MAX_ROOM then
            roomLines[#roomLines + 1] = L[ROOM_TEXT[data.metric]]:format(Report.Value(data.metric, data.value),
                Report.Value(data.metric, data.avg))
        end
    end
    compared:SetText(earlierRuns > 0 and L.COMPARED_WITH:format(earlierRuns) or "")
    if #roomLines == 0 then
        roomLines[1] = earlierRuns >= Chronicle.MIN_COMPARE and L.ROOM_NONE or L.ROOM_FEW
    end
    for index, text in ipairs(room) do
        text:SetText(roomLines[index] or "")
        UI.Paint(text, "SetTextColor", (#roomLines == 1 and index == 1 and roomLines[1] == L.ROOM_NONE)
            and "TextMuted" or "Text")
    end
end
