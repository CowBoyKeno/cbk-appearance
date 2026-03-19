ClientUtils = {}

function ClientUtils.Debug(...)
    if Config.Debug then
        print(('^3[cbk_appearance]^7 %s'):format(table.concat({ ... }, ' ')))
    end
end

function ClientUtils.RequestModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) then return false, 'invalid_model' end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            return false, 'model_timeout'
        end
    end

    return true, hash
end

function ClientUtils.LoadModel(model)
    local ok, hashOrErr = ClientUtils.RequestModel(model)
    if not ok then
        return false, hashOrErr
    end

    local hash = hashOrErr

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    return true
end

function ClientUtils.Notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

function ClientUtils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function ClientUtils.GetAllowedModels()
    local out = {}
    local seen = {}

    for _, modelName in ipairs(Config.AllowedModelNames or {}) do
        if type(modelName) == 'string' and modelName ~= '' then
            if modelName ~= 'mp_f_freemode_01' or Config.AllowFemaleModel then
                if not seen[modelName] then
                    seen[modelName] = true
                    out[#out + 1] = modelName
                end
            end
        end
    end

    if #out == 0 and type(Config.DefaultModel) == 'string' and Config.DefaultModel ~= '' then
        out[1] = Config.DefaultModel
    end

    return out
end

local function buildTextureMapForComponent(ped, slot, maxDrawable)
    local textures = {}

    for drawable = 0, maxDrawable do
        textures[tostring(drawable)] = math.max(0, GetNumberOfPedTextureVariations(ped, slot, drawable) - 1)
    end

    return textures
end

local function buildTextureMapForProp(ped, slot, maxDrawable)
    local textures = {}

    for drawable = 0, maxDrawable do
        textures[tostring(drawable)] = math.max(0, GetNumberOfPedPropTextureVariations(ped, slot, drawable) - 1)
    end

    return textures
end

function ClientUtils.BuildVariationProfile(modelName)
    local ok, hashOrErr = ClientUtils.RequestModel(modelName)
    if not ok then
        return nil, hashOrErr
    end

    local hash = hashOrErr
    local playerCoords = GetEntityCoords(PlayerPedId())
    local ped = CreatePed(2, hash, playerCoords.x, playerCoords.y, playerCoords.z + 75.0, 0.0, false, false)

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(hash)
        return nil, 'ped_create_failed'
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetPedDefaultComponentVariation(ped)

    local profile = {
        model = modelName,
        components = {},
        props = {}
    }

    for slot in pairs(Config.ComponentSlots or {}) do
        local drawableCount = GetNumberOfPedDrawableVariations(ped, slot)
        local maxDrawable = math.max(0, drawableCount - 1)

        profile.components[tostring(slot)] = {
            maxDrawable = maxDrawable,
            textures = buildTextureMapForComponent(ped, slot, maxDrawable)
        }
    end

    for slot in pairs(Config.PropSlots or {}) do
        local drawableCount = GetNumberOfPedPropDrawableVariations(ped, slot)
        local maxDrawable = drawableCount > 0 and (drawableCount - 1) or -1

        profile.props[tostring(slot)] = {
            maxDrawable = maxDrawable,
            textures = maxDrawable >= 0 and buildTextureMapForProp(ped, slot, maxDrawable) or {}
        }
    end

    DeleteEntity(ped)
    SetModelAsNoLongerNeeded(hash)
    return profile
end

function ClientUtils.BuildVariationProfiles(modelNames)
    local profiles = {}

    for _, modelName in ipairs(modelNames or {}) do
        local profile = ClientUtils.BuildVariationProfile(modelName)
        if profile then
            profiles[#profiles + 1] = profile
        end
    end

    return profiles
end
