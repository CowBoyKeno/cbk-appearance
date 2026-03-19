local function lockPlayerState(state)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
    SetEntityInvincible(ped, state)
    SetPlayerInvincible(PlayerId(), state)
    DisplayRadar(not state)

    if state then
        SetEntityHeading(ped, 180.0)
    end
end

local function markAuthoritativeApplied()
    CreatorState.authoritativeAppliedAt = GetGameTimer()
end

local function requestAuthoritativeAppearance()
    if Config.ServerAuthoritative then
        TriggerServerEvent('cbk_appearance:server:requestAuthoritativeAppearance')
    end
end

local variationProfilesSynced = false
local variationProfilesSyncing = false

local function syncVariationProfiles(force)
    if not Config.EnableVariationProfileValidation then
        return true
    end

    if variationProfilesSynced and not force then
        return true
    end

    if variationProfilesSyncing then
        while variationProfilesSyncing do
            Wait(50)
        end

        return variationProfilesSynced
    end

    variationProfilesSyncing = true
    local profiles = ClientUtils.BuildVariationProfiles(ClientUtils.GetAllowedModels())
    variationProfilesSyncing = false

    if profiles and #profiles > 0 then
        TriggerServerEvent('cbk_appearance:server:syncVariationProfiles', profiles)
        variationProfilesSynced = true
        return true
    end

    return false
end

local function requestOpenCreator()
    CreateThread(function()
        syncVariationProfiles(false)
        TriggerServerEvent('cbk_appearance:server:requestOpen')
    end)
end

local function checkAutoOpen()
    if Config.AutoOpenIfNoSavedAppearance then
        TriggerServerEvent('cbk_appearance:server:checkAutoOpen')
    end
end

local function applyAuthoritativeAppearance(appearance, applyNow)
    if not appearance then
        return
    end

    local normalized = Appearance.Normalize(appearance)
    CreatorState.authoritativeAppearance = normalized

    if applyNow == false or CreatorState.open or CreatorState.opening then
        return
    end

    CreatorState.appearance = Appearance.Normalize(normalized)
    Appearance.Apply(CreatorState.appearance)
    markAuthoritativeApplied()
end

local function enterCreator(appearance, sessionNonce)
    if CreatorState.open or CreatorState.opening then
        return
    end

    CreatorState.opening = true
    CreatorState.sessionNonce = sessionNonce
    CreatorState.baseline = Appearance.Normalize(appearance)
    CreatorState.appearance = Appearance.Normalize(appearance)
    CreatorState.authoritativeAppearance = Appearance.Normalize(appearance)

    lockPlayerState(true)
    Appearance.Apply(CreatorState.appearance)
    CreatorState.appearance = Appearance.HydrateWearablesFromPed(CreatorState.appearance)
    CreatorState.baseline = Appearance.Normalize(CreatorState.appearance)
    CreatorState.authoritativeAppearance = Appearance.Normalize(CreatorState.appearance)
    CameraController.Create('full')
    OpenAppearanceUI(CreatorState.appearance)

    CreatorState.open = true
    CreatorState.opening = false
end

local function exitCreator(applyBaseline)
    if not CreatorState.open then
        return
    end

    if applyBaseline and CreatorState.baseline then
        Appearance.Apply(CreatorState.baseline)
    end

    CloseAppearanceUI()
    CameraController.Destroy()
    lockPlayerState(false)
    TriggerServerEvent('cbk_appearance:server:sessionClosed')
    CreatorState.ResetSession()
end

RegisterNetEvent('cbk_appearance:client:open', function(appearance, sessionNonce)
    enterCreator(appearance, sessionNonce)
end)

RegisterNetEvent('cbk_appearance:client:applyAuthoritativeAppearance', function(appearance)
    applyAuthoritativeAppearance(appearance, true)
end)

RegisterNetEvent('cbk_appearance:client:saveResult', function(ok, appearance, err)
    if not CreatorState.open then return end

    CreatorState.pendingSave = false
    CreatorState.saveStartedAt = 0

    if not ok then
        UpdateAppearanceUI({
            action = 'saveState',
            saving = false,
            error = err or 'unknown_error',
            message = 'Save failed. Please try again.'
        })
        ClientUtils.Notify(('Appearance save failed: %s'):format(err or 'unknown'))
        return
    end

    CreatorState.baseline = Appearance.Normalize(appearance)
    CreatorState.appearance = Appearance.Normalize(appearance)
    CreatorState.authoritativeAppearance = Appearance.Normalize(appearance)
    Appearance.Apply(CreatorState.appearance)
    markAuthoritativeApplied()
    UpdateAppearanceUI({
        action = 'saveState',
        saving = false,
        success = true,
        message = 'Appearance saved.'
    })
    ClientUtils.Notify('Appearance saved.')
    exitCreator(false)
end)

RegisterNetEvent('cbk_appearance:client:cancel', function()
    if CreatorState.pendingSave then
        UpdateAppearanceUI({
            action = 'saveState',
            saving = false,
            error = 'save_cancelled',
            message = 'Save was cancelled.'
        })
    end
    exitCreator(true)
end)

RegisterCommand(Config.Command, function()
    requestOpenCreator()
end, false)

exports('OpenCreator', function()
    requestOpenCreator()
end)

exports('ApplyAppearance', function(appearance)
    CreatorState.appearance = Appearance.Normalize(appearance)
    return Appearance.Apply(CreatorState.appearance)
end)

exports('GetAppearance', function()
    return Appearance.GetCurrent()
end)

AddEventHandler('playerSpawned', function()
    CreateThread(function()
        Wait(1500)
        syncVariationProfiles(false)
        requestAuthoritativeAppearance()
        checkAutoOpen()
    end)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        Wait(1000)
        syncVariationProfiles(false)
        requestAuthoritativeAppearance()
        checkAutoOpen()
    end)
end)

CreateThread(function()
    while true do
        if CreatorState.open then
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 322, true)
            EnableControlAction(0, 200, true)
            EnableControlAction(0, 202, true)
            EnableControlAction(0, 241, true)
            EnableControlAction(0, 242, true)

            if IsDisabledControlJustPressed(0, 202) then
                TriggerEvent('cbk_appearance:client:cancel')
            end

            local lookX = GetDisabledControlNormal(0, 1)
            if math.abs(lookX) > 0.01 then
                CameraController.Rotate(lookX * 4.0)
            end

            if IsDisabledControlJustPressed(0, 241) then
                CameraController.Zoom(-0.08)
            elseif IsDisabledControlJustPressed(0, 242) then
                CameraController.Zoom(0.08)
            end

            if CreatorState.pendingSave and CreatorState.saveStartedAt > 0 and (GetGameTimer() - CreatorState.saveStartedAt) > 10000 then
                CreatorState.pendingSave = false
                CreatorState.saveStartedAt = 0
                UpdateAppearanceUI({
                    action = 'saveState',
                    saving = false,
                    error = 'timeout',
                    message = 'Save timed out.'
                })
                ClientUtils.Notify('Appearance save timed out.')
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if Config.ServerAuthoritative and not CreatorState.open and not CreatorState.opening and CreatorState.authoritativeAppearance then
            local interval = math.max(5000, tonumber(Config.AuthoritativeReapplyMs) or 15000)
            local now = GetGameTimer()

            if CreatorState.authoritativeAppliedAt == 0 or (now - CreatorState.authoritativeAppliedAt) >= interval then
                applyAuthoritativeAppearance(CreatorState.authoritativeAppearance, true)
            end

            Wait(1000)
        else
            Wait(1500)
        end
    end
end)
