local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local StatusEffects = require(GameModules:FindFirstChild("StatusEffects"))

---

return {
    UnitType = GameEnum.UnitType.TowerUnit,
    AbilityType = GameEnum.AbilityType.OnHit,

    Callback = function(_, data)
        StatusEffects.ApplyEffect(data.TargetUnit.Id, "Frozen", 3)
    end
}