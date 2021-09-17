local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local PlayerData = require(GameModules:FindFirstChild("PlayerData"))

---

return {
    UnitType = GameEnum.UnitType.TowerUnit,
    AbilityType = GameEnum.AbilityType.RoundStart,

    Callback = function(thisUnit)
        PlayerData.DepositCurrencyToPlayer(thisUnit.Owner, GameEnum.CurrencyType.Points, 750)
    end
}