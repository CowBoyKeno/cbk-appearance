local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function sendUI(payload)
    SendNUIMessage(payload)
end

local function ensureTable(value)
    return type(value) == 'table' and value or {}
end

local function titleize(raw)
    local label = tostring(raw or ''):gsub('_', ' ')
    return (label:gsub('(%a)([%w]*)', function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end))
end

local function getAllowedModels()
    return ClientUtils.GetAllowedModels()
end

local function getOptionLabels(group, key)
    local labels = ensureTable(ensureTable(Config.OptionLabels)[group])
    return ensureTable(labels[tostring(key)] or labels[key])
end

local function buildIndexedOptions(maxIndex, prefix, labelMap, includeNone)
    local options = {}
    labelMap = ensureTable(labelMap)

    if includeNone then
        options[#options + 1] = {
            value = -1,
            label = 'None'
        }
    end

    for index = 0, maxIndex do
        local custom = labelMap[tostring(index)] or labelMap[index]
        options[#options + 1] = {
            value = index,
            label = custom or ('%s %02d'):format(prefix, index)
        }
    end

    return options
end

local function buildTextureMaxByDrawable(profileSlot, maxDrawable, fallbackMax)
    local textureMaxByDrawable = {}
    local textures = ensureTable(ensureTable(profileSlot).textures)

    for drawable = 0, maxDrawable do
        local value = math.floor(tonumber(textures[tostring(drawable)] or textures[drawable]) or fallbackMax)
        if value < 0 then value = 0 end
        if value > fallbackMax then value = fallbackMax end
        textureMaxByDrawable[tostring(drawable)] = value
    end

    return textureMaxByDrawable
end

local function buildModelOptions()
    local options = {}

    for _, modelName in ipairs(getAllowedModels()) do
        local label = titleize(modelName)
        if modelName == 'mp_m_freemode_01' then
            label = 'Male Freemode'
        elseif modelName == 'mp_f_freemode_01' then
            label = 'Female Freemode'
        end

        options[#options + 1] = {
            value = modelName,
            label = label
        }
    end

    return options
end

local function buildOverlayControls()
    local slots = Config.ShowExtendedEditorOptions and Config.ExtendedEditorOverlaySlots or Config.BasicEditorOverlaySlots
    local controls = {}

    for _, slot in ipairs(slots or {}) do
        local cfg = Config.HeadOverlays[slot]
        if cfg then
            local label = titleize(cfg.name)
            controls[#controls + 1] = {
                id = tostring(slot),
                label = label,
                colorType = cfg.colorType or 0,
                styleOptions = buildIndexedOptions(cfg.maxIndex, ('%s Style'):format(label), getOptionLabels('overlays', slot), false)
            }
        end
    end

    return controls
end

local function buildComponentControlsForModel(profile)
    local slots = Config.ShowExtendedEditorOptions and Config.ExtendedEditorComponentSlots or Config.BasicEditorComponentSlots
    local controls = {}
    local components = ensureTable(profile and profile.components)

    for _, slot in ipairs(slots or {}) do
        local cfg = Config.ComponentSlots[slot]
        if cfg and slot ~= 2 then
            local label = titleize(cfg.name)
            local profileSlot = ensureTable(components[tostring(slot)] or components[slot])
            local maxDrawable = math.floor(tonumber(profileSlot.maxDrawable) or cfg.maxDrawable)
            if maxDrawable < 0 then maxDrawable = 0 end
            if maxDrawable > cfg.maxDrawable then maxDrawable = cfg.maxDrawable end

            controls[#controls + 1] = {
                id = tostring(slot),
                label = label,
                drawableOptions = buildIndexedOptions(maxDrawable, label, getOptionLabels('components', slot), false),
                textureMaxByDrawable = buildTextureMaxByDrawable(profileSlot, maxDrawable, cfg.maxTexture),
                maxTexture = cfg.maxTexture
            }
        end
    end

    return controls
end

local function buildPropControlsForModel(profile)
    local slots = Config.ShowExtendedEditorOptions and Config.ExtendedEditorPropSlots or Config.BasicEditorPropSlots
    local controls = {}
    local props = ensureTable(profile and profile.props)

    for _, slot in ipairs(slots or {}) do
        local cfg = Config.PropSlots[slot]
        if cfg then
            local label = titleize(cfg.name)
            local profileSlot = ensureTable(props[tostring(slot)] or props[slot])
            local maxDrawable = math.floor(tonumber(profileSlot.maxDrawable) or cfg.maxDrawable)
            if maxDrawable < -1 then maxDrawable = -1 end
            if maxDrawable > cfg.maxDrawable then maxDrawable = cfg.maxDrawable end

            controls[#controls + 1] = {
                id = tostring(slot),
                label = label,
                drawableOptions = buildIndexedOptions(maxDrawable, label, getOptionLabels('props', slot), true),
                textureMaxByDrawable = maxDrawable >= 0 and buildTextureMaxByDrawable(profileSlot, maxDrawable, cfg.maxTexture) or {},
                maxTexture = cfg.maxTexture
            }
        end
    end

    return controls
