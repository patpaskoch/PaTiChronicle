-- PaTiChronicle run report, tab "Timeline": the run as a strip with a time axis (fights as blocks, boss fights in
-- the accent colour, one symbol per kind), the list of what happened with aligned times, and on the right the
-- details of the chosen event (its fight, what else happened in it). Facts only: who died is named, causes never;
-- aggro moments carry a name only when they were yours (owner decisions 2026-10-19).
local _, ns = ...
local UI, L, Logic, Run, Report = ns.UI, ns.UI.L, ns.Logic, ns.Run, ns.Report

local TRACK = 12 -- strip height
local MARK = 16 -- symbol size above the strip
local CLUSTER = 10 -- symbols of one kind closer than this (px) become one with "×n"
local TICK = 300 -- a label every 5 minutes
local LIST_WIDTH, DETAIL_X = 380, 410
local MAX_ROWS = 10

local function eventText(entry)
    if entry.kind == "boss" then return L.EVENT_BOSS:format(entry.boss or "?") end
    if entry.kind == "death" then return L.EVENT_DEATH:format(entry.name or "?") end
    if entry.kind == "wipe" then return L.EVENT_WIPE end
    if entry.kind == "aggro" then
        return (entry.mine and L.EVENT_AGGRO_MINE or L.EVENT_AGGRO_GROUP) .. " · "
            .. L.SECONDS:format(entry.seconds or 0)
    end
    return entry.text or ""
end

local function pooled(pool, index, create)
    if not pool[index] then pool[index] = create() end
    return pool[index]
end

