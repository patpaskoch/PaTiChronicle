-- PaTiChronicle: settings window, the ••• menu, slash commands and the probe output (like the other PaTi addons:
-- PaTiDungeon is the pattern). Loaded after PaTiChronicle.lua (ns.Commands).
local _, ns = ...
local UI, L, Logic, Report = ns.UI, ns.UI.L, ns.Logic, ns.Report
local C = ns.Commands
local window = Report.window

local modal

local function buildSettings()
    local DB = C.db()
    modal = UI.CreateModal("PaTiChronicleSettings", function() return "PaTiChronicle " .. L.SETTINGS end, 380)
    local scales, roles = {}, {}
    for _, scale in ipairs(Logic.SCALES) do
        scales[#scales + 1] = { value = scale, text = function() return ("%d %%"):format(scale * 100 + 0.5) end }
    end
    for _, role in ipairs(Logic.ROLES) do roles[#roles + 1] = { value = role, text = "MY_ROLE_" .. role } end
    modal:AddSection("GENERAL")
    modal:AddRow("LANGUAGE", UI.CreateLanguageDropdown(modal, DB, 170))
    modal:AddRow("SCALE", UI.CreateDropdown(modal, 170, {
        items = function() return scales end,
        get = function() return DB.scale end,
        set = function(scale) DB.scale = scale; window:SetScale(scale) end,
    }))
    modal:AddRow("MY_ROLE", UI.CreateDropdown(modal, 170, {
        items = function() return roles end,
        get = function() return DB.myRole end,
        set = function(role) DB.myRole = role end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "SHOW_HUD", {
        get = function() return DB.showHud end,
        set = function(shown) DB.showHud = shown; C.refresh() end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "SHOW_MINIMAP", {
        get = function() return DB.showMinimap end,
        set = function(shown) DB.showMinimap = shown; ns.MinimapButton.Refresh() end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "OPEN_REPORT_AT_END", {
        get = function() return DB.openReport end,
        set = function(open) DB.openReport = open end,
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "LOCK_WINDOW", {
        get = function() return window:IsLocked() end,
        set = function(locked) window:SetLocked(locked) end,
    }))
    UI.AddWindowSettings(modal, window) -- test switch, theme, panel opacity (PaTiShared)
    modal:Finish(function()
        Logic.RestoreDefaults(DB)
        window:ApplyTheme()
        window:ApplyOpacity()
        UI.SetLanguage(DB.language)
        window:SetLocked(DB.locked)
        window:SetScale(DB.scale)
        C.refresh()
        ns.MinimapButton.Refresh()
    end)
end

local function openSettings()
    if not modal then buildSettings() end
    modal:Show()
end

window:SetMenu(function()
    local DB = C.db()
    if not DB then return {} end
    local items = { { text = "SETTINGS", onClick = openSettings } }
    if DB.run then
        items[#items + 1] = { text = "END_RUN", onClick = function() C.finishRun("manual") end }
        items[#items + 1] = { text = "ABORT_RUN", onClick = function() C.abortRun("click") end }
    end
    items[#items + 1] = { text = window:IsLocked() and "UNLOCK" or "LOCK",
        onClick = function() window:SetLocked(not window:IsLocked()) end }
    items[#items + 1] = { text = "TEST_MODE", checked = C.isTest(), onClick = C.toggleTest }
    items[#items + 1] = { text = "HIDE", onClick = function() window:Hide() end }
    return items
end)
-- PaTiSuite "show": the last (or running) run; without one there is nothing to show (false).
window.suiteSetShown = function(shown)
    if not C.db() then return false end
    return C.setShown(shown)
end

-- Probe ----------------------------------------------------------------------------------------------------------

local function yesNo(value) return value and L.YES or L.NO end

local function printProbe()
    local probe = C.db().probe
    C.say("PROBE_HEADER", tostring(probe.client))
    local seen = probe.events
    C.say("PROBE_EVENTS", yesNo(seen.ENCOUNTER_START), yesNo(seen.ENCOUNTER_END), yesNo(seen.BOSS_KILL),
        yesNo(seen.UNIT_THREAT_SITUATION_UPDATE))
    C.say("PROBE_DAMAGE_METER", probe.damageMeter or L.NO)
    ns.Probe.DamageMeter(probe, InCombatLockdown and InCombatLockdown() or false)
    local meter = probe.meter or {}
    C.say("PROBE_METER", tostring(meter.available), tostring(meter.types), tostring(meter.sessionTypes))
    C.say("PROBE_METER_SESSIONS", tostring(meter.sessions))
    C.say("PROBE_METER_AFTER", tostring(meter.afterCombat))
    C.say("PROBE_METER_DURING", tostring(meter.inCombat))
    C.say("PROBE_MODEL", tostring(probe.model), tostring(probe.fonts))
    C.say("PROBE_THREAT", probe.threat.readable, probe.threat.secret, probe.threat.party)
    C.say("PROBE_DEATHS", probe.deaths.readable, probe.deaths.secret)
    C.say("PROBE_FIGHTS", probe.fights)
    for _, fight in ipairs(probe.encounters) do
        C.say("PROBE_FIGHT", fight.event, tostring(fight.name), tostring(fight.id), tostring(fight.success),
            tostring(fight.instance))
    end
    C.say("PROBE_SAVED")
end

-- Commands -------------------------------------------------------------------------------------------------------

local function resetPosition()
    local DB = C.db()
    DB.point, DB.relativePoint, DB.x, DB.y, DB.hud = nil, nil, nil, nil, nil
    window:Attach(DB, 0, 60)
    ns.Hud.Attach(DB)
end

local COMMANDS = {
    [""] = function() C.setShown(not window:IsShown()) end,
    show = function() C.setShown(true) end,
    hide = function() C.setShown(false) end,
    test = C.toggleTest,
    lock = function() window:SetLocked(true) end,
    unlock = function() window:SetLocked(false) end,
    reset = resetPosition,
    settings = openSettings,
    ["end"] = function() if C.db().run then C.finishRun("manual") else C.say("NO_RUN") end end,
    abort = function() if C.db().run then C.abortRun("click") else C.say("NO_RUN") end end,
    hud = function() local DB = C.db(); DB.showHud = not DB.showHud; C.refresh() end,
    minimap = function()
        local DB = C.db()
        DB.showMinimap = not DB.showMinimap
        ns.MinimapButton.Refresh()
    end,
    probe = printProbe,
    clear = function()
        C.db().probe = Logic.NewProbe()
        C.noteClient(C.db().probe)
        C.say("PROBE_RESET")
    end,
    version = function() C.say("VERSION", C.version()) end,
}

-- Key binding (Bindings.xml): shown in WoW's key binding menu; nothing is bound automatically.
local G = _G
G.BINDING_HEADER_PATICHRONICLE = "PaTiChronicle"
G.BINDING_NAME_PATICHRONICLE_TOGGLE = L.BINDING_TOGGLE
function PaTiChronicle_Toggle()
    if C.db() then C.setShown(not window:IsShown()) end
end

-- Minimap button: left click = the report, right click = the same menu as the window (+ hide the button).
ns.OnLogin = function()
    ns.MinimapButton.Attach(C.db(), {
        toggle = PaTiChronicle_Toggle,
        menu = function()
            local items = window.getMenuItems and window.getMenuItems() or {}
            items[#items + 1] = { text = "HIDE_MINIMAP", onClick = function()
                C.db().showMinimap = false
                ns.MinimapButton.Refresh()
                C.say("MINIMAP_HIDDEN")
            end }
            return items
        end,
    })
end

SLASH_PATICHRONICLE1 = "/patichronicle"
SLASH_PATICHRONICLE2 = "/pchron"
SLASH_PATICHRONICLE3 = "/pcomp" -- old name (PaTiCompetition), kept until 0.3.0
SlashCmdList.PATICHRONICLE = function(message)
    local command = COMMANDS[(message or ""):match("^%s*(.-)%s*$"):lower()]
    if command and C.db() then command() else C.say("HELP") end
end
