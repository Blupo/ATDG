local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Unit = require(GameModules:FindFirstChild("Unit"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    Limits = {
        [GameEnum.SpecialActionLimitType.PlayerLimit] = 2,
        [GameEnum.SpecialActionLimitType.GameLimit] = nil,
        [GameEnum.SpecialActionLimitType.PlayerCooldown] = 120,
        [GameEnum.SpecialActionLimitType.GameCooldown] = 120,
    },

    Callback = function()
        local enemyUnits = Unit.GetUnits(function(unit): boolean
            return (unit.Type == GameEnum.UnitType.FieldUnit) and (unit.Owner == 0)
        end)

        for i = 1, #enemyUnits do
            enemyUnits[i]:TakeDamage(math.huge, GameEnum.DamageSourceType.Almighty, "SpecialAction.Expel_TEST", true)
        end
    end
}