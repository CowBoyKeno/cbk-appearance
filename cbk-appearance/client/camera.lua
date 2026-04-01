CameraController = {
    cam = nil,
    current = { angle = 0.0, radius = 1.85, height = 0.80, fov = 80.0 },
    target = { angle = 0.0, radius = 1.85, height = 0.80, fov = 80.0 }
}

local cameraProfiles = {
    full = { radius = 2.25, height = 0.80, fov = 80.0, focusBone = 0, focusZ = 0.65, defaultAngle = 0.0, zoomMin = 1.65, zoomMax = 3.35 },
    torso = { radius = 2.25, height = 0.35, fov = 34.0, focusBone = 24818, focusZ = 0.1, defaultAngle = 0.0, zoomMin = 1.15, zoomMax = 2.90 },
    head = { radius = 2.25, height = 0.65, fov = 22.0, focusBone = 31086, focusZ = 0.02, defaultAngle = 0.0, zoomMin = 0.55, zoomMax = 2.65 },
    feet = { radius = 1.85, height = -0.55, fov = 28.0, focusBone = 0, focusZ = -0.95, defaultAngle = 0.0, zoomMin = 0.95, zoomMax = 2.50 },
    left = { radius = 2.25, height = 0.65, fov = 24.0, focusBone = 31086, focusZ = 0.02, defaultAngle = -90.0, zoomMin = 0.55, zoomMax = 2.65 },
    right = { radius = 2.25, height = 0.65, fov = 24.0, focusBone = 31086, focusZ = 0.02, defaultAngle = 90.0, zoomMin = 0.55, zoomMax = 2.65 }
}

local function clamp(value, min, max)
    if min > max then
        min, max = max, min
    end

    if value < min then return min end
    if value > max then return max end
    return value
end

local function getProfile(mode)
    return cameraProfiles[mode] or cameraProfiles.full
end

local function getFocusPos(ped, mode)
    local profile = getProfile(mode)
    local bone = profile.focusBone or 0
    local pos = bone ~= 0 and GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0) or GetEntityCoords(ped)
    return vec3(pos.x, pos.y, pos.z + (profile.focusZ or 0.0))
end

local function ensureCamera()
    if CameraController.cam then
        return CameraController.cam
    end

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 350, true, true)
    CameraController.cam = cam
    return cam
end

local function wrapAngle(angle)
    while angle > 180.0 do angle = angle - 360.0 end
    while angle < -180.0 do angle = angle + 360.0 end
    return angle
end

local function updateCameraNow()
    if not CameraController.cam or not CreatorState.open then
        return
    end

    local ped = PlayerPedId()
    local profile = getProfile(CreatorState.cameraMode)
    local focusPos = getFocusPos(ped, CreatorState.cameraMode)

    local angleRad = math.rad(CameraController.current.angle)
    local localX = math.sin(angleRad) * CameraController.current.radius
    local localY = math.cos(angleRad) * CameraController.current.radius
    local camPos = GetOffsetFromEntityInWorldCoords(ped, localX, localY, CameraController.current.height)

    SetCamCoord(CameraController.cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(CameraController.cam, focusPos.x, focusPos.y, focusPos.z)
    SetCamFov(CameraController.cam, CameraController.current.fov + 0.0)
end

function CameraController.Create(mode)
    CreatorState.cameraMode = mode or 'full'
    local profile = getProfile(CreatorState.cameraMode)

    local cam = ensureCamera()
    CameraController.target.radius = profile.radius
    CameraController.target.height = profile.height
    CameraController.target.fov = profile.fov
    CameraController.target.angle = profile.defaultAngle

    if not cam then
        return
    end

    if CameraController.current.radius == 0.0 then
        CameraController.current.radius = profile.radius
        CameraController.current.height = profile.height
        CameraController.current.fov = profile.fov
        CameraController.current.angle = profile.defaultAngle
    end

    updateCameraNow()
end

function CameraController.SetMode(mode)
    CameraController.Create(mode)
end

function CameraController.Rotate(delta)
    CameraController.target.angle = wrapAngle(CameraController.target.angle + (delta or 0.0))
end

function CameraController.Zoom(delta)
    local profile = getProfile(CreatorState.cameraMode)
    local minRadius = profile.zoomMin or math.max(0.5, profile.radius - 0.75)
    local maxRadius = profile.zoomMax or (profile.radius + 0.75)
    CameraController.target.radius = clamp(CameraController.target.radius + (delta or 0.0), minRadius, maxRadius)
end

function CameraController.Destroy()
    if CameraController.cam then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(CameraController.cam, false)
        CameraController.cam = nil
    end

    CameraController.current = { angle = 0.0, radius = 0.0, height = 0.0, fov = 0.0 }
    CameraController.target = { angle = 0.0, radius = 0.0, height = 0.0, fov = 0.0 }
end

CreateThread(function()
    while true do
        if CameraController.cam and CreatorState.open then
            local angleDelta = wrapAngle(CameraController.target.angle - CameraController.current.angle)
            CameraController.current.angle = wrapAngle(CameraController.current.angle + (angleDelta * 0.18))
            CameraController.current.radius = CameraController.current.radius + ((CameraController.target.radius - CameraController.current.radius) * 0.18)
            CameraController.current.height = CameraController.current.height + ((CameraController.target.height - CameraController.current.height) * 0.18)
            CameraController.current.fov = CameraController.current.fov + ((CameraController.target.fov - CameraController.current.fov) * 0.18)
            updateCameraNow()
            Wait(0)
        else
            Wait(250)
        end
    end
end)
