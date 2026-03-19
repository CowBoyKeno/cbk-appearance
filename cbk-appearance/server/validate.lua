Validator = {}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function ensureTable(v)
    return type(v) == 'table' and v or {}
end

local function isModelAllowed(modelName)
    if type(modelName) ~= 'string' or modelName == '' then
        return false
    end

    if not Config.AllowFemaleModel and modelName == 'mp_f_freemode_01' then
        return false
    end

    return Config.AllowedModels[joaat(modelName)] == true
end

local function sanitizeTextureMap(rawTextures, maxDrawable, maxTexture)
    local out = {}
    rawTextures = ensureTable(rawTextures)

    for drawable = 0, maxDrawable do
        out[tostring(drawable)] = clamp(
            math.floor(tonumber(rawTextures[tostring(drawable)] or rawTextures[drawable]) or 0),
            0,
            maxTexture
        )
    end

    return out
end

function Validator.NormalizeVariationProfile(profile)
    profile = ensureTable(profile)

    local model = tostring(profile.model or '')
    if not isModelAllowed(model) then
        return nil
    end

    local out = {
        model = model,
        components = {},
        props = {}
    }

    local components = ensureTable(profile.components)
    for slot, cfg in pairs(Config.ComponentSlots) do
        local raw = ensureTable(components[tostring(slot)] or components[slot])
        local maxDrawable = clamp(
            math.floor(tonumber(raw.maxDrawable) or 0),
            0,
            cfg.maxDrawable
        )

        out.components[tostring(slot)] = {
            maxDrawable = maxDrawable,
            textures = sanitizeTextureMap(raw.textures, maxDrawable, cfg.maxTexture)
        }
    end

    local props = ensureTable(profile.props)
    for slot, cfg in pairs(Config.PropSlots) do
        local raw = ensureTable(props[tostring(slot)] or props[slot])
        local maxDrawable = clamp(
            math.floor(tonumber(raw.maxDrawable) or -1),
            -1,
            cfg.maxDrawable
        )

        out.props[tostring(slot)] = {
            maxDrawable = maxDrawable,
            textures = maxDrawable >= 0 and sanitizeTextureMap(raw.textures, maxDrawable, cfg.maxTexture) or {}
        }
    end

    return out
end

local function getProfileTextureMax(profileSlot, drawable, fallbackMax)
    profileSlot = ensureTable(profileSlot)
    local textures = ensureTable(profileSlot.textures)
    return clamp(
        math.floor(tonumber(textures[tostring(drawable)] or textures[drawable]) or 0),
        0,
        fallbackMax
    )
end

function Validator.ApplyVariationProfile(appearance, profile)
    if not Config.EnableVariationProfileValidation or type(profile) ~= 'table' then
        return appearance
    end

    if tostring(profile.model or '') ~= tostring(appearance.model or '') then
        return appearance
    end

    local hairProfile = ensureTable(ensureTable(profile.components)['2'])
    local hairMaxDrawable = clamp(
        math.floor(tonumber(hairProfile.maxDrawable) or Config.ComponentSlots[2].maxDrawable),
        0,
        Config.ComponentSlots[2].maxDrawable
    )
    appearance.hair.style = clamp(appearance.hair.style, 0, hairMaxDrawable)

    for slot, cfg in pairs(Config.ComponentSlots) do
        if slot ~= 2 then
            local component = ensureTable(appearance.components[tostring(slot)])
            local profileSlot = ensureTable(ensureTable(profile.components)[tostring(slot)] or ensureTable(profile.components)[slot])
            local maxDrawable = clamp(
                math.floor(tonumber(profileSlot.maxDrawable) or cfg.maxDrawable),
                0,
                cfg.maxDrawable
            )

            component.drawable = clamp(component.drawable, 0, maxDrawable)
            component.texture = clamp(component.texture, 0, getProfileTextureMax(profileSlot, component.drawable, cfg.maxTexture))
            appearance.components[tostring(slot)] = component
        end
    end

    for slot, cfg in pairs(Config.PropSlots) do
        local prop = ensureTable(appearance.props[tostring(slot)])
        local profileSlot = ensureTable(ensureTable(profile.props)[tostring(slot)] or ensureTable(profile.props)[slot])
        local maxDrawable = clamp(
            math.floor(tonumber(profileSlot.maxDrawable) or cfg.maxDrawable),
            -1,
            cfg.maxDrawable
        )

        prop.drawable = clamp(prop.drawable, -1, maxDrawable)
        if prop.drawable == -1 then
            prop.texture = 0
        else
            prop.texture = clamp(prop.texture, 0, getProfileTextureMax(profileSlot, prop.drawable, cfg.maxTexture))
        end

        appearance.props[tostring(slot)] = prop
    end

    return appearance
