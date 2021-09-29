local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local StatusEffects = require(GameModules:FindFirstChild("StatusEffects"))

---

return {
    UnitType = GameEnum.UnitType.FieldUnit,
    AbilityType = GameEnum.AbilityType.OnApply,

    Callback = function(thisUnit)
        StatusEffects.ApplyEffect(thisUnit.Id, "InnateFrost", 86400)
    end
}