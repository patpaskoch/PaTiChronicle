-- PaTiCompetition end screen "Party Competition": one card per member (up to five) with portrait, name, level and
-- class, role, the run's values with the points each one gives, and the score; the best score has a gold frame.
-- Layout after the owner's design (2026-10-19). Display only, no secure frames. Values come from
-- PaTiCompetition.lua (Results.Show).
local _, ns = ...
local UI, L = ns.UI, ns.UI.L
local Results = {}
ns.Results = Results

local MAX_CARDS = 5 -- a party
local PAD, GAP = UI.Spacing.LG, UI.Spacing.MD
local INSET = UI.Spacing.MD -- card content inset
local CARD_WIDTH, CARD_HEIGHT = 176, 500
local PORTRAIT = 72 -- portrait edge; the role frame around it is ROLE_FRAME wider on each side
local ROLE_FRAME = 3
-- One value row (owner 2026-10-19: "mehr Abstand, besser lesbar"): label and value on top, below the bar with the
-- points this value gives; a thin line between rows.
local ROW_HEIGHT = 40
local ROW_TOP = 6 -- space above the label line
local STAT_ICON = 20
local POINTS_WIDTH = 30 -- "+50" / "-10" right of the bar
local BAR = 4 -- points bar height
local BAR_TOP = 26 -- points bar below the label line (row top → bar top)
local SCORE_BAR = 6 -- the score as a bar 0-100 under the number
local SCORE_BAR_WIDTH = CARD_WIDTH - 2 * INSET
local TITLE_HEIGHT = 52 -- big title + subtitle above the cards
local WIDTH = 2 * PAD + MAX_CARDS * CARD_WIDTH + (MAX_CARDS - 1) * GAP
local HEIGHT = UI.Sizes.HeaderHeight + TITLE_HEIGHT + CARD_HEIGHT + 2 * PAD

-- Bigger Blizzard fonts for the title, the names and the score (they carry the client's CJK fallbacks); a client
-- without one gets the next smaller font.
local function font(name, fallback) return _G[name] and name or fallback end
local FONT_TITLE = font("GameFontNormalHuge", "GameFontNormalLarge")
local FONT_NAME = font("GameFontHighlightLarge", UI.Fonts.Title)
local FONT_SCORE = font("GameFontHighlightHuge", font("GameFontHighlightLarge", UI.Fonts.Title))

-- Role colours from the theme: tank blue, healer green, damage red (like the design); unknown = muted.
local ROLE_COLOR = { TANK = "Mana", HEALER = "Success", DAMAGER = "Danger" }
local ROLE_TEXT = { TANK = "ROLE_TANK", HEALER = "ROLE_HEALER", DAMAGER = "ROLE_DAMAGER" }

-- The values on a card, top to bottom. Icons: classic textures every client has.
local STATS = {
    { key = "done", label = "STAT_DAMAGE", icon = "Interface\\Icons\\INV_Sword_04", short = true },
    { key = "heal", label = "STAT_HEALING", icon = "Interface\\Icons\\Spell_Holy_Heal", short = true },
    { key = "taken", label = "STAT_TAKEN", icon = "Interface\\Icons\\INV_Shield_06", short = true },
    { key = "interrupts", label = "STAT_INTERRUPTS", icon = "Interface\\Icons\\Ability_Kick" },
    { key = "kills", label = "STAT_KILLS", icon = "Interface\\Icons\\Ability_BackStab" },
    { key = "aggro", label = "STAT_AGGRO", icon = "Interface\\Icons\\Spell_Nature_Reincarnation" },
    { key = "deaths", label = "STAT_DEATHS", icon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" },
}

local window = UI.CreateWindow("PaTiCompetitionFrame", "PaTiCompetition", WIDTH, HEIGHT)
window:SetCombatMovable(true) -- no secure children
window:SetFrameStrata("HIGH")
window:Hide()
tinsert(UISpecialFrames, "PaTiCompetitionFrame") -- Esc closes the end screen
Results.window = window

local title = window:CreateFontString(nil, "OVERLAY", FONT_TITLE)
title:SetPoint("TOP", 0, -UI.Sizes.HeaderHeight - UI.Spacing.SM)
UI.Paint(title, "SetTextColor", "Accent")
UI.BindText(title, "TITLE")
local subtitle = window:CreateFontString(nil, "OVERLAY", UI.Fonts.Label)
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -UI.Spacing.SM)
UI.Paint(subtitle, "SetTextColor", "TextMuted")
local sampleNote = window:CreateFontString(nil, "OVERLAY", UI.Fonts.Muted)
sampleNote:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", -PAD, -UI.Sizes.HeaderHeight - TITLE_HEIGHT + UI.Spacing.XS)
UI.BindText(sampleNote, "SAMPLE_VALUES")
local empty = window:CreateFontString(nil, "OVERLAY", UI.Fonts.Muted)
empty:SetPoint("CENTER", 0, -TITLE_HEIGHT / 2)
UI.BindText(empty, "RESULTS_EMPTY")

local function separator(card, y)
    local line = card:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", INSET, y)
    line:SetPoint("TOPRIGHT", -INSET, y)
    line:SetHeight(1)
    UI.Paint(line, "SetColorTexture", "Border")
end

-- A bar: the dark track and its fill, both anchored at the track's left edge.
local function newBar(card, width, height)
    local track = card:CreateTexture(nil, "ARTWORK")
    track:SetSize(width, height)
    UI.Paint(track, "SetColorTexture", "Border")
    local fill = card:CreateTexture(nil, "OVERLAY")
    fill:SetHeight(height)
    fill:SetPoint("LEFT", track, "LEFT")
    return { track = track, fill = fill, width = width }
end

-- fraction 0-1 of the track; a texture cannot be 0 wide, so an empty bar hides its fill.
local function setBar(bar, fraction, color)
    fraction = math.max(0, math.min(1, fraction))
    bar.fill:SetWidth(math.max(1, bar.width * fraction))
    bar.fill:SetShown(fraction > 0)
    UI.Paint(bar.fill, "SetColorTexture", color)
end

local function newStat(card, stat, y)
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(STAT_ICON, STAT_ICON)
    icon:SetPoint("TOPLEFT", INSET, y - ROW_TOP)
    icon:SetTexture(stat.icon)
    local textLeft = INSET + STAT_ICON + UI.Spacing.MD
    local label = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
    label:SetPoint("TOPLEFT", textLeft, y - ROW_TOP)
    UI.Paint(label, "SetTextColor", "TextMuted")
    UI.BindText(label, stat.label)
    local value = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Title)
    value:SetPoint("TOPRIGHT", -INSET, y - ROW_TOP)
    value:SetJustifyH("RIGHT")
    UI.Paint(value, "SetTextColor", "Text")
    local bar = newBar(card, CARD_WIDTH - textLeft - INSET - POINTS_WIDTH, BAR)
    bar.track:SetPoint("TOPLEFT", textLeft, y - BAR_TOP)
    local points = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Label)
    points:SetPoint("RIGHT", card, "TOPRIGHT", -INSET, y - BAR_TOP - BAR / 2)
    points:SetJustifyH("RIGHT")
    return { value = value, bar = bar, points = points }
