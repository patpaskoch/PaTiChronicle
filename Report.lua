-- PaTiChronicle run report: the main window with four tabs — Overview (the moment the run is done), Group result
-- (ReportGroup.lua), My performance (ReportMine.lua), Timeline (ReportTimeline.lua). Redesign after the owner's
-- approval of 2026-10-19: a calm page instead of a dashboard — five type levels, one grid, one strong element per
-- tab, text tabs instead of buttons, no boxes inside the page. No ranking, no winner, no score.
-- Display only, no secure frames. Colours only from PaTiShared tokens (all themes).
local _, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic
local Report = { views = {} }
ns.Report = Report

-- Grid ---------------------------------------------------------------------------------------------------------
Report.WIDTH, Report.HEIGHT = 640, 560
Report.PAD = 20 -- window edge
Report.GAP = 24 -- between sections
Report.ROW = 30 -- table and list rows
Report.CONTENT_WIDTH = Report.WIDTH - 2 * Report.PAD
local TAB_TOP = -UI.Sizes.HeaderHeight - 12
local TAB_HEIGHT = 26
local CONTENT_TOP = TAB_TOP - TAB_HEIGHT - 18
Report.CONTENT_HEIGHT = Report.HEIGHT + CONTENT_TOP - Report.PAD

-- Five type levels, Blizzard font objects only (they carry the client's CJK fallbacks); a missing one falls back
-- to the next smaller level.
local function font(...)
    for index = 1, select("#", ...) do
        local name = select(index, ...)
        if _G[name] then return name end
    end
    return UI.Fonts.Title
end
Report.FONT = {
    Display = font("GameFontNormalHuge", "GameFontNormalLarge"),
    Hero = font("NumberFontNormalHuge", "GameFontHighlightHuge", "GameFontNormalHuge"),
    Heading = font("GameFontHighlightLarge", "GameFontNormalLarge"),
    Body = font("GameFontHighlight", "GameFontHighlightSmall"),
    Caption = font("GameFontNormalSmall"),
}

Report.ROLE_COLOR = { TANK = "Mana", HEALER = "Success", DAMAGER = "Danger" }
Report.ROLE_TEXT = { TANK = "ROLE_TANK", HEALER = "ROLE_HEALER", DAMAGER = "ROLE_DAMAGER" }
-- One symbol per kind, everywhere (raid marker textures: verified in this client). Their own colours carry the
-- meaning: skull = boss, red cross = death, orange circle = aggro (the green triangle read as "good").
Report.ICONS = { boss = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
    death = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    wipe = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    aggro = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2" }

local window = UI.CreateWindow("PaTiChronicleFrame", "PaTiChronicle", Report.WIDTH, Report.HEIGHT)
window:SetCombatMovable(true) -- no secure children
window:SetFrameStrata("HIGH")
window:Hide()
tinsert(UISpecialFrames, "PaTiChronicleFrame") -- Esc closes the report
Report.window = window
-- A page to read: here the opacity setting is the real cover (100 % = the world does not shine through), not a
-- share of the theme's slightly transparent window colour.
function window.ApplyOpacity(self)
    local r, g, b = UI.Color("Background")
    self:SetBackdropColor(r, g, b, UI.ClampOpacity(self.db and self.db.opacity))
end

-- Building blocks ----------------------------------------------------------------------------------------------

-- level: a Report.FONT key.
function Report.Text(parent, level, color)
    local text = parent:CreateFontString(nil, "OVERLAY", Report.FONT[level] or Report.FONT.Body)
    UI.Paint(text, "SetTextColor", color or "Text")
    return text
end

-- A small upper-case section title.
function Report.SectionTitle(parent, x, y, key)
    local text = Report.Text(parent, "Caption", "TextMuted")
    text:SetPoint("TOPLEFT", x, y)
    if key then UI.BindText(text, key) end
    return text
end

-- One quiet line over the whole width.
function Report.Divider(parent, y, width, x)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", x or 0, y)
    line:SetSize(width or Report.CONTENT_WIDTH, 1)
    UI.Paint(line, "SetColorTexture", "Border")
    return line
end

-- Text tabs: the word itself and an accent line under the active one, no box (also the category switch).
-- items: { { id, text (L key), disabled?, tip? } }; onSelect(id). Place with tabs.anchor, then tabs:Layout(gap).
function Report.TextTabs(parent, items, onSelect, level)
    local tabs, current = { buttons = {}, gap = 28 }, nil
    local function paint()
        for _, item in ipairs(items) do
            local button = tabs.buttons[item.id]
            local active, hovered = item.id == current, button:IsMouseOver()
            local color = (active or hovered) and not item.disabled and "Text" or "TextMuted"
            button.label:SetTextColor(UI.Color(color))
            button.label:SetAlpha(item.disabled and 0.5 or 1)
            button.underline:SetShown(active and not item.disabled)
        end
    end
    tabs.anchor = CreateFrame("Frame", nil, parent)
    tabs.anchor:SetSize(1, TAB_HEIGHT)
    for _, item in ipairs(items) do
        local button = CreateFrame("Button", nil, parent)
        button.label = button:CreateFontString(nil, "OVERLAY", Report.FONT[level or "Heading"])
        button.label:SetPoint("LEFT")
        button.label.patiAfterText = function(self)
            button:SetSize(math.max(20, math.ceil(UI.TextWidth(self))), TAB_HEIGHT)
        end
        UI.BindText(button.label, item.text)
        button.underline = button:CreateTexture(nil, "OVERLAY")
        button.underline:SetPoint("BOTTOMLEFT")
        button.underline:SetPoint("BOTTOMRIGHT")
        button.underline:SetHeight(2)
        UI.Paint(button.underline, "SetColorTexture", "Accent")
        button:SetScript("OnEnter", paint)
        button:SetScript("OnLeave", paint)
        button:SetScript("OnClick", function()
            if item.disabled then return end
            tabs:Select(item.id)
            onSelect(item.id)
        end)
        if item.tip then UI.SetTooltip(button, item.tip) end
        tabs.buttons[item.id] = button
    end
    -- Positions follow the text widths (language change).
    function tabs.Layout(_, gap)
        tabs.gap = gap or tabs.gap
        local left = 0
        for _, item in ipairs(items) do
            local button = tabs.buttons[item.id]
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", tabs.anchor, "TOPLEFT", left, 0)
            left = left + button:GetWidth() + tabs.gap
        end
        tabs.width = left - tabs.gap
    end
    function tabs.Select(_, id) current = id; paint() end
    function tabs.SetDisabled(_, id, disabled)
        for _, item in ipairs(items) do
            if item.id == id then item.disabled = disabled end
        end
        paint()
    end
    UI.OnThemeChanged(paint)
    UI.OnLanguageChanged(function() tabs:Layout() end)
    return tabs
end

-- Class colour for a name (game data, not a theme colour); unknown class: the theme's text colour.
function Report.ClassColor(text, classFile)
    local color = RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile]
    if color then text:SetTextColor(color.r, color.g, color.b) else text:SetTextColor(UI.Color("Text")) end
end

function Report.ClassName(member)
    if member.className then return member.className end
    local names = LOCALIZED_CLASS_NAMES_MALE
    return names and member.classFile and names[member.classFile] or member.classFile
end

-- "Warrior · Tank" (class and role; either may be missing).
function Report.ClassRole(member)
    local className = Report.ClassName(member)
    local role = Report.ROLE_TEXT[member.role] and L[Report.ROLE_TEXT[member.role]] or nil
    if className and role then return ("%s · %s"):format(className, role) end
    return className or role or ""
end

-- Portrait in a role-coloured ring; without a unit (sample, left the group) the initial letter.
function Report.Portrait(parent, size)
    local ring = parent:CreateTexture(nil, "BORDER")
    ring:SetSize(size + 4, size + 4)
    local back = parent:CreateTexture(nil, "BORDER", nil, 1)
    back:SetSize(size, size)
    back:SetPoint("CENTER", ring)
    UI.Paint(back, "SetColorTexture", "Panel")
    local portrait = parent:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(size, size)
    portrait:SetPoint("CENTER", ring)
    local letter = Report.Text(parent, "Heading", "TextMuted")
    letter:SetPoint("CENTER", ring)
    local widget = { ring = ring }
    function widget.Set(_, name, role, unit)
        UI.Paint(ring, "SetColorTexture", Report.ROLE_COLOR[role] or "Border")
        -- SetPortraitTexture takes the unit token itself; no unit data is read here.
        local hasUnit = unit ~= nil and SetPortraitTexture ~= nil
        if hasUnit then SetPortraitTexture(portrait, unit) end
        portrait:SetShown(hasUnit)
        letter:SetText(hasUnit and "" or (name or "?"):sub(1, 1))
    end
    return widget
end

-- A value as shown: run time as clock, counts with one decimal for averages ("1,8"); nil = "n/a".
function Report.Value(metric, value)
    if value == nil then return L.NA end
    if metric == "time" or metric == "clock" then return Logic.Clock(value) end
    if math.floor(value) == value then return tostring(value) end
    return (("%.1f"):format(value):gsub("%.", L.DECIMAL))
end

-- Achievement texts: title + the reason (L["ACH_<ID>"], L["ACH_<ID>_TEXT"]).
function Report.AchievementText(entry)
    local args, id = entry.args, entry.id
    if id == "BEST_TIME" then
        return L.ACH_BEST_TIME, (args.personal and L.ACH_BEST_TIME_TEXT or L.ACH_BEST_TIME_GROUP_TEXT)
            :format(Logic.Clock(-args.delta))
    elseif id == "FIRST_TIME" then return L.ACH_FIRST_TIME, L.ACH_FIRST_TIME_TEXT:format(Logic.Clock(args.time))
    elseif id == "NO_WIPE" then return L.ACH_NO_WIPE, L.ACH_NO_WIPE_TEXT:format(args.deaths)
    elseif id == "TEAM" then return L.ACH_TEAM, L.ACH_TEAM_TEXT:format(args.count)
    elseif id == "STEADFAST" then
        return L.ACH_STEADFAST, args.streak and L.ACH_STEADFAST_STREAK:format(args.streak) or L.ACH_STEADFAST_TEXT
    elseif id == "IMPROVED" then
        return L.ACH_IMPROVED, L["ACH_IMPROVED_" .. args.metric:upper()]:format(
            Report.Value(args.metric, args.value), Report.Value(args.metric, args.avg))
    end
    return L["ACH_" .. id], L["ACH_" .. id .. "_TEXT"]
end

-- An achievement medallion: 32 px icon, title, the reason in up to two lines; the rule in the tooltip.
Report.MEDALLION_HEIGHT = 58
function Report.Medallion(parent, width)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, Report.MEDALLION_HEIGHT)
    frame:EnableMouse(true) -- for the tooltip with the rule
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT")
    local title = Report.Text(frame, "Body", "Text")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
    title:SetPoint("RIGHT")
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    local detail = Report.Text(frame, "Body", "TextMuted")
    detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    detail:SetPoint("RIGHT")
    detail:SetJustifyH("LEFT")
    detail:SetJustifyV("TOP")
    detail:SetWordWrap(true)
    if detail.SetMaxLines then detail:SetMaxLines(2) end
    function frame.Set(_, entry)
        icon:SetTexture(ns.Chronicle.ICONS[entry.id])
        local titleText, detailText = Report.AchievementText(entry)
        title:SetText(titleText)
        detail:SetText(detailText or "")
        UI.SetTooltip(frame, function()
            return { titleText, detailText, L.TIP_RULE .. " " .. L["RULE_" .. entry.id] }
        end)
        frame:Show()
    end
    return frame
