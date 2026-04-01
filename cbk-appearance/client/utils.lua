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

local variationProfileCache = {}

local heritageParents = {
    [0] = 'Benjamin',
    [1] = 'Daniel',
    [2] = 'Joshua',
    [3] = 'Noah',
    [4] = 'Andrew',
    [5] = 'Juan',
    [6] = 'Alex',
    [7] = 'Isaac',
    [8] = 'Evan',
    [9] = 'Ethan',
    [10] = 'Vincent',
    [11] = 'Angel',
    [12] = 'Diego',
    [13] = 'Adrian',
    [14] = 'Gabriel',
    [15] = 'Michael',
    [16] = 'Santiago',
    [17] = 'Kevin',
    [18] = 'Louis',
    [19] = 'Samuel',
    [20] = 'Anthony',
    [21] = 'Hannah',
    [22] = 'Audrey',
    [23] = 'Jasmine',
    [24] = 'Giselle',
    [25] = 'Amelia',
    [26] = 'Isabella',
    [27] = 'Zoe',
    [28] = 'Ava',
    [29] = 'Camila',
    [30] = 'Violet',
    [31] = 'Sophia',
    [32] = 'Evelyn',
    [33] = 'Nicole',
    [34] = 'Ashley',
    [35] = 'Gracie',
    [36] = 'Brianna',
    [37] = 'Natalie',
    [38] = 'Olivia',
    [39] = 'Elizabeth',
    [40] = 'Charlotte',
    [41] = 'Emma',
    [42] = 'John',
    [43] = 'Niko',
    [44] = 'Claude',
    [45] = 'Misty'
}

local hairColors = {
    [0] = { name = 'Black', hex = '#1C1B1A' },
    [1] = { name = 'Soft Black', hex = '#241F1C' },
    [2] = { name = 'Espresso', hex = '#2F2621' },
    [3] = { name = 'Dark Brown', hex = '#3D3028' },
    [4] = { name = 'Walnut Brown', hex = '#4C382D' },
    [5] = { name = 'Warm Brown', hex = '#5A4030' },
    [6] = { name = 'Chestnut', hex = '#6A4A37' },
    [7] = { name = 'Cinnamon', hex = '#79503A' },
    [8] = { name = 'Copper Brown', hex = '#8A5A40' },
    [9] = { name = 'Golden Brown', hex = '#9A6848' },
    [10] = { name = 'Hazel Brown', hex = '#7B6047' },
    [11] = { name = 'Ash Brown', hex = '#66584D' },
    [12] = { name = 'Mocha', hex = '#584337' },
    [13] = { name = 'Chocolate', hex = '#6B4E3B' },
    [14] = { name = 'Light Brown', hex = '#8D6D53' },
    [15] = { name = 'Honey Brown', hex = '#A37A56' },
    [16] = { name = 'Caramel', hex = '#B48254' },
    [17] = { name = 'Toffee', hex = '#BE8B58' },
    [18] = { name = 'Dark Blonde', hex = '#9A7A52' },
    [19] = { name = 'Sandy Blonde', hex = '#B18A58' },
    [20] = { name = 'Honey Blonde', hex = '#C09A5E' },
    [21] = { name = 'Golden Blonde', hex = '#D2B16A' },
    [22] = { name = 'Wheat Blonde', hex = '#DCC07C' },
    [23] = { name = 'Champagne Blonde', hex = '#E7D198' },
    [24] = { name = 'Platinum Blonde', hex = '#EDE1B9' },
    [25] = { name = 'Bleached Blonde', hex = '#F3E8C8' },
    [26] = { name = 'Pearl Blonde', hex = '#F5ECD8' },
    [27] = { name = 'Strawberry Blonde', hex = '#D69B79' },
    [28] = { name = 'Ginger', hex = '#B96F47' },
    [29] = { name = 'Copper', hex = '#A85D3B' },
    [30] = { name = 'Auburn', hex = '#874633' },
    [31] = { name = 'Deep Auburn', hex = '#70392F' },
    [32] = { name = 'Mahogany', hex = '#64342C' },
    [33] = { name = 'Burgundy', hex = '#5A2830' },
    [34] = { name = 'Cherry Red', hex = '#8A2D36' },
    [35] = { name = 'Crimson', hex = '#A12E34' },
    [36] = { name = 'Rosewood', hex = '#7A3941' },
    [37] = { name = 'Dusty Rose', hex = '#AA6A73' },
    [38] = { name = 'Rose Gold', hex = '#C98D81' },
    [39] = { name = 'Pastel Pink', hex = '#DDB2BC' },
    [40] = { name = 'Cotton Candy', hex = '#EAC9D5' },
    [41] = { name = 'Lavender', hex = '#AE9BC6' },
    [42] = { name = 'Lilac', hex = '#9A8DB8' },
    [43] = { name = 'Violet', hex = '#7F6FA4' },
    [44] = { name = 'Midnight Blue', hex = '#32415A' },
    [45] = { name = 'Denim Blue', hex = '#4C648E' },
    [46] = { name = 'Powder Blue', hex = '#9AB7D6' },
    [47] = { name = 'Seafoam', hex = '#84AE9C' },
    [48] = { name = 'Mint', hex = '#A9CDBD' },
    [49] = { name = 'Emerald', hex = '#3B6C54' },
    [50] = { name = 'Olive', hex = '#6B7747' },
    [51] = { name = 'Lime', hex = '#A8C65C' },
    [52] = { name = 'Sunflower', hex = '#D7BF4D' },
    [53] = { name = 'Amber', hex = '#CC9443' },
    [54] = { name = 'Tangerine', hex = '#D87937' },
    [55] = { name = 'Burnt Orange', hex = '#B55E33' },
    [56] = { name = 'Slate Gray', hex = '#72727A' },
    [57] = { name = 'Steel Gray', hex = '#8B8D93' },
    [58] = { name = 'Silver', hex = '#B9B7B2' },
    [59] = { name = 'Frost Silver', hex = '#D4D5D7' },
    [60] = { name = 'White Blonde', hex = '#EEE6D3' },
    [61] = { name = 'Snow White', hex = '#F5F3EE' },
    [62] = { name = 'Graphite', hex = '#3B3B40' },
    [63] = { name = 'Jet Black', hex = '#0D0D0D' }
}

