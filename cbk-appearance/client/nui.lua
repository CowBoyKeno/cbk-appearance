local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function sendUI(payload)
    SendNUIMessage(payload)
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
            controls[#controls + 1] = {
                id = tostring(slot),
                label = titleize(cfg.name),
                maxStyle = cfg.maxIndex,
                colorType = cfg.colorType or 0
            }
        end
    end

    return controls
end

local function buildComponentControls()
    local slots = Config.ShowExtendedEditorOptions and Config.ExtendedEditorComponentSlots or Config.BasicEditorComponentSlots
    local controls = {}

    for _, slot in ipairs(slots or {}) do
        local cfg = Config.ComponentSlots[slot]
        if cfg and slot ~= 2 then
            controls[#controls + 1] = {
                id = tostring(slot),
                label = titleize(cfg.name),
                maxDrawable = cfg.maxDrawable,
                maxTexture = cfg.maxTexture
            }
        end
    end

    return controls
end

local function buildPropControls()
    local slots = Config.ShowExtendedEditorOptions and Config.ExtendedEditorPropSlots or Config.BasicEditorPropSlots
    local controls = {}

    for _, slot in ipairs(slots or {}) do
        local cfg = Config.PropSlots[slot]
        if cfg then
            controls[#controls + 1] = {
                id = tostring(slot),
                label = titleize(cfg.name),
                maxDrawable = cfg.maxDrawable,
                maxTexture = cfg.maxTexture
            }
        end
    end

    return controls
end

local function buildEditorConfig()
    return {
        modelOptions = buildModelOptions(),
        allowedModels = getAllowedModels(),
        maxHairColor = Config.MaxHairColor,
        maxEyeColor = Config.MaxEyeColor,
        overlays = Config.HeadOverlays,
        overlayControls = buildOverlayControls(),
        componentControls = buildComponentControls(),
        propControls = buildPropControls(),
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