end

local cards = {}
local CARDS_TOP = -UI.Sizes.HeaderHeight - TITLE_HEIGHT - PAD
for index = 1, MAX_CARDS do
    local card = CreateFrame("Frame", nil, window, "BackdropTemplate")
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    card:SetPoint("TOPLEFT", PAD + (index - 1) * (CARD_WIDTH + GAP), CARDS_TOP)
    UI.ApplyBackdrop(card, "Panel", "Border")

    local y = -INSET
    card.roleFrame = card:CreateTexture(nil, "BORDER")
    card.roleFrame:SetSize(PORTRAIT + 2 * ROLE_FRAME, PORTRAIT + 2 * ROLE_FRAME)
    card.roleFrame:SetPoint("TOP", 0, y)
    card.placeholder = card:CreateTexture(nil, "BORDER", nil, 1) -- under the portrait; seen without a unit
    card.placeholder:SetSize(PORTRAIT, PORTRAIT)
    card.placeholder:SetPoint("CENTER", card.roleFrame)
    UI.Paint(card.placeholder, "SetColorTexture", "PanelHover")
    card.portrait = card:CreateTexture(nil, "ARTWORK")
    card.portrait:SetSize(PORTRAIT, PORTRAIT)
    card.portrait:SetPoint("CENTER", card.roleFrame)
    card.noPortrait = card:CreateFontString(nil, "OVERLAY", FONT_TITLE) -- no unit (sample, left the group)
    card.noPortrait:SetPoint("CENTER", card.roleFrame)
    UI.Paint(card.noPortrait, "SetTextColor", "TextMuted")
    y = y - PORTRAIT - 2 * ROLE_FRAME - UI.Spacing.SM

    card.name = card:CreateFontString(nil, "OVERLAY", FONT_NAME)
    card.name:SetPoint("TOP", 0, y)
    card.name:SetWidth(CARD_WIDTH - 2 * UI.Spacing.SM)
    card.name:SetWordWrap(false)
    y = y - 20
    card.class = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Text) -- "Level 60 Warrior" in the class colour
    card.class:SetPoint("TOP", 0, y)
    card.class:SetWidth(CARD_WIDTH - 2 * UI.Spacing.SM)
    card.class:SetWordWrap(false)
    y = y - 16
    card.role = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Label)
    card.role:SetPoint("TOP", 0, y)
    UI.Paint(card.role, "SetTextColor", "TextMuted")
    y = y - 18
    separator(card, y)

    card.stats = {}
    for statIndex, stat in ipairs(STATS) do
        card.stats[statIndex] = newStat(card, stat, y)
        y = y - ROW_HEIGHT
        if statIndex < #STATS then separator(card, y) end
    end
    separator(card, y - UI.Spacing.XS)

    card.scoreBar = newBar(card, SCORE_BAR_WIDTH, SCORE_BAR)
    card.scoreBar.track:SetPoint("BOTTOM", 0, INSET)
    card.score = card:CreateFontString(nil, "OVERLAY", FONT_SCORE)
    card.score:SetPoint("BOTTOM", 0, INSET + SCORE_BAR + UI.Spacing.MD)
    card.scoreLabel = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Label)
    card.scoreLabel:SetPoint("BOTTOM", card.score, "TOP", 0, UI.Spacing.SM)
    UI.Paint(card.scoreLabel, "SetTextColor", "TextMuted")
    UI.BindText(card.scoreLabel, "SCORE")
    cards[index] = card
