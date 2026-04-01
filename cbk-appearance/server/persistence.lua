Persistence = {}

local cache = {}
local cacheExists = {}

local function identifierFor(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if id:find('license:') == 1 then
            return id
        end
    end
    return identifiers[1]
end

function Persistence.GetIdentifier(source)
    return identifierFor(source)
end

function Persistence.Load(source)
    local identifier = identifierFor(source)
    if not identifier then
        return AppearanceSchema.GetDefault(), 'missing_identifier'
    end

    if cache[identifier] then
        return cache[identifier]
    end

    local row = MySQL.single.await('SELECT appearance_json FROM cbk_appearance WHERE player_identifier = ? LIMIT 1', { identifier })
    if not row or not row.appearance_json then
        local fallback = AppearanceSchema.GetDefault()
        cache[identifier] = fallback
        cacheExists[identifier] = false
        return fallback
    end

    local decoded = json.decode(row.appearance_json)
    local normalized = Validator.NormalizeAppearance(decoded)
    cache[identifier] = normalized
    cacheExists[identifier] = true
    return normalized
end

function Persistence.HasSavedAppearance(source)
    local identifier = identifierFor(source)
    if not identifier then
        return false, 'missing_identifier'
    end

    if cacheExists[identifier] ~= nil then
        return cacheExists[identifier]
    end

    local row = MySQL.single.await('SELECT id FROM cbk_appearance WHERE player_identifier = ? LIMIT 1', { identifier })
    local exists = row ~= nil
    cacheExists[identifier] = exists
    return exists
end

function Persistence.Save(source, appearance)
    local identifier = identifierFor(source)
    if not identifier then
        return false, 'missing_identifier'
    end

    local encoded = json.encode(appearance)
    local result = MySQL.insert.await([[
        INSERT INTO cbk_appearance (player_identifier, appearance_json, updated_at)
        VALUES (?, ?, NOW())
        ON DUPLICATE KEY UPDATE appearance_json = VALUES(appearance_json), updated_at = NOW()
    ]], { identifier, encoded })

    if result == nil then
        return false, 'db_write_failed'
    end

    cache[identifier] = appearance
    cacheExists[identifier] = true
    return true
end

AddEventHandler('playerDropped', function()
    local source = source
    local identifier = identifierFor(source)
    if identifier then
        cache[identifier] = nil
        cacheExists[identifier] = nil
    end
    RateLimit.ClearPlayer(source)
end)