end

function Validator.NormalizeAppearance(payload, variationProfile)
    local out = AppearanceSchema.GetDefault()
    payload = ensureTable(payload)

    out.version = tonumber(payload.version) or 1
    out.model = tostring(payload.model or out.model)
    if not isModelAllowed(out.model) then
        out.model = Config.DefaultModel
    end

    local heritage = ensureTable(payload.heritage)
    out.heritage.shapeFirst = clamp(math.floor(tonumber(heritage.shapeFirst) or out.heritage.shapeFirst), 0, Config.Heritage.maxParentIndex)
    out.heritage.shapeSecond = clamp(math.floor(tonumber(heritage.shapeSecond) or out.heritage.shapeSecond), 0, Config.Heritage.maxParentIndex)
    out.heritage.skinFirst = clamp(math.floor(tonumber(heritage.skinFirst) or out.heritage.skinFirst), 0, Config.Heritage.maxParentIndex)
    out.heritage.skinSecond = clamp(math.floor(tonumber(heritage.skinSecond) or out.heritage.skinSecond), 0, Config.Heritage.maxParentIndex)
    out.heritage.shapeMix = clamp(tonumber(heritage.shapeMix) or out.heritage.shapeMix, 0.0, 1.0)
    out.heritage.skinMix = clamp(tonumber(heritage.skinMix) or out.heritage.skinMix, 0.0, 1.0)

    local faceFeatures = ensureTable(payload.faceFeatures)
    for i = 1, Config.FaceFeatureCount do
        out.faceFeatures[i] = clamp(tonumber(faceFeatures[i]) or 0.0, Config.MinFeatureValue, Config.MaxFeatureValue)
    end

    local hair = ensureTable(payload.hair)
    out.hair.style = clamp(math.floor(tonumber(hair.style) or 0), 0, 255)
    out.hair.color = clamp(math.floor(tonumber(hair.color) or 0), 0, Config.MaxHairColor)
    out.hair.highlight = clamp(math.floor(tonumber(hair.highlight) or 0), 0, Config.MaxHairColor)

    local eyes = ensureTable(payload.eyes)
    out.eyes.color = clamp(math.floor(tonumber(eyes.color) or 0), 0, Config.MaxEyeColor)

    local headOverlays = ensureTable(payload.headOverlays)
    for overlayId, cfg in pairs(Config.HeadOverlays) do
        local raw = ensureTable(headOverlays[tostring(overlayId)] or headOverlays[overlayId])
        out.headOverlays[tostring(overlayId)] = {
            style = clamp(math.floor(tonumber(raw.style) or 0), 0, cfg.maxIndex),
            opacity = clamp(tonumber(raw.opacity) or 0.0, 0.0, 1.0),
            color = clamp(math.floor(tonumber(raw.color) or 0), 0, Config.MaxHairColor),
            secondColor = clamp(math.floor(tonumber(raw.secondColor) or 0), 0, Config.MaxHairColor)
        }
    end

    local components = ensureTable(payload.components)
    for slot, cfg in pairs(Config.ComponentSlots) do
        if slot ~= 2 then
            local raw = ensureTable(components[tostring(slot)] or components[slot])
            out.components[tostring(slot)] = {
                drawable = clamp(math.floor(tonumber(raw.drawable) or 0), 0, cfg.maxDrawable),
                texture = clamp(math.floor(tonumber(raw.texture) or 0), 0, cfg.maxTexture)
            }
        end
    end

    local props = ensureTable(payload.props)
    for slot, cfg in pairs(Config.PropSlots) do
        local raw = ensureTable(props[tostring(slot)] or props[slot])
        out.props[tostring(slot)] = {
            drawable = clamp(math.floor(tonumber(raw.drawable) or -1), -1, cfg.maxDrawable),
            texture = clamp(math.floor(tonumber(raw.texture) or 0), 0, cfg.maxTexture)
        }
    end

    out = Validator.ApplyVariationProfile(out, variationProfile)
    return out
end
