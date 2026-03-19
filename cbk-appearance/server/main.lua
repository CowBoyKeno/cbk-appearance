local sessions = {}
local variationProfiles = {}
local autoOpenHandled = {}
local routingBuckets = {}

local function newNonce(source)
    return ('%s:%s:%s'):format(source, os.time(), math.random(100000, 999999))
end

local function closeSession(source)
    sessions[source] = nil

    if Config.EnableRoutingBucketIsolation and routingBuckets[source] ~= nil then
        SetPlayerRoutingBucket(source, routingBuckets[source])
        routingBuckets[source] = nil
    end
end

local function openCreator(source, appearance)
    if not source or source <= 0 then
        return false, 'invalid_source'
    end

    local nonce = newNonce(source)
    sessions[source] = {
        nonce = nonce,
        openedAt = GetGameTimer()
    }
    autoOpenHandled[source] = true

    if Config.EnableRoutingBucketIsolation then
        routingBuckets[source] = routingBuckets[source] or GetPlayerRoutingBucket(source)
        SetPlayerRoutingBucket(source, Config.CreatorBucket)
    end

    TriggerClientEvent('cbk_appearance:client:open', source, appearance, nonce)
    return true, nonce
end

local function getVariationProfile(source, modelName)
    local playerProfiles = variationProfiles[source]
    if type(playerProfiles) ~= 'table' then
        return nil
    end

    local model = tostring(modelName or '')
    if model == '' then
        model = Config.DefaultModel
    end

    return playerProfiles[model]
end

local function getValidatedAppearance(source)
    local appearance = Persistence.Load(source)
    local variationProfile = getVariationProfile(source, appearance and appearance.model or nil)

    if variationProfile then
        return Validator.NormalizeAppearance(appearance, variationProfile)
    end

    return appearance
end

local function sendAuthoritativeAppearance(source)
    if not source or source <= 0 then
        return false, 'invalid_source'
    end

    local appearance = getValidatedAppearance(source)
    TriggerClientEvent('cbk_appearance:client:applyAuthoritativeAppearance', source, appearance)
    return true, appearance
end

RegisterNetEvent('cbk_appearance:server:requestOpen', function()
    local source = source
    local appearance = getValidatedAppearance(source)
    openCreator(source, appearance)
end)

RegisterNetEvent('cbk_appearance:server:save', function(payload, nonce)
    local source = source
    local session = sessions[source]
    if not session or session.nonce ~= nonce then
        TriggerClientEvent('cbk_appearance:client:saveResult', source, false, nil, 'invalid_session')
        return
    end

    local allowed, waitMs = RateLimit.Check('save', source, Config.SaveCooldownMs)
    if not allowed then
        TriggerClientEvent('cbk_appearance:client:saveResult', source, false, nil, ('rate_limited_%sms'):format(waitMs))
        return
    end

    local variationProfile = getVariationProfile(source, type(payload) == 'table' and payload.model or nil)
    if Config.EnableVariationProfileValidation and not variationProfile then
        TriggerClientEvent('cbk_appearance:client:saveResult', source, false, nil, 'variation_profile_missing')
        return
    end

    local appearance = Validator.NormalizeAppearance(payload, variationProfile)
    local ok, err = Persistence.Save(source, appearance)
    if not ok then
        TriggerClientEvent('cbk_appearance:client:saveResult', source, false, nil, err)
        return
    end

    closeSession(source)
    TriggerClientEvent('cbk_appearance:client:saveResult', source, true, appearance)
end)

RegisterNetEvent('cbk_appearance:server:requestAuthoritativeAppearance', function()
    local source = source
    sendAuthoritativeAppearance(source)
end)

RegisterNetEvent('cbk_appearance:server:checkAutoOpen', function()
    local source = source
    if not Config.AutoOpenIfNoSavedAppearance or autoOpenHandled[source] or sessions[source] then
        return
    end

    local hasSavedAppearance = Persistence.HasSavedAppearance(source)
    if hasSavedAppearance then
        autoOpenHandled[source] = true
        return
    end

    local appearance = getValidatedAppearance(source)
    openCreator(source, appearance)
end)

RegisterNetEvent('cbk_appearance:server:syncVariationProfiles', function(profiles)
    local source = source
    if not Config.EnableVariationProfileValidation then
        return
    end

    variationProfiles[source] = variationProfiles[source] or {}
    for _, rawProfile in pairs(type(profiles) == 'table' and profiles or {}) do
        local normalized = Validator.NormalizeVariationProfile(rawProfile)
        if normalized then
            variationProfiles[source][normalized.model] = normalized
        end
    end
end)

RegisterNetEvent('cbk_appearance:server:sessionClosed', function()
    closeSession(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            SetTimeout(1000, function()
                sendAuthoritativeAppearance(source)
            end)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if not Config.EnableRoutingBucketIsolation then
        return
    end

    for source, originalBucket in pairs(routingBuckets) do
        if GetPlayerName(source) then
            SetPlayerRoutingBucket(source, originalBucket)
        end
    end
end)

AddEventHandler('playerDropped', function()
    closeSession(source)
    variationProfiles[source] = nil
    autoOpenHandled[source] = nil
end)

exports('GetSavedAppearance', function(source)
    if not source or source <= 0 then
        return nil
    end

    return Persistence.Load(source)
end)

exports('HasSavedAppearance', function(source)
    if not source or source <= 0 then
        return false, 'invalid_source'
    end

    return Persistence.HasSavedAppearance(source)
end)

exports('ApplySavedAppearance', function(source)
    local ok, appearance = sendAuthoritativeAppearance(source)
    if not ok then
        return false, appearance
    end

    return true, appearance
end)
