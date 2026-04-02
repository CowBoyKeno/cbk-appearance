Appearance = {}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function Appearance.Normalize(input)
    local appearance = AppearanceSchema.GetDefault()
    if type(input) ~= 'table' then
        for overlayId in pairs(Config.HeadOverlays or {}) do
            appearance.headOverlays[tostring(overlayId)] = appearance.headOverlays[tostring(overlayId)] or {
                style = 0,
                opacity = 0.0,
                color = 0,
                secondColor = 0,
            }
        end

        for slot in pairs(Config.ComponentSlots or {}) do
            if slot ~= 2 then
                appearance.components[tostring(slot)] = appearance.components[tostring(slot)] or {
                    drawable = 0,
                    texture = 0,
                }
            end
        end

        for slot in pairs(Config.PropSlots or {}) do
            appearance.props[tostring(slot)] = appearance.props[tostring(slot)] or {
                drawable = -1,
                texture = 0,
            }
        end

        return appearance
    end

    appearance.version = tonumber(input.version) or 1
    appearance.model = tostring(input.model or appearance.model)

    if type(input.heritage) == 'table' then
        for _, key in ipairs({ 'shapeFirst', 'shapeSecond', 'skinFirst', 'skinSecond' }) do
            appearance.heritage[key] = clamp(tonumber(input.heritage[key]) or appearance.heritage[key], 0, Config.Heritage.maxParentIndex)
        end
        appearance.heritage.shapeMix = clamp(tonumber(input.heritage.shapeMix) or appearance.heritage.shapeMix, 0.0, 1.0)
        appearance.heritage.skinMix = clamp(tonumber(input.heritage.skinMix) or appearance.heritage.skinMix, 0.0, 1.0)
    end

    if type(input.faceFeatures) == 'table' then
        for i = 1, Config.FaceFeatureCount do
            appearance.faceFeatures[i] = clamp(tonumber(input.faceFeatures[i]) or 0.0, Config.MinFeatureValue, Config.MaxFeatureValue)
        end
    end

    if type(input.hair) == 'table' then
        appearance.hair.style = clamp(tonumber(input.hair.style) or 0, 0, 255)
        appearance.hair.color = clamp(tonumber(input.hair.color) or 0, 0, Config.MaxHairColor)
        appearance.hair.highlight = clamp(tonumber(input.hair.highlight) or 0, 0, Config.MaxHairColor)
    end

    if type(input.eyes) == 'table' then
        appearance.eyes.color = clamp(tonumber(input.eyes.color) or 0, 0, Config.MaxEyeColor)
    end

    if type(input.headOverlays) == 'table' then
        for overlayId, overlayData in pairs(input.headOverlays) do
            if Config.HeadOverlays[tonumber(overlayId)] and type(overlayData) == 'table' then
                appearance.headOverlays[tostring(overlayId)] = {
                    style = clamp(tonumber(overlayData.style) or 0, 0, Config.HeadOverlays[tonumber(overlayId)].maxIndex),
                    opacity = clamp(tonumber(overlayData.opacity) or 0.0, 0.0, 1.0),
                    color = clamp(tonumber(overlayData.color) or 0, 0, Config.MaxHairColor),
                    secondColor = clamp(tonumber(overlayData.secondColor) or 0, 0, Config.MaxHairColor)
                }
            end
        end
    end

    if type(input.components) == 'table' then
        for slot, data in pairs(input.components) do
            local slotNumber = tonumber(slot)
            if slotNumber ~= 2 and Config.ComponentSlots[slotNumber] and type(data) == 'table' then
                appearance.components[tostring(slotNumber)] = {
                    drawable = clamp(tonumber(data.drawable) or 0, 0, Config.ComponentSlots[slotNumber].maxDrawable),
                    texture = clamp(tonumber(data.texture) or 0, 0, Config.ComponentSlots[slotNumber].maxTexture)
                }
            end
        end
    end

    if type(input.props) == 'table' then
        for slot, data in pairs(input.props) do
            local slotNumber = tonumber(slot)
            if Config.PropSlots[slotNumber] and type(data) == 'table' then
                appearance.props[tostring(slotNumber)] = {
                    drawable = clamp(tonumber(data.drawable) or -1, -1, Config.PropSlots[slotNumber].maxDrawable),
                    texture = clamp(tonumber(data.texture) or 0, 0, Config.PropSlots[slotNumber].maxTexture)
                }
            end
        end
    end

    for overlayId in pairs(Config.HeadOverlays or {}) do
        appearance.headOverlays[tostring(overlayId)] = appearance.headOverlays[tostring(overlayId)] or {
            style = 0,
            opacity = 0.0,
            color = 0,
            secondColor = 0,
        }
    end

    for slot in pairs(Config.ComponentSlots or {}) do
        if slot ~= 2 then
            appearance.components[tostring(slot)] = appearance.components[tostring(slot)] or {
                drawable = 0,
                texture = 0,
            }
        end
    end

    for slot in pairs(Config.PropSlots or {}) do
        appearance.props[tostring(slot)] = appearance.props[tostring(slot)] or {
            drawable = -1,
            texture = 0,
        }
    end

    return appearance
