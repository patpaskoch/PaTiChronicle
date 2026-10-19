-- PaTiChronicle run report: the main window with three tabs — Overview (our run, your highlight), My performance
-- (ReportMine.lua) and Timeline (ReportTimeline.lua). Layout after the owner's decision of 2026-10-19: first the
-- shared success, then your part, then the details. No ranking, no winner, no points per person.
-- Display only, no secure frames. Colours only from PaTiShared tokens (themes Standard, WoForever, Dracula).
local _, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic
local Report = { views = {} }
ns.Report = Report

Report.WIDTH, Report.HEIGHT = 560, 470
Report.PAD = UI.Spacing.LG
Report.CONTENT_WIDTH = Report.WIDTH - 2 * Report.PAD
local TAB_TOP = -UI.Sizes.HeaderHeight - UI.Spacing.MD
local CONTENT_TOP = TAB_TOP - UI.Sizes.ButtonHeight - UI.Spacing.MD
Report.CONTENT_HEIGHT = Report.HEIGHT + CONTENT_TOP - Report.PAD
local LINEUP_SLOT = 100 -- one member in the lineup
local PORTRAIT = 36
local RING = 2 -- role-coloured ring around a portrait
local ACHIEVEMENT_WIDTH = 168
local ACHIEVEMENT_ICON = 22

-- Bigger Blizzard fonts (with the client's CJK fallbacks); a client without one gets the next smaller font.
local function font(name, fallback) return _G[name] and name or fallback end
Report.FONT_HUGE = font("GameFontNormalHuge", "GameFontNormalLarge")
Report.FONT_LARGE = font("GameFontHighlightLarge", UI.Fonts.Title)

Report.ROLE_COLOR = { TANK = "Mana", HEALER = "Success", DAMAGER = "Danger" }
Report.ROLE_TEXT = { TANK = "ROLE_TANK", HEALER = "ROLE_HEALER", DAMAGER = "ROLE_DAMAGER" }
Report.ICONS = { boss = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", -- skull
    death = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", -- cross
    aggro = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" } -- triangle

local window = UI.CreateWindow("PaTiChronicleFrame", "PaTiChronicle", Report.WIDTH, Report.HEIGHT)
window:SetCombatMovable(true) -- no secure children
window:SetFrameStrata("HIGH")
window:Hide()
tinsert(UISpecialFrames, "PaTiChronicleFrame") -- Esc closes the report
Report.window = window

-- Shared building blocks ----------------------------------------------------------------------------------------

function Report.Text(parent, fontName, color)
    local text = parent:CreateFontString(nil, "OVERLAY", fontName or UI.Fonts.Text)
    UI.Paint(text, "SetTextColor", color or "Text")
    return text
end

-- A small upper-case section title ("TOGETHER", "YOUR HIGHLIGHT").
function Report.SectionTitle(parent, x, y)
    local text = Report.Text(parent, UI.Fonts.Label, "TextMuted")
    text:SetPoint("TOPLEFT", x, y)
    return text
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

-- "21 Warrior", "Warrior", "21" or "".
function Report.LevelClass(member)
    local className = Report.ClassName(member)
    if member.level and className then return L.LEVEL_CLASS:format(member.level, className) end
    if member.level then return L.LEVEL:format(member.level) end
    return className or ""
end

-- Portrait in a role-coloured ring; without a unit (sample, left the group) the initial letter.
function Report.Portrait(parent, size)
    local ring = parent:CreateTexture(nil, "BORDER")
    ring:SetSize(size + 2 * RING, size + 2 * RING)
    local back = parent:CreateTexture(nil, "BORDER", nil, 1)
    back:SetSize(size, size)
    back:SetPoint("CENTER", ring)
    UI.Paint(back, "SetColorTexture", "Panel")
    local portrait = parent:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(size, size)
    portrait:SetPoint("CENTER", ring)
    local letter = Report.Text(parent, UI.Fonts.Title, "TextMuted")
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

-- Achievement texts: title + one line why (L["ACH_<ID>"], L["ACH_<ID>_TEXT"]).
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
        local value, avg = args.value, args.avg
        if args.metric == "time" then value, avg = Logic.Clock(value), Logic.Clock(avg)
        else value, avg = tostring(value), ("%.1f"):format(avg):gsub("%.", L.DECIMAL) end
        return L.ACH_IMPROVED, L["ACH_IMPROVED_" .. args.metric:upper()]:format(value, avg)
    end
    return L["ACH_" .. id], L["ACH_" .. id .. "_TEXT"]
end

-- One achievement: icon, title, the reason below. width: how wide the text may be.
function Report.Achievement(parent, width)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, ACHIEVEMENT_ICON + UI.Spacing.SM)
    frame:EnableMouse(true) -- for the tooltip with the rule
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ACHIEVEMENT_ICON, ACHIEVEMENT_ICON)
    icon:SetPoint("TOPLEFT")
    local title = Report.Text(frame, UI.Fonts.Title, "Accent")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", UI.Spacing.SM, 1)
    title:SetPoint("RIGHT")
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    local detail = Report.Text(frame, UI.Fonts.Text, "TextMuted")
    detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
    detail:SetPoint("RIGHT")
    detail:SetJustifyH("LEFT")
    detail:SetWordWrap(false)
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

