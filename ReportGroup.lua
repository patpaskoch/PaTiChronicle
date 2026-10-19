-- PaTiChronicle run report, tab "Group result" (owner 2026-10-19): the five members side by side as portraits
-- (owner 2026-10-19: no 3D characters, the portrait is steadier) — and below a calm result table with all of
-- them. Fixed order (tank, healer, damage), never sorted by values, no highlighted maximum, no winner. Values come
-- from Chronicle.PlayerRows; a missing value shows "n/a" with its reason, never 0. "Contribution" (damage,
-- healing, interrupts) stays switched off until C_DamageMeter is confirmed.
local _, ns = ...
local UI, L, Logic, Chronicle, Report = ns.UI, ns.UI.L, ns.Logic, ns.Chronicle, ns.Report

local page = Report.pages.group
local width = Report.CONTENT_WIDTH
local SLOT = width / 5
local FIGURE_H = 80 -- the portrait area above the name
local FIGURES_TOP = -30
local TABLE_TOP = -196
local ROW = 28 -- a little tighter than Report.ROW: five members, the total and the detail line fit the page
local NAME_COLUMN = 200
-- Survival columns: key, header key, right edge (x).
local COLUMNS = { { key = "deaths", text = "COL_DEATHS", right = 300 },
    { key = "deadTime", text = "COL_DEAD_TIME", right = 395, clock = true },
    { key = "attacked", text = "COL_ATTACKS", right = 510 },
    { key = "present", text = "COL_PRESENT", right = width, clock = true } }

local headline = Report.Text(page, "Heading", "Text")
headline:SetPoint("TOP", 0, -2)

-- Figures -------------------------------------------------------------------------------------------------------

local selected -- the member whose times the detail line shows
local slots = {}
for index = 1, 5 do
    local slot = CreateFrame("Button", nil, page)
    slot:SetSize(SLOT, 146)
    slot:SetPoint("TOPLEFT", (index - 1) * SLOT, FIGURES_TOP)
    slot.portrait = Report.Portrait(slot, 64)
    slot.portrait.ring:SetPoint("TOP", 0, -(FIGURE_H - 68) / 2)
    slot.name = Report.Text(slot, "Heading")
    slot.name:SetPoint("TOP", 0, -FIGURE_H - 8)
    slot.name:SetWidth(SLOT - 8)
    slot.name:SetWordWrap(false)
    slot.class = Report.Text(slot, "Body", "TextMuted")
    slot.class:SetPoint("TOP", slot.name, "BOTTOM", 0, -3)
    slot.class:SetWidth(SLOT - 8)
    slot.class:SetWordWrap(false)
    slot.role = Report.Text(slot, "Caption")
    slot.role:SetPoint("TOP", slot.class, "BOTTOM", 0, -3)
    slot.mark = slot:CreateTexture(nil, "ARTWORK")
    slot.mark:SetSize(40, 2)
    slot.mark:SetPoint("TOP", slot.role, "BOTTOM", 0, -6)
    UI.Paint(slot.mark, "SetColorTexture", "Accent")
    slots[index] = slot
end

-- Result table ------------------------------------------------------------------------------------------------

Report.SectionTitle(page, 0, TABLE_TOP, "SECTION_RESULT")
local category = "survival"
local categories = Report.TextTabs(page, {
    { id = "survival", text = "CAT_SURVIVAL" },
    { id = "contribution", text = "CAT_CONTRIBUTION", disabled = true, tip = "CAT_CONTRIBUTION_NA" },
}, function(id) category = id end, "Body")
categories:Layout(20)
categories.anchor:SetPoint("TOPRIGHT", page, "TOPRIGHT", -categories.width, TABLE_TOP + 6)
Report.Divider(page, TABLE_TOP - 22)

local header = CreateFrame("Frame", nil, page)
header:SetSize(width, 20)
header:SetPoint("TOPLEFT", 0, TABLE_TOP - 28)
for _, column in ipairs(COLUMNS) do
    local text = Report.Text(header, "Caption", "TextMuted")
    text:SetPoint("RIGHT", header, "LEFT", column.right, 0)
    UI.BindText(text, column.text)
end

local rows = {}
local function newRow(index, total)
    local row = CreateFrame("Button", nil, page)
    row:SetSize(width, ROW)
    if index % 2 == 0 and not total then row.tint = Report.RowTint(row) end
    row.bar = Report.MarkBar(row)
    row.name = Report.Text(row, total and "Heading" or "Body")
    row.name:SetPoint("LEFT", 6, 0)
    row.name:SetWidth(110)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.role = Report.Text(row, "Caption", "TextMuted")
    row.role:SetPoint("LEFT", 120, 0)
    row.role:SetWidth(NAME_COLUMN - 120)
    row.role:SetJustifyH("LEFT")
    row.cells = {}
    for columnIndex, column in ipairs(COLUMNS) do
        local cell = CreateFrame("Frame", nil, row)
        cell:SetSize(80, ROW)
        cell:SetPoint("RIGHT", row, "LEFT", column.right, 0)
        cell:EnableMouse(true) -- for the reason of an "n/a"
        cell.text = Report.Text(cell, total and "Heading" or "Body")
        cell.text:SetPoint("RIGHT")
        row.cells[columnIndex] = cell
    end
    return row
end
for index = 1, 5 do
    rows[index] = newRow(index)
    rows[index]:SetPoint("TOPLEFT", 0, TABLE_TOP - 50 - (index - 1) * ROW)
end
local totalLine = Report.Divider(page, TABLE_TOP - 50 - 5 * ROW - 2)
local totalRow = newRow(6, true)
totalRow:SetPoint("TOPLEFT", 0, TABLE_TOP - 50 - 5 * ROW - 4)