end

local function buildModelProfile(modelName)
    local profile = ClientUtils.GetOrBuildVariationProfile(modelName)
    local hairProfile = ensureTable(ensureTable(profile and profile.components)['2'])
    local hairMaxDrawable = math.floor(tonumber(hairProfile.maxDrawable) or ensureTable(Config.ComponentSlots[2]).maxDrawable or 255)

    if hairMaxDrawable < 0 then hairMaxDrawable = 0 end
    if hairMaxDrawable > ensureTable(Config.ComponentSlots[2]).maxDrawable then
        hairMaxDrawable = ensureTable(Config.ComponentSlots[2]).maxDrawable
    end

    return {
        hairStyleOptions = buildIndexedOptions(hairMaxDrawable, 'Hair Style', getOptionLabels('hairStyles', modelName), false),
        componentControls = buildComponentControlsForModel(profile),
        propControls = buildPropControlsForModel(profile)
    }
end

local function buildModelProfiles()
    local profiles = {}

    for _, modelName in ipairs(getAllowedModels()) do
        profiles[modelName] = buildModelProfile(modelName)
    end

    return profiles
end

local function buildEditorConfig()
    return {
        modelOptions = buildModelOptions(),
        allowedModels = getAllowedModels(),
        heritageOptions = ClientUtils.GetHeritageOptions(Config.Heritage.maxParentIndex),
        hairColorOptions = ClientUtils.GetHairColorOptions(Config.MaxHairColor),
        eyeColorOptions = ClientUtils.GetEyeColorOptions(Config.MaxEyeColor),
        overlayControls = buildOverlayControls(),
        profiles = buildModelProfiles(),
        showExtendedEditorOptions = Config.ShowExtendedEditorOptions
    }
end

RegisterNUICallback('ready', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    TriggerEvent('cbk_appearance:client:cancel')
    cb({ ok = true })
end)

RegisterNUICallback('save', function(data, cb)
    if not CreatorState.open or not CreatorState.sessionNonce then
        cb({ ok = false, error = 'not_open' })
        return
    end

    if CreatorState.pendingSave then
        cb({ ok = false, error = 'save_pending' })
        return
    end

    CreatorState.pendingSave = true
    CreatorState.saveStartedAt = GetGameTimer()

    local payload = Appearance.Normalize(data and data.appearance or {})
    local ok, appliedOrErr = Appearance.Apply(payload)
    if not ok then
        CreatorState.pendingSave = false
        CreatorState.saveStartedAt = 0
        cb({ ok = false, error = appliedOrErr or 'preview_failed' })
        return
    end

    payload = Appearance.Normalize(appliedOrErr)
    CreatorState.appearance = payload

    sendUI({ action = 'saveState', saving = true, message = 'Saving appearance...' })
    TriggerServerEvent('cbk_appearance:server:save', payload, CreatorState.sessionNonce)
    cb({ ok = true })
end)

RegisterNUICallback('preview', function(data, cb)
    if not CreatorState.open then
        cb({ ok = false, error = 'not_open' })
        return
    end

    CreatorState.appearance = Appearance.Normalize(data and data.appearance or {})
    local ok, appliedOrErr = Appearance.Apply(CreatorState.appearance)
    if not ok then
        cb({ ok = false, error = appliedOrErr or 'preview_failed' })
        return
    end

    CreatorState.appearance = Appearance.Normalize(appliedOrErr)
    cb({ ok = true, appearance = CreatorState.appearance })
end)

RegisterNUICallback('camera', function(data, cb)
    local mode = data and data.mode or 'full'
    CameraController.SetMode(mode)
    cb({ ok = true })
end)

RegisterNUICallback('rotate', function(data, cb)
    local direction = tonumber(data and data.direction) or 0.0
    CameraController.Rotate(direction)
    cb({ ok = true })
end)

RegisterNUICallback('zoom', function(data, cb)
    local delta = tonumber(data and data.delta) or 0.0
    CameraController.Zoom(delta)
    cb({ ok = true })
end)

RegisterNUICallback('cameraInput', function(data, cb)
    local rotateDelta = tonumber(data and data.rotate) or 0.0
    local zoomDelta = tonumber(data and data.zoom) or 0.0

    if rotateDelta ~= 0.0 then
        CameraController.Rotate(rotateDelta)
    end

    if zoomDelta ~= 0.0 then
        CameraController.Zoom(zoomDelta)
    end

    cb({ ok = true })
end)

function OpenAppearanceUI(appearance)
    setFocus(true)
    sendUI({
        action = 'open',
        appearance = appearance,
        config = buildEditorConfig()
    })
end

function CloseAppearanceUI()
    setFocus(false)
    sendUI({ action = 'close' })
end

function UpdateAppearanceUI(payload)
    sendUI(payload)
end
