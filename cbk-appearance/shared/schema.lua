AppearanceSchema = {}

function AppearanceSchema.DeepCopy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for k, v in pairs(value) do
        out[k] = AppearanceSchema.DeepCopy(v)
    end
    return out
end

function AppearanceSchema.GetDefault()
    return AppearanceSchema.DeepCopy(Config.DefaultAppearance)
end