local detail = Report.Text(page, "Body", "Text")
detail:SetPoint("TOPLEFT", 0, TABLE_TOP - 50 - 6 * ROW - 14)
detail:SetWidth(width)
detail:SetJustifyH("LEFT")
local note = Report.Text(page, "Caption", "TextMuted")
note:SetPoint("BOTTOMLEFT", 0, 0)
note:SetWidth(width)
note:SetJustifyH("LEFT")
UI.BindText(note, "CONTRIBUTION_NOTE")

-- One cell: a number, a clock, "-" (nothing to show: 0 seconds dead, attacks of a tank) or "n/a" + reason.
local function fillCell(cell, column, value, reason)
    local text, color, tip
    color = "Text"
    if value == nil then
        if reason == "TANK" then text, color, tip = "-", "TextMuted", L.NA_TANK
        else text, color, tip = L.NA, "TextMuted", L["NA_" .. (reason or "DATA")] end
    elseif column.clock then
        text = value > 0 and Logic.Clock(value) or "-"
        color = value > 0 and "Text" or "TextMuted"
    else
        text = tostring(value)
    end
    cell.text:SetText(text)
    UI.Paint(cell.text, "SetTextColor", color)
    UI.SetTooltip(cell, tip)
end

local function times(list)
    if not list or #list == 0 then return nil end
    local out = {}
    for _, t in ipairs(list) do out[#out + 1] = Logic.Clock(t) end
    return table.concat(out, ", ")
end

local shown -- { rows, total, report }
-- The times of the selected member under the table ("Korr: deaths 14:05 · attacks 9:13").
local function fillDetail()
    local chosen
    for _, row in ipairs(shown and shown.rows or {}) do
        if row.name == selected then chosen = row end
    end
    for index, slot in ipairs(slots) do
        local row = shown and shown.rows[index]
        slot.mark:SetShown(row ~= nil and row.name == selected)
    end
    if not chosen then
        detail:SetText(L.DETAIL_HINT)
        UI.Paint(detail, "SetTextColor", "TextMuted")
        return
    end
    local parts = {}
    local deaths, attacks = times(chosen.deathTimes), times(chosen.attackTimes)
    if deaths then parts[#parts + 1] = L.DETAIL_DEATHS:format(deaths) end
    if attacks then parts[#parts + 1] = L.DETAIL_ATTACKS:format(attacks) end
    detail:SetText(("%s:  %s"):format(chosen.name, #parts > 0 and table.concat(parts, "  ·  ") or L.DETAIL_NONE))
    UI.Paint(detail, "SetTextColor", "Text")
end

function Report.SelectPlayer(name)
    selected = name
    fillDetail()
end

local function selectIndex(index)
    local row = shown and shown.rows[index]
    if row then Report.SelectPlayer(row.name) end
end
for index, row in ipairs(rows) do row:SetScript("OnClick", function() selectIndex(index) end) end
for index, slot in ipairs(slots) do slot:SetScript("OnClick", function() selectIndex(index) end) end

Report.views.group = function(report)
    local run = report.run
    local playerRows, total = Chronicle.PlayerRows(run, report.names)
    shown = { rows = playerRows, total = total, report = report }
    headline:SetText(L.GROUP_HEADLINE:format(run.name or "", Logic.Clock(report.result.summary.time), #report.names))
    for index, slot in ipairs(slots) do
        local row = playerRows[index]
        slot:SetShown(row ~= nil)
        if row then
            local unit = report.units and report.units[row.name]
            slot.portrait:Set(row.name, row.role, unit)
            slot.name:SetText(row.name)
            Report.ClassColor(slot.name, row.classFile)
            local className = Report.ClassName(row)
            slot.class:SetText(className and row.level and ("%s %d"):format(className, row.level) or className or "")
            slot.role:SetText(L[Report.ROLE_TEXT[row.role] or "ROLE_NONE"])
            UI.Paint(slot.role, "SetTextColor", Report.ROLE_COLOR[row.role] or "TextMuted")
        end
    end
    for index, tableRow in ipairs(rows) do
        local row = playerRows[index]
        tableRow:SetShown(row ~= nil)
        if row then
            tableRow.name:SetText(row.me and L.ROW_YOU:format(row.name) or row.name)
            Report.ClassColor(tableRow.name, row.classFile)
            tableRow.role:SetText(L[Report.ROLE_TEXT[row.role] or "ROLE_NONE"])
            tableRow.bar:SetShown(row.me)
            for columnIndex, column in ipairs(COLUMNS) do
                fillCell(tableRow.cells[columnIndex], column, row[column.key], row[column.key .. "Reason"])
            end
        end
    end
    totalRow.name:SetText(L.ROW_GROUP)
    UI.Paint(totalRow.name, "SetTextColor", "Text")
    totalRow.role:SetText("")
    for columnIndex, column in ipairs(COLUMNS) do
        local cell = totalRow.cells[columnIndex]
        if column.key == "present" then
            local deathsKnown = Chronicle.Reliable(run).deaths
            cell.text:SetText(deathsKnown and (run.wipes > 0 and L.WIPES:format(run.wipes) or L.WIPES_NONE) or L.NA)
            UI.Paint(cell.text, "SetTextColor", deathsKnown and "Text" or "TextMuted")
            UI.SetTooltip(cell, not deathsKnown and L.NA_DATA or nil)
        else
            fillCell(cell, column, total.known[column.key] and total[column.key] or nil, "DATA")
        end
    end
    totalLine:Show()
    categories:Select(category)
    if selected and not run.members[selected] then selected = nil end
    fillDetail()
end
