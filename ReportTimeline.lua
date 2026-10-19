-- PaTiChronicle run report, tab "Timeline": the run as a strip (fights as blocks, boss fights in the accent colour,
-- marks for deaths and aggro moments) and the list of what happened, with time and fight number. Facts only: who
-- died is named, causes never; aggro moments carry a name only when they were yours (owner decision 2026-10-19).
local _, ns = ...
local UI, L, Logic, Run, Report = ns.UI, ns.UI.L, ns.Logic, ns.Run, ns.Report

local TRACK = 8 -- strip height
local MARK = 12 -- icon size above the strip
local MAX_ROWS = 11
local ROW_HEIGHT = 20

local function eventText(entry)
    if entry.kind == "boss" then return L.EVENT_BOSS:format(entry.boss or "?"), L.EVENT_FIGHT:format(entry.fight) end
    if entry.kind == "death" then return L.EVENT_DEATH:format(entry.name or "?"), L.EVENT_FIGHT:format(entry.fight) end
    if entry.kind == "wipe" then return L.EVENT_WIPE, L.EVENT_FIGHT:format(entry.fight) end
    if entry.kind == "aggro" then
        return entry.mine and L.EVENT_AGGRO_MINE or L.EVENT_AGGRO_GROUP,
            L.EVENT_AGGRO_DETAIL:format(entry.fight, entry.seconds or 0)
    end
    return entry.text or "", ""
end

-- The strip: a track over the whole run, a block per fight, marks for bosses, deaths and aggro moments.
function Report.Strip(parent, width)
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetSize(width, MARK + TRACK + 16)
    local track = strip:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", 0, -MARK - 2)
    track:SetSize(width, TRACK)
    UI.Paint(track, "SetColorTexture", "Panel")
    local startText = Report.Text(strip, UI.Fonts.Label, "TextMuted")
    startText:SetPoint("TOPLEFT", track, "BOTTOMLEFT", 0, -2)
    startText:SetText("0:00")
    local endText = Report.Text(strip, UI.Fonts.Label, "TextMuted")
    endText:SetPoint("TOPRIGHT", track, "BOTTOMRIGHT", 0, -2)
    local blocks, marks = {}, {}

    local function block(index)
        if not blocks[index] then blocks[index] = strip:CreateTexture(nil, "ARTWORK") end
        return blocks[index]
    end
    local function mark(index)
        local frame = marks[index]
        if not frame then
            frame = CreateFrame("Frame", nil, strip)
            frame:SetSize(MARK, MARK)
            frame:EnableMouse(true) -- for the tooltip
            frame.icon = frame:CreateTexture(nil, "OVERLAY")
            frame.icon:SetAllPoints()
            marks[index] = frame
        end
        return frame
    end

    function strip.Set(_, run)
        local total = math.max(1, Run.Duration(run, run.now)) -- run.now: set by the caller for a running run
        endText:SetText(Logic.Clock(total))
        local function x(seconds) return math.min(width, math.max(0, seconds / total * width)) end
        for index, fight in ipairs(run.fights) do
            local texture, stop = block(index), fight.e or total
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", track, "TOPLEFT", x(fight.s), 0)
            texture:SetSize(math.max(2, x(stop) - x(fight.s)), TRACK)
            if fight.boss then UI.Paint(texture, "SetColorTexture", "Accent")
            else UI.Paint(texture, "SetColorTexture", "TextMuted", 0.55) end
            texture:Show()
        end
        for index = #run.fights + 1, #blocks do blocks[index]:Hide() end
        local count = 0
        for _, entry in ipairs(run.events) do
            local icon = Report.ICONS[entry.kind]
            if icon then
                count = count + 1
                local frame = mark(count)
                frame:ClearAllPoints()
                frame:SetPoint("BOTTOM", track, "TOPLEFT", x(entry.t), 1)
                frame.icon:SetTexture(icon)
                local text, detail = eventText(entry)
                local title = Logic.Clock(entry.t) .. "  " .. text
                UI.SetTooltip(frame, function() return { title, detail } end)
                frame:Show()
            end
        end
        for index = count + 1, #marks do marks[index]:Hide() end
    end
    return strip
end

