-- PaTiChronicle HUD: one quiet line inside a dungeon — dungeon, run clock, best time. Right click: the menu (end
-- the run, abort it, open the report, hide the line). Display only, no secure frames; it ticks once a second only
-- while shown and a run is running. Not the suite's main window (that is the report), so it is a plain frame with
-- its own saved position (DB.hud).
local _, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic
local Hud = {}
ns.Hud = Hud

local HEIGHT = 22
local TICK = 1 -- seconds between clock updates

local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
frame:SetSize(240, HEIGHT)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()
UI.ApplyBackdrop(frame, "Background", "Border")
Hud.frame = frame

local text = frame:CreateFontString(nil, "OVERLAY", UI.Fonts.Title)
text:SetPoint("LEFT", UI.Spacing.MD, 0)
UI.Paint(text, "SetTextColor", "Text")
local best = frame:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
best:SetPoint("LEFT", text, "RIGHT", UI.Spacing.MD, 0)
UI.Paint(best, "SetTextColor", "TextMuted")

local state -- { name, run, best, menu } from PaTiChronicle.lua (Hud.Update)
local db

local function paint()
    if not state then return end
    local run = state.run
    if run and run.state == "running" then
        text:SetText(("%s  %s"):format(state.name, Logic.Clock(time() - run.start)))
    elseif run then
        text:SetText(("%s  %s"):format(state.name, L.HUD_DONE:format(Logic.Clock(run.finish - run.start))))
    else
        text:SetText(("%s  %s"):format(state.name, L.HUD_READY))
    end
    best:SetText(state.best and L.HUD_BEST:format(Logic.Clock(state.best)) or "")
    frame:SetWidth(math.ceil(UI.TextWidth(text) + UI.TextWidth(best)) + 3 * UI.Spacing.MD)
end

local elapsed = 0
frame:SetScript("OnUpdate", function(_, delta)
    if not (state and state.run and state.run.state == "running") then return end
    elapsed = elapsed + delta
    if elapsed < TICK then return end
    elapsed = 0
    paint()
end)

frame:SetScript("OnDragStart", function(self)
    if db and not db.locked then self.dragged = true; self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false) -- position lives in the addon's DB
    local point, _, relativePoint, x, y = self:GetPoint()
    db.hud = { point = point, relativePoint = relativePoint, x = x, y = y }
end)
-- Left click: the run report (owner 2026-10-19); right click: the menu. A drag is not a click.
frame:SetScript("OnMouseUp", function(self, button)
    if not state then return end
    if button == "RightButton" and state.menu then UI.ShowPopup(self, state.menu(), 180, "RIGHT")
    elseif button == "LeftButton" and not self.dragged and state.open then state.open() end
    self.dragged = nil
end)
UI.SetTooltip(frame, "HUD_TIP")
UI.OnThemeChanged(function() frame:SetBackdropColor(UI.Color("Background")) end)

-- Where the line sits (saved; a broken save falls back to the top of the screen).
function Hud.Attach(savedDb)
    db = savedDb
    frame:ClearAllPoints()
    local point, relativePoint, x, y = UI.WindowPosition(db.hud, 0, -120)
    if not (db.hud and db.hud.point) then point, relativePoint = "TOP", "TOP" end
    frame:SetPoint(point, UIParent, relativePoint, x, y)
end

-- newState: nil = hide (outside a dungeon or switched off).
function Hud.Update(newState)
    state = newState
    frame:SetShown(state ~= nil)
    paint()
end

UI.OnLanguageChanged(paint)

return Hud