-- "! 2 achievements not checkable" with the reasons in the tooltip.
function Report.MissingNote(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(260, 14)
    frame:EnableMouse(true) -- for the tooltip with the reasons
    local text = Report.Text(frame, UI.Fonts.Label, "Warning")
    text:SetPoint("LEFT")
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

-- Tabs --------------------------------------------------------------------------------------------------------

local TABS = { { id = "overview", text = "TAB_OVERVIEW" }, { id = "mine", text = "TAB_MINE" },
    { id = "timeline", text = "TAB_TIMELINE" } }
local tabButtons, pages, current = {}, {}, nil
Report.pages = pages
local shownReport

local function paintTabs()
    for _, tab in ipairs(TABS) do
        local button, active = tabButtons[tab.id], tab.id == current
        button.label:SetTextColor(UI.Color(active and "Accent" or "TextMuted"))
        button.underline:SetShown(active)
    end
end

function Report.SelectTab(id)
    current = id
    for tabId, page in pairs(pages) do page:SetShown(tabId == id) end
    paintTabs()
end

local tabX = Report.PAD
for _, tab in ipairs(TABS) do
    local button = UI.CreateButton(window, tab.text, nil, function() Report.SelectTab(tab.id) end)
    button:SetPoint("TOPLEFT", tabX, TAB_TOP)
    button.underline = button:CreateTexture(nil, "OVERLAY")
    button.underline:SetPoint("BOTTOMLEFT", 1, 1)
    button.underline:SetPoint("BOTTOMRIGHT", -1, 1)
    button.underline:SetHeight(2)
    UI.Paint(button.underline, "SetColorTexture", "Accent")
    button:HookScript("OnLeave", paintTabs)
    tabButtons[tab.id] = button
    tabX = tabX + 150
    local page = CreateFrame("Frame", nil, window)
    page:SetPoint("TOPLEFT", Report.PAD, CONTENT_TOP)
    page:SetSize(Report.CONTENT_WIDTH, Report.CONTENT_HEIGHT)
    pages[tab.id] = page
end
UI.OnThemeChanged(paintTabs)

-- Overview ----------------------------------------------------------------------------------------------------

local overview = {}
do
    local page, width = pages.overview, Report.CONTENT_WIDTH
    overview.dungeon = Report.Text(page, Report.FONT_HUGE, "Text")
    overview.dungeon:SetPoint("TOP", 0, -UI.Spacing.SM)
    overview.status = Report.Text(page, Report.FONT_LARGE, "Text")
    overview.status:SetPoint("TOP", overview.dungeon, "BOTTOM", 0, -UI.Spacing.SM)
    overview.headline = Report.Text(page, UI.Fonts.Title, "Accent")
    overview.headline:SetPoint("TOP", overview.status, "BOTTOM", 0, -UI.Spacing.SM)

    overview.lineup = {}
    local lineupTop = -96
    for index = 1, 5 do
        local slot = CreateFrame("Frame", nil, page)
        slot:SetSize(LINEUP_SLOT, PORTRAIT + 2 * RING + 30)
        slot.portrait = Report.Portrait(slot, PORTRAIT)
        slot.portrait.ring:SetPoint("TOP")
        slot.name = Report.Text(slot, UI.Fonts.Title)
        slot.name:SetPoint("TOP", slot.portrait.ring, "BOTTOM", 0, -UI.Spacing.XS)
        slot.name:SetWidth(LINEUP_SLOT - UI.Spacing.SM)
        slot.name:SetWordWrap(false)
        slot.info = Report.Text(slot, UI.Fonts.Label, "TextMuted")
        slot.info:SetPoint("TOP", slot.name, "BOTTOM", 0, -1)
        slot.info:SetWidth(LINEUP_SLOT - UI.Spacing.SM)
        slot.info:SetWordWrap(false)
        overview.lineup[index] = slot
    end
    overview.lineupTop = lineupTop

    local y = lineupTop - PORTRAIT - 2 * RING - 44
    overview.groupTitle = Report.SectionTitle(page, 0, y)
    UI.BindText(overview.groupTitle, "SECTION_TOGETHER")
    overview.groupNone = Report.Text(page, UI.Fonts.Text, "TextMuted")
    overview.groupNone:SetPoint("TOPLEFT", 0, y - 18)
    overview.group = {}
    for index = 1, 3 do
        local entry = Report.Achievement(page, ACHIEVEMENT_WIDTH)
        entry:SetPoint("TOPLEFT", (index - 1) * (ACHIEVEMENT_WIDTH + UI.Spacing.MD), y - 18)
        overview.group[index] = entry
    end

    y = y - 72
    overview.mineTitle = Report.SectionTitle(page, 0, y)
    overview.mineNone = Report.Text(page, UI.Fonts.Text, "TextMuted")
    overview.mineNone:SetPoint("TOPLEFT", 0, y - 18)
    overview.mine = {}
    for index = 1, 2 do
        local entry = Report.Achievement(page, 2 * ACHIEVEMENT_WIDTH)
        entry:SetPoint("TOPLEFT", (index - 1) * (2 * ACHIEVEMENT_WIDTH + UI.Spacing.MD), y - 18)
        overview.mine[index] = entry
    end
    local more = UI.CreateButton(page, "MORE_MINE", nil, function() Report.SelectTab("mine") end)
    more:SetPoint("TOPRIGHT", 0, y - 4)

    y = y - 72
    overview.stripTop, overview.stripWidth = y, width - 90 -- the strip itself: ReportTimeline.lua (Report.Strip)
    local toTimeline = UI.CreateButton(page, "MORE_TIMELINE", nil, function() Report.SelectTab("timeline") end)
    toTimeline:SetPoint("TOPRIGHT", 0, y + 2)

    overview.missing = Report.MissingNote(page)
    overview.missing:SetPoint("BOTTOMLEFT", 0, 0)
    local claim = Report.Text(page, UI.Fonts.Label, "TextMuted")
    claim:SetPoint("BOTTOMRIGHT", 0, 0)
    UI.BindText(claim, "CLAIM")
end

-- The status under the dungeon name and the headline (best time) above everything else.
local function statusLines(report)
    local run, summary = report.run, report.result.summary
    local status
    if run.state == "completed" then
        status = L.STATUS_COMPLETED:format(Logic.Clock(summary.time))
        if run.how == "manual" then status = status .. " " .. L.STATUS_MANUAL end
    elseif run.state == "aborted" then status = L.STATUS_ABORTED:format(Logic.Clock(summary.time))
    else status = L.STATUS_RUNNING:format(Logic.Clock(summary.time)) end
    local headline = ""
    for _, entry in ipairs(report.result.group) do
        if entry.id == "BEST_TIME" then
            headline = L.HEADLINE_BEST:format(Logic.Clock(-entry.args.delta))
        elseif entry.id == "FIRST_TIME" then headline = L.HEADLINE_FIRST end
    end
    if headline == "" and report.best then headline = L.HEADLINE_BEST_KNOWN:format(Logic.Clock(report.best)) end
    return status, headline
end

local function fillOverview(report)
    local run, result = report.run, report.result
    overview.dungeon:SetText(run.name or "")
    local status, headline = statusLines(report)
    overview.status:SetText(status)
    overview.headline:SetText(headline)
    UI.Paint(overview.headline, "SetTextColor", headline == "" and "TextMuted" or "Accent")

    local names = report.names
    local count = math.min(#names, #overview.lineup)
    local left = (Report.CONTENT_WIDTH - count * LINEUP_SLOT) / 2
    for index, slot in ipairs(overview.lineup) do
        local name = names[index]
        if name then
            local member = run.members[name] or { name = name }
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", left + (index - 1) * LINEUP_SLOT, overview.lineupTop)
            slot.portrait:Set(name, member.role, report.units and report.units[name])
            slot.name:SetText(name)
            Report.ClassColor(slot.name, member.classFile)
            slot.info:SetText(Report.LevelClass(member))
            slot:Show()
        else
            slot:Hide()
        end
    end

    for index, entry in ipairs(overview.group) do
        if result.group[index] then entry:Set(result.group[index]) else entry:Hide() end
    end
    overview.groupNone:SetShown(#result.group == 0)
    overview.groupNone:SetText(L.NONE_TOGETHER)
    overview.mineTitle:SetText(L.SECTION_HIGHLIGHT:format(run.me or "",
        L[Report.ROLE_TEXT[run.myRole] or "ROLE_NONE"]))
    for index, entry in ipairs(overview.mine) do
        if result.mine[index] then entry:Set(result.mine[index]) else entry:Hide() end
    end
    overview.mineNone:SetShown(#result.mine == 0)
    overview.mineNone:SetText(L.NONE_MINE)
    if not overview.strip then
        overview.strip = Report.Strip(pages.overview, overview.stripWidth)
        overview.strip:SetPoint("TOPLEFT", 0, overview.stripTop)
    end
    overview.strip:Set(run)
    overview.missing:Set(result.missing)
end

Report.views.overview = fillOverview

-- report: { run, result, names, units?, best?, sample? } (PaTiChronicle.lua builds it; Sample.lua for test mode).
function Report.Show(report, tab)
    shownReport = report
    for _, fill in pairs({ Report.views.overview, Report.views.mine, Report.views.timeline }) do fill(report) end
    window:SetTestMode(report.sample == true)
    Report.SelectTab(tab or current or "overview")
    window:Show()
end

-- The shown report again (language change).
function Report.Refresh()
    if shownReport and window:IsShown() then Report.Show(shownReport) end
end

return Report
