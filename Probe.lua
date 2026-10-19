-- PaTiChronicle probe, part 2 (redesign step 1, owner 2026-10-19): what C_DamageMeter delivers, whether PlayerModel
-- works and which big Blizzard fonts exist. Read only: C_DamageMeter is never reset or changed (ResetAllCombatSessions
-- would empty the player's Blizzard meter); no numbers are stored, only structure and "readable or secret".
-- Results land in PaTiChronicleDB.probe (SavedVariables) and in /pchron probe.
local _, ns = ...
local Probe = {}
ns.Probe = Probe

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end

-- "a, b, c" of the keys of a table (sorted); nil for anything else.
local function keys(value)
    if type(value) ~= "table" or isSecret(value) then return nil end
    local list = {}
    for key in pairs(value) do list[#list + 1] = tostring(key) end
    table.sort(list)
    return table.concat(list, ", ")
end

-- Fields of a table and, for numbers, whether they came back secret: "amount=secret, name=string".
local function shape(value)
    if type(value) ~= "table" then return isSecret(value) and "secret" or type(value) end
    local list = {}
    for key, field in pairs(value) do
        local kind = isSecret(field) and "secret" or type(field)
        list[#list + 1] = ("%s=%s"):format(tostring(key), kind)
    end
    table.sort(list)
    return table.concat(list, ", ")
end

local function call(fn, ...)
    if type(fn) ~= "function" then return false, "missing" end
    return pcall(fn, ...)
end

-- The first entry of a list-like table (sessions, sources).
local function first(value)
    if type(value) == "table" and not isSecret(value) then return value[1] end
end

-- One look at C_DamageMeter. inCombat: taken during a fight (test T6c) or after it (T6b).
function Probe.DamageMeter(probe, inCombat)
    local api = C_DamageMeter
    if type(api) ~= "table" then return end
    local result = probe.meter or {}
    probe.meter = result
    local ok, available = call(api.IsDamageMeterAvailable)
    result.available = ok and (isSecret(available) and "secret" or tostring(available)) or "error"
    local enums = Enum or {}
    result.types = keys(enums.DamageMeterType) or "-"
    result.sessionTypes = keys(enums.DamageMeterSessionType) or "-"
    local sessionsOk, sessions = call(api.GetAvailableCombatSessions)
    result.sessions = sessionsOk and shape(first(sessions) or sessions) or "error"
    -- A session of the first known type (damage done, if the enum has it) and its first source (a player).
    local meterType = enums.DamageMeterType and (enums.DamageMeterType.DamageDone or next(enums.DamageMeterType))
    if type(meterType) == "string" then meterType = enums.DamageMeterType[meterType] end
    local sessionType = enums.DamageMeterSessionType
        and (enums.DamageMeterSessionType.Current or enums.DamageMeterSessionType.Overall)
    local key = inCombat and "inCombat" or "afterCombat"
    if meterType ~= nil and sessionType ~= nil then
        local sessionOk, session = call(api.GetCombatSessionFromType, sessionType, meterType)
        local sources = sessionOk and type(session) == "table" and not isSecret(session) and session.combatSources
        result[key] = sessionOk and ("session: %s | source: %s"):format(shape(session), shape(first(sources)))
            or "error"
    else
        result[key] = "no enums"
    end
end

-- Whether a 3D character (PlayerModel:SetUnit) can be shown (test T9) and which big fonts exist.
function Probe.Client(probe)
    local ok, model = pcall(CreateFrame, "PlayerModel", nil, UIParent)
    local setOk = ok and model and model.SetUnit and pcall(model.SetUnit, model, "player")
    probe.model = not ok and "no PlayerModel" or (setOk and "ok" or "SetUnit failed")
    if ok and model then model:Hide() end
    local fonts = {}
    for _, name in ipairs({ "GameFontNormalHuge", "GameFontHighlightHuge", "NumberFontNormalHuge",
        "GameFontHighlightLarge", "GameFontNormalLarge", "GameFontHighlight" }) do
        fonts[#fonts + 1] = ("%s=%s"):format(name, _G[name] and "yes" or "no")
    end
    probe.fonts = table.concat(fonts, ", ")
end

return Probe