-- Tab "Timeline" ------------------------------------------------------------------------------------------------

local page = Report.pages.timeline
local width = Report.CONTENT_WIDTH
local strip = Report.Strip(page, width)
strip:SetPoint("TOPLEFT", 0, -UI.Spacing.SM)

local legend = Report.Text(page, UI.Fonts.Label, "TextMuted")
legend:SetPoint("TOPLEFT", 0, -UI.Spacing.SM - MARK - TRACK - 22)
local function legendText()
    local function icon(path) return ("|T%s:12:12|t"):format(path) end
    return ("%s %s   %s %s   %s %s"):format(icon(Report.ICONS.boss), L.LEGEND_BOSS, icon(Report.ICONS.death),
        L.LEGEND_DEATH, icon(Report.ICONS.aggro), L.LEGEND_AGGRO)
end
UI.BindText(legend, legendText)

local summary = Report.Text(page, UI.Fonts.Text, "Text")
summary:SetPoint("TOPLEFT", legend, "BOTTOMLEFT", 0, -UI.Spacing.SM)

local separatorLine = page:CreateTexture(nil, "ARTWORK")
separatorLine:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -UI.Spacing.SM)
separatorLine:SetSize(width, 1)
UI.Paint(separatorLine, "SetColorTexture", "Border")

local rows = {}
for index = 1, MAX_ROWS do
    local row = CreateFrame("Frame", nil, page)
    row:SetSize(width, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", separatorLine, "BOTTOMLEFT", 0, -UI.Spacing.SM - (index - 1) * ROW_HEIGHT)
    row.time = Report.Text(row, UI.Fonts.Text, "TextMuted")
    row.time:SetPoint("LEFT")
    row.time:SetWidth(52)
    row.time:SetJustifyH("RIGHT")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 60, 0)
    row.text = Report.Text(row, UI.Fonts.Title, "Text")
    row.text:SetPoint("LEFT", 82, 0)
    row.detail = Report.Text(row, UI.Fonts.Text, "TextMuted")
    row.detail:SetPoint("RIGHT")
    rows[index] = row
end

local footer = Report.Text(page, UI.Fonts.Label, "TextMuted")
footer:SetPoint("BOTTOMLEFT", 0, 0)

local function endEntry(run)
    local text = L.EVENT_RUNNING
    if run.state == "completed" then text = run.how == "manual" and L.EVENT_END_MANUAL or L.EVENT_END_AUTO
    elseif run.state == "aborted" then text = L.EVENT_ABORTED end
    return { kind = "end", t = Run.Duration(run, run.now), text = text }
end

local function combatTime(run)
    local total, bosses = 0, 0
    for _, fight in ipairs(run.fights) do
        total = total + math.max(0, (fight.e or fight.s) - fight.s)
        if fight.boss then bosses = bosses + 1 end
    end
    return total, bosses
end

Report.views.timeline = function(report)
    local run = report.run
    strip:Set(run)
    local fightTime, bosses = combatTime(run)
    summary:SetText(L.TIMELINE_SUMMARY:format(#run.fights, bosses, Logic.Clock(fightTime)))
    local entries = {}
    for _, entry in ipairs(run.events) do entries[#entries + 1] = entry end
    entries[#entries + 1] = endEntry(run)
    local hidden = math.max(0, #entries - MAX_ROWS)
    for index, row in ipairs(rows) do
        -- Too many: the first rows are dropped, the end of the run always stays.
        local entry = entries[index + hidden]
        if entry then
            local text, detail = eventText(entry)
            row.time:SetText(Logic.Clock(entry.t))
            row.icon:SetTexture(Report.ICONS[entry.kind])
            row.icon:SetShown(Report.ICONS[entry.kind] ~= nil)
            row.text:SetText(text)
            row.detail:SetText(detail)
            row:Show()
        else
            row:Hide()
        end
    end
    local yes, no = L.YES, L.NO
    footer:SetText(L.TIMELINE_FOOTER:format(run.complete and yes or no,
        report.result.summary.counted and yes or no, report.size or 0)
        .. (hidden > 0 and ("   " .. L.TIMELINE_HIDDEN:format(hidden)) or ""))
end
