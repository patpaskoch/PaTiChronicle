-- PaTiChronicle minimap button (owner 2026-10-19: "opening it is tedious"): left click shows / hides the run report,
-- right click opens the menu, drag moves it around the minimap. PaTiChronicle has no window that is always open,
-- so this is its handle. Display only, a plain button (no secure frame); switched off in the settings.
-- First minimap button of the suite, kept local (no library): a follow-up decides on PaTiShared if others want one.
local _, ns = ...
local UI, L, Logic = ns.UI, ns.UI.L, ns.Logic
local MinimapButton = {}
ns.MinimapButton = MinimapButton

local SIZE = 31
local ICON = "Interface\\Icons\\INV_Misc_Book_09" -- a book: the chronicle (classic icon)

local button, db, actions

local function place()
    if not (button and db) then return end
    local radius = (Minimap:GetWidth() / 2) + 10
    local x, y = Logic.MinimapOffset(db.minimapAngle, radius)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- While dragging: the angle from the minimap centre to the cursor.
local function follow()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    db.minimapAngle = Logic.MinimapAngle(cx / scale - mx, cy / scale - my)
    place()
end

local function create()
    button = CreateFrame("Button", nil, Minimap)
    button:SetSize(SIZE, SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture(ICON)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(self, mouse)
        GameTooltip:Hide()
        if mouse == "RightButton" then UI.ShowPopup(self, actions.menu(), 180, "RIGHT")
        else actions.toggle() end
    end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", follow) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    UI.SetTooltip(button, function() return { "PaTiChronicle", L.MINIMAP_TIP } end)
end

-- savedDb: PaTiChronicleDB (showMinimap, minimapAngle); handlers: { toggle(), menu() → popup items }.
function MinimapButton.Attach(savedDb, handlers)
    db, actions = savedDb, handlers
    if not Minimap then return end
    if not button then create() end
    MinimapButton.Refresh()
end

function MinimapButton.Refresh()
    if not button then return end
    button:SetShown(db.showMinimap == true)
    place()
end

return MinimapButton