end

function Appearance.ClampToPedVariations(appearance, ped)
    ped = ped or PlayerPedId()
    local clampedAppearance = Appearance.Normalize(appearance)

    local maxHairDrawable = math.max(0, GetNumberOfPedDrawableVariations(ped, 2) - 1)
    clampedAppearance.hair.style = clamp(clampedAppearance.hair.style, 0, maxHairDrawable)

    for slot, data in pairs(clampedAppearance.components) do
        local componentSlot = tonumber(slot)
        if componentSlot and componentSlot ~= 2 then
            local maxDrawable = math.max(0, GetNumberOfPedDrawableVariations(ped, componentSlot) - 1)
            data.drawable = clamp(data.drawable, 0, maxDrawable)
            data.texture = clamp(data.texture, 0, math.max(0, GetNumberOfPedTextureVariations(ped, componentSlot, data.drawable) - 1))
        end
    end

    for slot, data in pairs(clampedAppearance.props) do
        local propSlot = tonumber(slot)
        if propSlot then
            local maxDrawable = GetNumberOfPedPropDrawableVariations(ped, propSlot) - 1
            if maxDrawable < 0 then
                maxDrawable = -1
            end

            data.drawable = clamp(data.drawable, -1, maxDrawable)
            if data.drawable == -1 then
                data.texture = 0
            else
                data.texture = clamp(data.texture, 0, math.max(0, GetNumberOfPedPropTextureVariations(ped, propSlot, data.drawable) - 1))
            end
        end
    end

    return clampedAppearance
end

local function isFreemodePedModel(ped)
    local model = GetEntityModel(ped)
    return model == joaat('mp_m_freemode_01') or model == joaat('mp_f_freemode_01')
end

local function waitForPedVariations(ped)
    local timeoutAt = GetGameTimer() + 750

    while DoesEntityExist(ped) and GetGameTimer() < timeoutAt do
        local hairVariations = GetNumberOfPedDrawableVariations(ped, 2)
        local torsoVariations = GetNumberOfPedDrawableVariations(ped, 3)
        if hairVariations > 0 and torsoVariations > 0 then
            break
        end

        Wait(0)
    end
end

local function applyHeadBlend(ped, heritage)
    if type(heritage) ~= 'table' then
        return
    end

    SetPedHeadBlendData(
        ped,
        heritage.shapeFirst,
        heritage.shapeSecond,
        0,
        heritage.skinFirst,
        heritage.skinSecond,
        0,
        heritage.shapeMix + 0.0,
        heritage.skinMix + 0.0,
        0.0,
        false
    )
end

local function applyFaceFeatures(ped, faceFeatures)
    if type(faceFeatures) ~= 'table' then
        return
    end

    for i = 1, Config.FaceFeatureCount do
        SetPedFaceFeature(ped, i - 1, (tonumber(faceFeatures[i]) or 0.0) + 0.0)
    end
end

local function applyComponents(ped, components)
    if type(components) ~= 'table' then
        return
    end

    local freemodePed = isFreemodePedModel(ped)
    for slot, data in pairs(components) do
        local componentSlot = tonumber(slot)
        if componentSlot and type(data) == 'table' then
            if not (freemodePed and (componentSlot == 0 or componentSlot == 2)) then
                SetPedComponentVariation(ped, componentSlot, tonumber(data.drawable) or 0, tonumber(data.texture) or 0, 0)
            end
        end
    end
end