end

-- "! 2 not checkable" with the reasons in the tooltip (anchored by its right edge).
function Report.MissingNote(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, 16)
    frame:EnableMouse(true) -- for the tooltip with the reasons
    local text = Report.Text(frame, "Caption", "Warning")
    text:SetPoint("RIGHT")
    function frame.Set(_, missing)
        frame:SetShown(#missing > 0)
        if #missing == 0 then return end
        text:SetText(L.MISSING_COUNT:format(#missing))
        frame:SetWidth(math.max(40, UI.TextWidth(text)))
        UI.SetTooltip(frame, function()
            local lines = { L.MISSING_TITLE }
            for _, entry in ipairs(missing) do
                lines[#lines + 1] = ("%s: %s"):format(L["ACH_" .. entry.id], L["MISSING_" .. entry.reason])
            end
            return lines
        end)
    end
    return frame
end

-- A slightly tinted row background (every second row; a selected row too).
function Report.RowTint(row)
    local tint = row:CreateTexture(nil, "BACKGROUND")
    tint:SetAllPoints()
    UI.Paint(tint, "SetColorTexture", "PanelHover", 0.45)
    return tint
end

-- A narrow accent bar at the left edge (your row, the selected entry): orientation, not an award.
function Report.MarkBar(row)
    local bar = row:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", -8, 0)
    bar:SetPoint("BOTTOMLEFT", -8, 0)
    bar:SetWidth(3)
    UI.Paint(bar, "SetColorTexture", "Accent")
    bar:Hide()
    return bar
end

-- Tabs ---------------------------------------------------------------------------------------------------------

local PAGE_IDS = { "overview", "group", "mine", "timeline" }
local pages, current = {}, nil
Report.pages = pages
local shownReport
local tabs = Report.TextTabs(window, {
    { id = "overview", text = "TAB_OVERVIEW" }, { id = "group", text = "TAB_GROUP" },
    { id = "mine", text = "TAB_MINE" }, { id = "timeline", text = "TAB_TIMELINE" },
}, function(id) Report.SelectTab(id) end)
tabs.anchor:SetPoint("TOPLEFT", Report.PAD, TAB_TOP)
tabs:Layout(32)
local tabLine = window:CreateTexture(nil, "ARTWORK")
tabLine:SetPoint("TOPLEFT", Report.PAD, TAB_TOP - TAB_HEIGHT - 1)
tabLine:SetSize(Report.CONTENT_WIDTH, 1)
UI.Paint(tabLine, "SetColorTexture", "Border")

for _, id in ipairs(PAGE_IDS) do
    local page = CreateFrame("Frame", nil, window)
    page:SetPoint("TOPLEFT", Report.PAD, CONTENT_TOP)
    page:SetSize(Report.CONTENT_WIDTH, Report.CONTENT_HEIGHT)
    pages[id] = page
end

function Report.SelectTab(id)
    current = id
    for tabId, page in pairs(pages) do page:SetShown(tabId == id) end
    tabs:Select(id)
end

-- Overview: the moment the run is done ------------------------------------------------------------------------

local LINEUP_SLOT = Report.CONTENT_WIDTH / 5
local LINEUP_TOP = -118
local overview = {}
do
    local page = pages.overview
    overview.kicker = Report.Text(page, "Caption", "TextMuted")
    overview.kicker:SetPoint("TOP", 0, -2)
    overview.dungeon = Report.Text(page, "Display", "Text")
    overview.dungeon:SetPoint("TOP", overview.kicker, "BOTTOM", 0, -6)
    overview.time = Report.Text(page, "Hero", "Text")
    overview.time:SetPoint("TOP", overview.dungeon, "BOTTOM", 0, -8)
    overview.headline = Report.Text(page, "Body", "Accent")
    overview.headline:SetPoint("TOP", overview.time, "BOTTOM", 0, -8)

    overview.lineup = {}
    for index = 1, 5 do
        local slot = CreateFrame("Button", nil, page)
        slot:SetSize(LINEUP_SLOT, 96)
        slot.portrait = Report.Portrait(slot, 48)
        slot.portrait.ring:SetPoint("TOP")
        slot.name = Report.Text(slot, "Heading")
        slot.name:SetPoint("TOP", slot.portrait.ring, "BOTTOM", 0, -6)
        slot.name:SetWidth(LINEUP_SLOT - 8)
        slot.name:SetWordWrap(false)
        slot.info = Report.Text(slot, "Caption", "TextMuted")
        slot.info:SetPoint("TOP", slot.name, "BOTTOM", 0, -3)
        slot.info:SetWidth(LINEUP_SLOT - 8)
        slot.info:SetWordWrap(false)
        slot:SetScript("OnClick", function()
            Report.SelectTab("group")
            if Report.SelectPlayer then Report.SelectPlayer(slot.player) end
        end)
        UI.SetTooltip(slot, "TIP_LINEUP")
        overview.lineup[index] = slot
    end

    local y = -232
    Report.Divider(page, y)
    Report.SectionTitle(page, 0, y - 16, "SECTION_TOGETHER")
    overview.missing = Report.MissingNote(page)
    overview.missing:SetPoint("TOPRIGHT", 0, y - 14)
    overview.none = Report.Text(page, "Body", "TextMuted")
    overview.none:SetPoint("TOPLEFT", 0, y - 38)
    overview.group = {}
    local medallion = (Report.CONTENT_WIDTH - 2 * 16) / 3
    for index = 1, 3 do
        local entry = Report.Medallion(page, medallion)
        entry:SetPoint("TOPLEFT", (index - 1) * (medallion + 16), y - 38)
        overview.group[index] = entry
    end

    y = y - 38 - Report.MEDALLION_HEIGHT - Report.GAP
    Report.SectionTitle(page, 0, y, "SECTION_HIGHLIGHTS")
    overview.highlights = {}
    for index = 1, 2 do
        local row = CreateFrame("Frame", nil, page)
        row:SetSize(Report.CONTENT_WIDTH, 24)
        row:SetPoint("TOPLEFT", 0, y - 20 - (index - 1) * 26)
        row.time = Report.Text(row, "Body", "TextMuted")
        row.time:SetPoint("LEFT")
        row.time:SetWidth(44)
        row.time:SetJustifyH("RIGHT")
        row.text = Report.Text(row, "Body", "Text")
        row.text:SetPoint("LEFT", 60, 0)
        overview.highlights[index] = row
    end

    local claim = Report.Text(page, "Caption", "TextMuted")
    claim:SetPoint("BOTTOMRIGHT", 0, 0)
    UI.BindText(claim, "CLAIM")
end

function Report.HighlightText(entry)
    local args = entry.args
    if entry.id == "HL_WIPE" then return L.HL_WIPE:format(args.fight) end
    if entry.id == "HL_DEATHS" then return L.HL_DEATHS:format(args.count, args.fight) end
    if entry.id == "HL_DEATH" then return L.HL_DEATH:format(args.fight) end
    if entry.id == "HL_LONG_BOSS" then return L.HL_LONG_BOSS:format(args.boss, Logic.Clock(args.seconds)) end
    return L.HL_LONG:format(args.fight, Logic.Clock(args.seconds))
end

local function headlineOf(report)
    for _, entry in ipairs(report.result.group) do
        if entry.id == "BEST_TIME" then return L.HEADLINE_BEST:format(Logic.Clock(-entry.args.delta)), true end
        if entry.id == "FIRST_TIME" then return L.HEADLINE_FIRST, true end
    end
    if report.best then return L.HEADLINE_BEST_KNOWN:format(Logic.Clock(report.best)), false end
    return "", false
end

local function fillLineup(report)
    local run, names = report.run, report.names
    local count = math.min(#names, #overview.lineup)
    local left = (Report.CONTENT_WIDTH - count * LINEUP_SLOT) / 2
    for index, slot in ipairs(overview.lineup) do
        local name = names[index]
        if name then
            local member = run.members[name] or { name = name }
            slot.player = name
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", left + (index - 1) * LINEUP_SLOT, LINEUP_TOP)
            slot.portrait:Set(name, member.role, report.units and report.units[name])
            slot.name:SetText(name)
            Report.ClassColor(slot.name, member.classFile)
            slot.info:SetText(Report.ClassRole(member))
            slot:Show()
        else
            slot:Hide()
        end
    end
end

local function fillOverview(report)
    local run, result = report.run, report.result
    local kicker = run.state == "completed" and L.KICKER_COMPLETED or run.state == "aborted" and L.KICKER_ABORTED
        or L.KICKER_RUNNING
    if run.how == "manual" then kicker = kicker .. "  ·  " .. L.STATUS_MANUAL end
    overview.kicker:SetText(kicker)
    overview.dungeon:SetText(run.name or "")
    overview.time:SetText(Logic.Clock(result.summary.time))
    local headline, strong = headlineOf(report)
    overview.headline:SetText(headline)
    UI.Paint(overview.headline, "SetTextColor", strong and "Accent" or "TextMuted")
    fillLineup(report)

    for index, entry in ipairs(overview.group) do
        if result.group[index] then entry:Set(result.group[index]) else entry:Hide() end
    end
    overview.none:SetShown(#result.group == 0)
    overview.none:SetText(run.state == "running" and L.NONE_RUNNING or L.NONE_TOGETHER)
    overview.missing:Set(result.missing)

    local highlights = ns.Chronicle.Highlights(run)
    for index, row in ipairs(overview.highlights) do
        local entry = highlights[index]
        row.time:SetText(entry and Logic.Clock(entry.t) or "")
        row.text:SetText(entry and Report.HighlightText(entry) or (index == 1 and L.HL_NONE or ""))
        row:SetShown(entry ~= nil or index == 1)
    end
end
Report.views.overview = fillOverview

-- No run yet: a short note and one click into test mode (owner 2026-10-19); Report.onSample: PaTiChronicle.lua.
local emptyNote = Report.Text(window, "Heading", "TextMuted")
emptyNote:SetPoint("CENTER", 0, Report.GAP)
emptyNote:SetWidth(Report.CONTENT_WIDTH - 2 * Report.PAD)
UI.BindText(emptyNote, "NO_REPORT")
emptyNote:Hide()
local sampleButton = UI.CreateButton(window, "SHOW_SAMPLE", nil, function()
    if Report.onSample then Report.onSample() end
end)
sampleButton:SetPoint("TOP", emptyNote, "BOTTOM", 0, -Report.GAP)
sampleButton:Hide()

local function setEmpty(empty)
    emptyNote:SetShown(empty)
    sampleButton:SetShown(empty)
    for _, button in pairs(tabs.buttons) do button:SetShown(not empty) end
    tabLine:SetShown(not empty)
    if empty then
        for _, page in pairs(pages) do page:Hide() end
    end
end

function Report.ShowEmpty()
    shownReport = nil
    setEmpty(true)
    window:SetTestMode(false)
    window:Show()
end

-- report: { run, result, names, units?, best?, sample? } (PaTiChronicle.lua; Sample.lua for test mode).
function Report.Show(report, tab)
    shownReport = report
    setEmpty(false)
    for _, id in ipairs(PAGE_IDS) do
        if Report.views[id] then Report.views[id](report) end
    end
    window:SetTestMode(report.sample == true)
    Report.SelectTab(tab or current or "overview")
    window:Show()
end

-- The shown report again (language change).
function Report.Refresh()
    if shownReport and window:IsShown() then Report.Show(shownReport) end
end

return Report
