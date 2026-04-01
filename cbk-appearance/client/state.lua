CreatorState = {
    open = false,
    opening = false,
    appearance = nil,
    baseline = nil,
    authoritativeAppearance = nil,
    authoritativeAppliedAt = 0,
    cameraMode = 'full',
    sessionNonce = nil,
    pendingSave = false,
    saveStartedAt = 0
}

function CreatorState.ResetSession()
    CreatorState.open = false
    CreatorState.opening = false
    CreatorState.appearance = nil
    CreatorState.baseline = nil
    CreatorState.cameraMode = 'full'
    CreatorState.sessionNonce = nil
    CreatorState.pendingSave = false
    CreatorState.saveStartedAt = 0
end
