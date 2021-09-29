local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    EffectType = GameEnum.StatusEffectType.Lingering,
    OnApplying = function() end,
    Interactions = {},
}