end

-- "Level 60 Warrior", "Warrior" or "Level 60"; nil when neither is known. className: the client's own name for the
-- unit's class; the example values only carry classFile.
local function classLine(row)
    local className = row.className
    if not className and row.classFile and LOCALIZED_CLASS_NAMES_MALE then
        className = LOCALIZED_CLASS_NAMES_MALE[row.classFile]
    end
    className = className or row.classFile
    if row.level and className then return L.LEVEL_CLASS:format(row.level, className) end
    if row.level then return L.LEVEL:format(row.level) end
    return className
end

local function paintClass(card, row)
    card.class:SetText(classLine(row) or "")
    local color = RAID_CLASS_COLORS and row.classFile and RAID_CLASS_COLORS[row.classFile]
    if color then card.class:SetTextColor(color.r, color.g, color.b) else card.class:SetTextColor(UI.Color("Text")) end
end

-- "+45", "-10" or "0" (whole points; ASCII minus: the game fonts may lack U+2212).
local function pointsText(points)
    local whole = math.floor(math.abs(points) + 0.5)
    if whole == 0 then return "0" end
    return (points > 0 and "+%d" or "-%d"):format(whole)
end

-- Points per value: green bar for plus points, red for minus points, relative to the most this value can give.
local function fillStat(stat, row, statInfo, limits, format)
    local value = row[statInfo.key] or 0
    stat.value:SetText(statInfo.short and ns.Score.Short(value, format) or tostring(value))
    local points = row.parts and row.parts[statInfo.key] or 0
    local limit = limits and limits[statInfo.key] or 0
    local color = points < 0 and "Danger" or "Success"
    setBar(stat.bar, limit > 0 and math.abs(points) / limit or 0, color)
    stat.points:SetText(pointsText(points))
    UI.Paint(stat.points, "SetTextColor", math.floor(math.abs(points) + 0.5) == 0 and "TextMuted" or color)
end

-- row: { name, role, unit?, level?, className?, classFile?, tank, score, parts, done, heal, … }; isBest: gold frame.
local function fillCard(card, row, isBest, limits, format)
    local role = row.tank and "TANK" or row.role
    UI.Paint(card.roleFrame, "SetColorTexture", ROLE_COLOR[role] or "TextMuted")
    UI.Paint(card.name, "SetTextColor", ROLE_COLOR[role] or "Text")
    card.name:SetText(row.name)
    paintClass(card, row)
    card.role:SetText(L[ROLE_TEXT[role] or "ROLE_NONE"])
    -- SetPortraitTexture takes the unit token itself; no unit data is read. Without a unit: initial letter.
    local hasUnit = row.unit ~= nil and SetPortraitTexture ~= nil
    if hasUnit then SetPortraitTexture(card.portrait, row.unit) end
    card.portrait:SetShown(hasUnit)
    card.noPortrait:SetText(hasUnit and "" or row.name:sub(1, 1))
    for statIndex, statInfo in ipairs(STATS) do fillStat(card.stats[statIndex], row, statInfo, limits, format) end
    card.score:SetText(L.SCORE_VALUE:format(row.score or 0))
    UI.Paint(card.score, "SetTextColor", isBest and "Accent" or "Text")
    setBar(card.scoreBar, (row.score or 0) / 100, isBest and "Accent" or ROLE_COLOR[role] or "TextMuted")
    UI.Paint(card, "SetBackdropBorderColor", isBest and "Accent" or "Border")
    UI.Paint(card, "SetBackdropColor", isBest and "PanelHover" or "Panel")
    card:Show()
end

-- rows: scored and ordered (ns.Score); best: index of the best score; info: { subtitle, sample, limits }
-- (limits: the most points each value can give, from Score.Apply).
function Results.Show(rows, best, info)
    local format = { thousand = L.NUMBER_THOUSAND, million = L.NUMBER_MILLION, decimal = L.DECIMAL }
    for index, card in ipairs(cards) do
        if rows[index] then fillCard(card, rows[index], index == best, info.limits, format) else card:Hide() end
    end
    subtitle:SetText(info.subtitle or "")
    sampleNote:SetShown(info.sample == true)
    window:SetTestMode(info.sample == true)
    empty:SetShown(#rows == 0)
    window:Show()
end

return Results
