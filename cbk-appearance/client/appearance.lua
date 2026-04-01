Appearance = {}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function Appearance.Normalize(input)
    local appearance = AppearanceSchema.GetDefault()
    if type(input) ~= 'table' then
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

function Appearance.Apply(appearance)
    local ped = PlayerPedId()
    appearance = Appearance.Normalize(appearance)

    if appearance.model and joaat(appearance.model) ~= GetEntityModel(ped) then
        local ok = ClientUtils.LoadModel(appearance.model)
        if not ok then return false, 'failed_model' end
        ped = PlayerPedId()
    end

    appearance = Appearance.ClampToPedVariations(appearance, ped)

    local h = appearance.heritage
    SetPedHeadBlendData(ped, h.shapeFirst, h.shapeSecond, 0, h.skinFirst, h.skinSecond, 0, h.shapeMix + 0.0, h.skinMix + 0.0, 0.0, false)

    for i = 1, Config.FaceFeatureCount do
        SetPedFaceFeature(ped, i - 1, appearance.faceFeatures[i] + 0.0)
    end

    SetPedComponentVariation(ped, 2, appearance.hair.style, 0, 0)
    SetPedHairColor(ped, appearance.hair.color, appearance.hair.highlight)
    SetPedEyeColor(ped, appearance.eyes.color)

    for overlayId, overlayData in pairs(appearance.headOverlays) do
        local overlayIndex = tonumber(overlayId)
        local style = overlayData.style or 0
        SetPedHeadOverlay(ped, overlayIndex, style, overlayData.opacity + 0.0)
        local overlayConfig = Config.HeadOverlays[overlayIndex]
        if overlayConfig and overlayConfig.colorType > 0 then
            SetPedHeadOverlayColor(ped, overlayIndex, overlayConfig.colorType, overlayData.color or 0, overlayData.secondColor or 0)
        end
    end

    for slot, data in pairs(appearance.components) do
        local componentSlot = tonumber(slot)
        if componentSlot ~= 2 then
            SetPedComponentVariation(ped, componentSlot, data.drawable, data.texture, 0)
        end
    end

    for slot, data in pairs(appearance.props) do
        local propSlot = tonumber(slot)
        if data.drawable == -1 then
            ClearPedProp(ped, propSlot)
        else
            SetPedPropIndex(ped, propSlot, data.drawable, data.texture, true)
        end
    end

    return true, appearance
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
        if slot ~= 2 and hydrated.components[tostring(slot)] == nil then
            hydrated.components[tostring(slot)] = {
                drawable = GetPedDrawableVariation(ped, slot),
                texture = GetPedTextureVariation(ped, slot)
            }
        end
    end

    for slot in pairs(Config.PropSlots or {}) do
        if hydrated.props[tostring(slot)] == nil then
            local drawable = GetPedPropIndex(ped, slot)
            hydrated.props[tostring(slot)] = {
                drawable = drawable,
                texture = drawable == -1 and 0 or GetPedPropTextureIndex(ped, slot)
            }
        end
    end

    return hydrated
end

function Appearance.GetCurrent()
    return CreatorState.appearance and Appearance.Normalize(CreatorState.appearance) or AppearanceSchema.GetDefault()
end