-- The strip: a track over the whole run, a block per fight, symbols for bosses, deaths and aggro moments
-- (clustered when close), a time axis below. onMark(entry) is called when a symbol is clicked.
function Report.Strip(parent, width, onMark)
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetSize(width, MARK + 4 + TRACK + 18)
    local track = strip:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", 0, -MARK - 4)
    track:SetSize(width, TRACK)
    UI.Paint(track, "SetColorTexture", "Panel")
    local blocks, marks, ticks = {}, {}, {}

    local function newMark()
        local mark = CreateFrame("Button", nil, strip)
        mark:SetSize(MARK, MARK)
        mark.icon = mark:CreateTexture(nil, "OVERLAY")
        mark.icon:SetAllPoints()
        mark.more = Report.Text(mark, "Caption", "TextMuted")
        mark.more:SetPoint("LEFT", mark, "RIGHT", 1, 0)
        return mark
    end

    function strip.Set(_, run)
        local total = math.max(1, Run.Duration(run, run.now)) -- run.now: set by the caller for a running run
        local function x(seconds) return math.min(width, math.max(0, seconds / total * width)) end
        for index, fight in ipairs(run.fights) do
            local texture = pooled(blocks, index, function() return strip:CreateTexture(nil, "ARTWORK") end)
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", track, "TOPLEFT", x(fight.s), 0)
            texture:SetSize(math.max(2, x(fight.e or total) - x(fight.s)), TRACK)
            if fight.boss then UI.Paint(texture, "SetColorTexture", "Accent")
            else UI.Paint(texture, "SetColorTexture", "TextMuted", 0.5) end
            texture:Show()
        end
        for index = #run.fights + 1, #blocks do blocks[index]:Hide() end

        -- Time axis: 0:00, every 5 minutes, the end.
        local labels = { 0 }
        for t = TICK, total - TICK / 3, TICK do labels[#labels + 1] = t end
        labels[#labels + 1] = total
        for index, t in ipairs(labels) do
            local text = pooled(ticks, index, function() return Report.Text(strip, "Caption", "TextMuted") end)
            text:ClearAllPoints()
            local anchor = index == 1 and "TOPLEFT" or index == #labels and "TOPRIGHT" or "TOP"
            text:SetPoint(anchor, track, "BOTTOMLEFT", x(t), -3)
            text:SetText(Logic.Clock(t))
            text:Show()
        end
        for index = #labels + 1, #ticks do ticks[index]:Hide() end

        local count, last = 0, nil
        for _, entry in ipairs(run.events) do
            local icon = entry.kind ~= "wipe" and Report.ICONS[entry.kind]
            if icon then
                local position = x(entry.t)
                if last and last.kind == entry.kind and position - last.position < CLUSTER then
                    last.count = last.count + 1
                    last.frame.more:SetText(L.MARK_MORE:format(last.count))
                else
                    count = count + 1
                    local frame = pooled(marks, count, newMark)
                    frame:ClearAllPoints()
                    frame:SetPoint("BOTTOM", track, "TOPLEFT", position, 3)
                    frame.icon:SetTexture(icon)
                    frame.more:SetText("")
                    local title = Logic.Clock(entry.t) .. "  " .. eventText(entry)
                    UI.SetTooltip(frame, function() return { title, L.EVENT_FIGHT:format(entry.fight) } end)
                    frame:SetScript("OnClick", function() if onMark then onMark(entry) end end)
                    frame:Show()
                    last = { kind = entry.kind, position = position, count = 1, frame = frame }
                end
            end
        end
        for index = count + 1, #marks do marks[index]:Hide() end
    end
    return strip
end

-- Tab "Timeline" ------------------------------------------------------------------------------------------------

local page = Report.pages.timeline
local width = Report.CONTENT_WIDTH
local selected -- the chosen entry (detail column)
local choose -- defined below
local strip = Report.Strip(page, width, function(entry) choose(entry) end)
strip:SetPoint("TOPLEFT", 0, -2)

local summary = Report.Text(page, "Body", "Text")
summary:SetPoint("TOPLEFT", 0, -64)
local legend = Report.Text(page, "Caption", "TextMuted")
legend:SetPoint("TOPRIGHT", 0, -66)
UI.BindText(legend, function()
    local function icon(path) return ("|T%s:12:12|t"):format(path) end
    return ("%s %s   %s %s   %s %s"):format(icon(Report.ICONS.boss), L.LEGEND_BOSS, icon(Report.ICONS.death),
        L.LEGEND_DEATH, icon(Report.ICONS.aggro), L.LEGEND_AGGRO)
end)
local TOP = -90
Report.Divider(page, TOP)

local headTime = Report.Text(page, "Caption", "TextMuted")
headTime:SetPoint("TOPRIGHT", page, "TOPLEFT", 48, TOP - 10)
UI.BindText(headTime, "COL_TIME")
Report.SectionTitle(page, 82, TOP - 10, "COL_EVENT")
Report.SectionTitle(page, DETAIL_X, TOP - 10, "SECTION_DETAIL")
local column = page:CreateTexture(nil, "ARTWORK")
column:SetPoint("TOPLEFT", DETAIL_X - 16, TOP - 8)
column:SetSize(1, MAX_ROWS * Report.ROW + 24)
UI.Paint(column, "SetColorTexture", "Border")

local rows = {}
for index = 1, MAX_ROWS do
    local row = CreateFrame("Button", nil, page)
    row:SetSize(LIST_WIDTH, Report.ROW)
    row:SetPoint("TOPLEFT", 0, TOP - 28 - (index - 1) * Report.ROW)
    row.tint = Report.RowTint(row)
    row.bar = Report.MarkBar(row)
    row.split = row:CreateTexture(nil, "ARTWORK") -- a new fight starts with this row
    row.split:SetPoint("TOPLEFT")
    row.split:SetSize(LIST_WIDTH, 1)
    UI.Paint(row.split, "SetColorTexture", "Border")
    row.time = Report.Text(row, "Body", "TextMuted")
    row.time:SetPoint("RIGHT", row, "LEFT", 48, 0)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", 58, 0)
    row.text = Report.Text(row, "Body", "Text")
    row.text:SetPoint("LEFT", 82, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    rows[index] = row
end
local hiddenNote = Report.Text(page, "Caption", "TextMuted")
hiddenNote:SetPoint("TOPLEFT", 82, TOP - 28 - MAX_ROWS * Report.ROW - 2)

local detail = { lines = {} }
detail.icon = page:CreateTexture(nil, "ARTWORK")
detail.icon:SetSize(16, 16)
detail.icon:SetPoint("TOPLEFT", DETAIL_X, TOP - 34)
detail.title = Report.Text(page, "Heading", "Text")
detail.title:SetPoint("TOPLEFT", DETAIL_X + 22, TOP - 32)
detail.title:SetWidth(width - DETAIL_X - 22)
detail.title:SetJustifyH("LEFT")
detail.title:SetWordWrap(false)
for index = 1, 8 do
    local line = Report.Text(page, "Body", index == 1 and "TextMuted" or "Text")
    line:SetPoint("TOPLEFT", DETAIL_X, TOP - 62 - (index - 1) * 22)
    line:SetWidth(width - DETAIL_X)
    line:SetJustifyH("LEFT")
    line:SetWordWrap(false)
    detail.lines[index] = line
end

local footer = Report.Text(page, "Caption", "TextMuted")
footer:SetPoint("BOTTOMLEFT", 0, 0)

local shownRun, entries = nil, {}

local function endEntry(run)
    local text = L.EVENT_RUNNING
    if run.state == "completed" then text = run.how == "manual" and L.EVENT_END_MANUAL or L.EVENT_END_AUTO
    elseif run.state == "aborted" then text = L.EVENT_ABORTED end
    return { kind = "end", t = Run.Duration(run, run.now), text = text, fight = #run.fights }
end

-- The chosen event: when, its fight (start, end, length, wipe or boss), what else happened in that fight.
local function fillDetail()
    local entry = selected
    for _, line in ipairs(detail.lines) do line:SetText("") end
    if not entry then detail.title:SetText(""); detail.icon:Hide(); return end
    detail.icon:SetTexture(Report.ICONS[entry.kind])
    detail.icon:SetShown(Report.ICONS[entry.kind] ~= nil)
    detail.title:SetText(eventText(entry))
    local lines = { L.DETAIL_WHEN:format(Logic.Clock(entry.t), entry.fight or 0) }
    local fight = shownRun.fights[entry.fight]
    if fight and entry.kind ~= "end" then
        local stop = fight.e or Run.Duration(shownRun, shownRun.now)
        lines[#lines + 1] = L.DETAIL_FIGHT:format(Logic.Clock(fight.s), Logic.Clock(stop), Logic.Clock(stop - fight.s))
        if fight.wipe then lines[#lines + 1] = L.DETAIL_WIPE
        elseif fight.boss then lines[#lines + 1] = L.DETAIL_BOSS_FIGHT end
        local others = {}
        for _, other in ipairs(shownRun.events) do
            if other ~= entry and other.fight == entry.fight and other.kind ~= "wipe" then
                others[#others + 1] = ("%s  %s"):format(Logic.Clock(other.t), eventText(other))
            end
        end
        lines[#lines + 1] = #others > 0 and L.DETAIL_SAME_FIGHT or L.DETAIL_ALONE
        for _, text in ipairs(others) do
            if #lines < #detail.lines then lines[#lines + 1] = text end
        end
    end
    for index, text in ipairs(lines) do detail.lines[index]:SetText(text) end
end

local function fillRows()
    local hidden = math.max(0, #entries - MAX_ROWS)
    for index, row in ipairs(rows) do
        -- Too many: the first rows are dropped, the end of the run always stays.
        local entry = entries[index + hidden]
        local previous = entries[index + hidden - 1]
        row:SetShown(entry ~= nil)
        if entry then
            row.time:SetText(Logic.Clock(entry.t))
            row.icon:SetTexture(Report.ICONS[entry.kind])
            row.icon:SetShown(Report.ICONS[entry.kind] ~= nil)
            row.text:SetText(eventText(entry))
            row.split:SetShown(index > 1 and previous ~= nil and previous.fight ~= entry.fight)
            row.tint:SetShown(entry == selected)
            row.bar:SetShown(entry == selected)
            row:SetScript("OnClick", function() choose(entry) end)
        end
    end
    hiddenNote:SetText(hidden > 0 and L.TIMELINE_HIDDEN:format(hidden) or "")
end

choose = function(entry)
    selected = entry
    fillRows()
    fillDetail()
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
    shownRun = run
    strip:Set(run)
    local fightTime, bosses = combatTime(run)
    local deaths, aggro = 0, 0
    entries = {}
    for _, entry in ipairs(run.events) do
        if entry.kind ~= "wipe" then entries[#entries + 1] = entry end
        if entry.kind == "death" then deaths = deaths + 1 end
        if entry.kind == "aggro" then aggro = aggro + 1 end
    end
    local finish = endEntry(run)
    entries[#entries + 1] = finish
    summary:SetText(L.TIMELINE_SUMMARY:format(#run.fights, bosses, Logic.Clock(fightTime), deaths, aggro))
    -- Default: the most telling entry — the first death, else the end of the run.
    selected = finish
    for _, entry in ipairs(entries) do
        if entry.kind == "death" then selected = entry; break end
    end
    fillRows()
    fillDetail()
    footer:SetText(L.TIMELINE_FOOTER:format(run.complete and L.YES or L.NO,
        report.result.summary.counted and L.YES or L.NO, report.size or 0))
end