local function applyProps(ped, props)
    if type(props) ~= 'table' then
        return
    end

    for slot, data in pairs(props) do
        local propSlot = tonumber(slot)
        if propSlot and type(data) == 'table' then
            local drawable = tonumber(data.drawable) or -1
            local texture = tonumber(data.texture) or 0

            if drawable == -1 then
                ClearPedProp(ped, propSlot)
            else
                SetPedPropIndex(ped, propSlot, drawable, texture, false)
            end
        end
    end
end

local function applyHeadOverlays(ped, overlays)
    if type(overlays) ~= 'table' then
        return
    end

    for overlayId, overlayData in pairs(overlays) do
        local overlayIndex = tonumber(overlayId)
        if overlayIndex and overlayIndex >= 0 and overlayIndex <= 12 and type(overlayData) == 'table' then
            local style = tonumber(overlayData.style) or 0
            local opacity = tonumber(overlayData.opacity) or 0.0

            SetPedHeadOverlay(ped, overlayIndex, style, opacity + 0.0)

            local overlayConfig = Config.HeadOverlays[overlayIndex]
            if overlayConfig and overlayConfig.colorType > 0 and overlayData.color ~= nil then
                SetPedHeadOverlayColor(
                    ped,
                    overlayIndex,
                    overlayConfig.colorType,
                    tonumber(overlayData.color) or 0,
                    tonumber(overlayData.secondColor or overlayData.color) or 0
                )
            end
        end
    end
end

local function applyHair(ped, hair)
    if type(hair) ~= 'table' then
        return
    end

    SetPedComponentVariation(ped, 2, tonumber(hair.style) or 0, 0, 0)
    SetPedHairColor(ped, tonumber(hair.color) or 0, tonumber(hair.highlight) or 0)
end

local function applyEyeColor(ped, eyes)
    if type(eyes) ~= 'table' then
        return
    end

    SetPedEyeColor(ped, tonumber(eyes.color) or 0)
end

function Appearance.Apply(appearance)
    local ped = PlayerPedId()
    appearance = Appearance.Normalize(appearance)

    if appearance.model and joaat(appearance.model) ~= GetEntityModel(ped) then
        local ok = ClientUtils.LoadModel(appearance.model)
        if not ok then return false, 'failed_model' end
        ped = PlayerPedId()

        if isFreemodePedModel(ped) then
            SetPedDefaultComponentVariation(ped)
            SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
        end

        waitForPedVariations(ped)
    end

    appearance = Appearance.ClampToPedVariations(appearance, ped)

    applyComponents(ped, appearance.components)
    applyProps(ped, appearance.props)
    applyHeadBlend(ped, appearance.heritage)
    applyFaceFeatures(ped, appearance.faceFeatures)
    applyHeadOverlays(ped, appearance.headOverlays)
    applyHair(ped, appearance.hair)
    applyEyeColor(ped, appearance.eyes)

    return true, Appearance.HydrateWearablesFromPed(appearance)
end

function Appearance.Rotate(deltaHeading)
    local ped = PlayerPedId()
    local heading = GetEntityHeading(ped)
    SetEntityHeading(ped, (heading + deltaHeading) % 360.0)
end

function Appearance.HydrateWearablesFromPed(appearance)
    local ped = PlayerPedId()
    local hydrated = Appearance.Normalize(appearance)

    for slot in pairs(Config.ComponentSlots or {}) do
        if slot ~= 2 then
            hydrated.components[tostring(slot)] = {
                drawable = GetPedDrawableVariation(ped, slot),
                texture = GetPedTextureVariation(ped, slot)
            }
        end
    end

    hydrated.hair.style = GetPedDrawableVariation(ped, 2)
    hydrated.hair.color = GetPedHairColor(ped)
    hydrated.hair.highlight = GetPedHairHighlightColor(ped)

    local eyeColor = GetPedEyeColor(ped)
    if eyeColor and eyeColor >= 0 then
        hydrated.eyes.color = eyeColor
    end

    for slot in pairs(Config.PropSlots or {}) do
        local drawable = GetPedPropIndex(ped, slot)
        hydrated.props[tostring(slot)] = {
            drawable = drawable,
            texture = drawable == -1 and 0 or GetPedPropTextureIndex(ped, slot)
        }
    end

    return hydrated
end

function Appearance.GetCurrent()
    return CreatorState.appearance and Appearance.Normalize(CreatorState.appearance) or AppearanceSchema.GetDefault()
end
