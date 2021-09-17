local Players = game:GetService("Players")
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
        local players = Players:GetPlayers()

        for i = 1, #players do
            local player = players[i]

            PlayerData.DepositCurrencyToPlayer(player.UserId, GameEnum.CurrencyType.Points, (player.UserId == thisUnit.Owner) and 1000 or 750)
        end
    end
}