Config = {}

Config.Debug = false
Config.Command = 'appearance'
Config.DefaultModel = 'mp_m_freemode_01'
Config.AllowFemaleModel = true
Config.SaveCooldownMs = 7000
Config.ServerAuthoritative = true
Config.AuthoritativeReapplyMs = 15000
Config.EnableVariationProfileValidation = true
Config.AutoOpenIfNoSavedAppearance = true
Config.ShowExtendedEditorOptions = true
Config.EnableRoutingBucketIsolation = false
Config.CreatorBucket = 4040

Config.AllowedModelNames = {
    'mp_m_freemode_01',
    'mp_f_freemode_01'
}

Config.AllowedModels = {
    [`mp_m_freemode_01`] = true,
    [`mp_f_freemode_01`] = true
}

Config.Heritage = {
    maxParentIndex = 45
}

Config.FaceFeatureCount = 20
Config.MaxOpacity = 1.0
Config.MinOpacity = 0.0
Config.MinFeatureValue = -1.0
Config.MaxFeatureValue = 1.0
Config.MaxHairColor = 63
Config.MaxEyeColor = 31

Config.ComponentSlots = {
    [0] = { name = 'face', maxDrawable = 255, maxTexture = 63 },
    [1] = { name = 'mask', maxDrawable = 255, maxTexture = 63 },
    [2] = { name = 'hair', maxDrawable = 255, maxTexture = 63 },
    [3] = { name = 'torso', maxDrawable = 255, maxTexture = 63 },
    [4] = { name = 'legs', maxDrawable = 255, maxTexture = 63 },
    [5] = { name = 'bags', maxDrawable = 255, maxTexture = 63 },
    [6] = { name = 'shoes', maxDrawable = 255, maxTexture = 63 },
    [7] = { name = 'accessory', maxDrawable = 255, maxTexture = 63 },
    [8] = { name = 'undershirt', maxDrawable = 255, maxTexture = 63 },
    [9] = { name = 'armor', maxDrawable = 255, maxTexture = 63 },
    [10] = { name = 'decal', maxDrawable = 255, maxTexture = 63 },
    [11] = { name = 'tops', maxDrawable = 255, maxTexture = 63 }
}

Config.PropSlots = {
    [0] = { name = 'hat', maxDrawable = 255, maxTexture = 63 },
    [1] = { name = 'glasses', maxDrawable = 255, maxTexture = 63 },
    [2] = { name = 'ears', maxDrawable = 255, maxTexture = 63 },
    [6] = { name = 'watch', maxDrawable = 255, maxTexture = 63 },
    [7] = { name = 'bracelet', maxDrawable = 255, maxTexture = 63 }
}

Config.HeadOverlays = {
    [0] = { name = 'blemishes', maxIndex = 23, colorType = 0 },
    [1] = { name = 'facial_hair', maxIndex = 28, colorType = 1 },
    [2] = { name = 'eyebrows', maxIndex = 33, colorType = 1 },
    [3] = { name = 'ageing', maxIndex = 14, colorType = 0 },
    [4] = { name = 'makeup', maxIndex = 74, colorType = 2 },
    [5] = { name = 'blush', maxIndex = 6, colorType = 2 },
    [6] = { name = 'complexion', maxIndex = 11, colorType = 0 },
    [7] = { name = 'sun_damage', maxIndex = 10, colorType = 0 },
    [8] = { name = 'lipstick', maxIndex = 9, colorType = 2 },
    [9] = { name = 'moles_freckles', maxIndex = 17, colorType = 0 },
    [10] = { name = 'chest_hair', maxIndex = 16, colorType = 1 },
    [11] = { name = 'body_blemishes', maxIndex = 11, colorType = 0 }
}

Config.BasicEditorOverlaySlots = { 1, 2, 4, 5, 8 }
Config.ExtendedEditorOverlaySlots = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
Config.BasicEditorComponentSlots = { 3, 4, 6, 8, 11 }
Config.ExtendedEditorComponentSlots = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
Config.BasicEditorPropSlots = { 0, 1 }
Config.ExtendedEditorPropSlots = { 0, 1, 2, 6, 7 }

Config.OptionLabels = {
    hairStyles = {
        mp_m_freemode_01 = {},
        mp_f_freemode_01 = {}
    },
    overlays = {},
    components = {},
    props = {}
}

Config.DefaultAppearance = {
    version = 1,
    model = 'mp_m_freemode_01',
    heritage = {
        shapeFirst = 0, shapeSecond = 21, skinFirst = 0, skinSecond = 21,
        shapeMix = 0.5, skinMix = 0.5
    },
    faceFeatures = {
        0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,
        0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
    },
    hair = {
        style = 0,
        color = 0,
        highlight = 0
    },
    eyes = {
        color = 0
    },
    headOverlays = {
        ["1"] = { style = 0, opacity = 0.0, color = 0, secondColor = 0 },
        ["2"] = { style = 0, opacity = 0.0, color = 0, secondColor = 0 },
        ["4"] = { style = 0, opacity = 0.0, color = 0, secondColor = 0 },
        ["5"] = { style = 0, opacity = 0.0, color = 0, secondColor = 0 },
        ["8"] = { style = 0, opacity = 0.0, color = 0, secondColor = 0 }
    },
    components = {
        ["3"] = { drawable = 15, texture = 0 },
        ["4"] = { drawable = 21, texture = 0 },
        ["6"] = { drawable = 34, texture = 0 },
        ["8"] = { drawable = 15, texture = 0 },
        ["11"] = { drawable = 15, texture = 0 }
    },
    props = {
        ["0"] = { drawable = -1, texture = 0 },
        ["1"] = { drawable = -1, texture = 0 }
    }
}
