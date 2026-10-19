-- PaTiCompetition end screen "Party Competition": one card per member (up to five) with portrait, name, role, the
-- run's values and the score; the best score has a gold frame. Layout after the owner's design (2026-10-19).
-- Display only, no secure frames. What is shown comes from PaTiCompetition.lua (Results.Show).
local _, ns = ...
local UI, L = ns.UI, ns.UI.L
local Results = {}
ns.Results = Results

local MAX_CARDS = 5 -- a party
local PAD, GAP = UI.Spacing.LG, UI.Spacing.MD
local CARD_WIDTH, CARD_HEIGHT = 150, 404
local PORTRAIT = 72 -- portrait edge; the role frame around it is ROLE_FRAME wider on each side
local ROLE_FRAME = 3
local STAT_HEIGHT = 30 -- icon row: label on top, value below
local STAT_ICON = 22
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
    line:SetPoint("TOPLEFT", UI.Spacing.MD, y)
    line:SetPoint("TOPRIGHT", -UI.Spacing.MD, y)
    line:SetHeight(1)
    UI.Paint(line, "SetColorTexture", "Border")
end

local function newStat(card, stat, y)
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(STAT_ICON, STAT_ICON)
    icon:SetPoint("TOPLEFT", UI.Spacing.MD, y - (STAT_HEIGHT - STAT_ICON) / 2)
    icon:SetTexture(stat.icon)
    local label = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Muted)
    label:SetPoint("TOPLEFT", icon, "TOPRIGHT", UI.Spacing.SM + UI.Spacing.XS, 1)
    UI.BindText(label, stat.label)
    local value = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Title)
    value:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", UI.Spacing.SM + UI.Spacing.XS, -1)
    UI.Paint(value, "SetTextColor", "Text")
    return value
end

local cards = {}
local CARDS_TOP = -UI.Sizes.HeaderHeight - TITLE_HEIGHT - PAD
for index = 1, MAX_CARDS do
    local card = CreateFrame("Frame", nil, window, "BackdropTemplate")
    card:SetSize(CARD_WIDTH, CARD_HEIGHT)
    card:SetPoint("TOPLEFT", PAD + (index - 1) * (CARD_WIDTH + GAP), CARDS_TOP)
    UI.ApplyBackdrop(card, "Panel", "Border")

    local y = -UI.Spacing.MD
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
    card.role = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Label)
    card.role:SetPoint("TOP", 0, y)
    UI.Paint(card.role, "SetTextColor", "TextMuted")
    y = y - 18
    separator(card, y)
    y = y - UI.Spacing.SM

    card.values = {}
    for statIndex, stat in ipairs(STATS) do
        card.values[statIndex] = newStat(card, stat, y)
        y = y - STAT_HEIGHT
    end
    separator(card, y - UI.Spacing.XS)

    card.scoreLabel = card:CreateFontString(nil, "OVERLAY", UI.Fonts.Label)
    card.scoreLabel:SetPoint("BOTTOM", 0, 38)
    UI.Paint(card.scoreLabel, "SetTextColor", "TextMuted")
    UI.BindText(card.scoreLabel, "SCORE")
    card.score = card:CreateFontString(nil, "OVERLAY", FONT_SCORE)
    card.score:SetPoint("BOTTOM", 0, UI.Spacing.MD + UI.Spacing.XS)
    cards[index] = card
end

-- row: { name, role, unit?, tank, score, done, heal, taken, interrupts, kills, aggro, deaths }; isBest: gold frame.
local function fillCard(card, row, isBest, format)
    local role = row.tank and "TANK" or row.role
    UI.Paint(card.roleFrame, "SetColorTexture", ROLE_COLOR[role] or "TextMuted")
    UI.Paint(card.name, "SetTextColor", ROLE_COLOR[role] or "Text")
    card.name:SetText(row.name)
    card.role:SetText(L[ROLE_TEXT[role] or "ROLE_NONE"])
    -- SetPortraitTexture takes the unit token itself; no unit data is read. Without a unit: initial letter.
    local hasUnit = row.unit ~= nil and SetPortraitTexture ~= nil
    if hasUnit then SetPortraitTexture(card.portrait, row.unit) end
    card.portrait:SetShown(hasUnit)
    card.noPortrait:SetText(hasUnit and "" or row.name:sub(1, 1))
    for statIndex, stat in ipairs(STATS) do
        local value = row[stat.key] or 0
        card.values[statIndex]:SetText(stat.short and ns.Score.Short(value, format) or tostring(value))
    end
    card.score:SetText(L.SCORE_VALUE:format(row.score or 0))
    UI.Paint(card.score, "SetTextColor", isBest and "Accent" or "Text")
    UI.Paint(card, "SetBackdropBorderColor", isBest and "Accent" or "Border")
    UI.Paint(card, "SetBackdropColor", isBest and "PanelHover" or "Panel")
    card:Show()
end

-- rows: scored and ordered (ns.Score); best: index of the best score; info: { subtitle, sample }.
function Results.Show(rows, best, info)
    local format = { thousand = L.NUMBER_THOUSAND, million = L.NUMBER_MILLION, decimal = L.DECIMAL }
    for index, card in ipairs(cards) do
        if rows[index] then fillCard(card, rows[index], index == best, format) else card:Hide() end
    end
    subtitle:SetText(info.subtitle or "")
    sampleNote:SetShown(info.sample == true)
    window:SetTestMode(info.sample == true)
    empty:SetShown(#rows == 0)
    window:Show()
end

return Results