local eyeColors = {
    [0] = { name = 'Green', hex = '#5E7E4C' },
    [1] = { name = 'Emerald', hex = '#3A7A5A' },
    [2] = { name = 'Light Blue', hex = '#8AB9E6' },
    [3] = { name = 'Ocean Blue', hex = '#4B80C2' },
    [4] = { name = 'Light Brown', hex = '#9C704D' },
    [5] = { name = 'Dark Brown', hex = '#5B3D2E' },
    [6] = { name = 'Hazel', hex = '#8B7A49' },
    [7] = { name = 'Dark Gray', hex = '#585C64' },
    [8] = { name = 'Light Gray', hex = '#9BA0A9' },
    [9] = { name = 'Pink', hex = '#CF8AA5' },
    [10] = { name = 'Yellow', hex = '#E2C94D' },
    [11] = { name = 'Purple', hex = '#8B67B4' },
    [12] = { name = 'Blackout', hex = '#101014' },
    [13] = { name = 'Shades Of Gray', hex = '#6E7280' },
    [14] = { name = 'Tequila Sunrise', hex = '#E08B4A' },
    [15] = { name = 'Atomic', hex = '#8FD756' },
    [16] = { name = 'Warp', hex = '#6D57D4' },
    [17] = { name = 'ECola', hex = '#C84343' },
    [18] = { name = 'Space Ranger', hex = '#47C7C7' },
    [19] = { name = 'Ying Yang', hex = '#D7D7D7' },
    [20] = { name = 'Bullseye', hex = '#C28F46' },
    [21] = { name = 'Lizard', hex = '#6AAE47' },
    [22] = { name = 'Dragon', hex = '#C06B33' },
    [23] = { name = 'Extra Terrestrial', hex = '#78C784' },
    [24] = { name = 'Goat', hex = '#B99363' },
    [25] = { name = 'Smiley', hex = '#E1C85A' },
    [26] = { name = 'Possessed', hex = '#E2D8C9' },
    [27] = { name = 'Demon', hex = '#B33434' },
    [28] = { name = 'Infected', hex = '#D9D76F' },
    [29] = { name = 'Alien', hex = '#82D86C' },
    [30] = { name = 'Undead', hex = '#C8E0D1' },
    [31] = { name = 'Zombie', hex = '#89A778' }
}

local function buildNamedOptions(maxIndex, entries, fallbackPrefix)
    local options = {}

    for index = 0, maxIndex do
        local entry = entries[index]
        local name = type(entry) == 'table' and entry.name or entry
        local hex = type(entry) == 'table' and entry.hex or nil

        options[#options + 1] = {
            value = index,
            label = name or ('%s %02d'):format(fallbackPrefix, index),
            hex = hex
        }
    end

    return options
end

function ClientUtils.StoreVariationProfile(profile)
    if type(profile) ~= 'table' or type(profile.model) ~= 'string' or profile.model == '' then
        return
    end

    variationProfileCache[profile.model] = profile
end

function ClientUtils.GetVariationProfile(modelName)
    return variationProfileCache[tostring(modelName or '')]
end

function ClientUtils.GetOrBuildVariationProfile(modelName)
    local model = tostring(modelName or '')
    if model == '' then
        return nil
    end

    local cached = ClientUtils.GetVariationProfile(model)
    if cached then
        return cached
    end

    local profile = ClientUtils.BuildVariationProfile(model)
    if profile then
        ClientUtils.StoreVariationProfile(profile)
    end

    return profile
end

function ClientUtils.GetHeritageOptions(maxIndex)
    return buildNamedOptions(maxIndex, heritageParents, 'Parent')
end

function ClientUtils.GetHairColorOptions(maxIndex)
    return buildNamedOptions(maxIndex, hairColors, 'Hair Color')
end

function ClientUtils.GetEyeColorOptions(maxIndex)
    return buildNamedOptions(maxIndex, eyeColors, 'Eye Color')
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
    ClientUtils.StoreVariationProfile(profile)
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
