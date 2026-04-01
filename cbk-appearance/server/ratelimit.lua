RateLimit = {}

local buckets = {}

function RateLimit.Check(key, playerId, cooldownMs)
    local now = os.clock() * 1000
    buckets[key] = buckets[key] or {}
    local expiresAt = buckets[key][playerId] or 0
    if now < expiresAt then
        return false, math.floor(expiresAt - now)
    end
    buckets[key][playerId] = now + cooldownMs
    return true, 0
end

function RateLimit.ClearPlayer(playerId)
    for _, bucket in pairs(buckets) do
        bucket[playerId] = nil
    end
end
