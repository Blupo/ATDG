local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Game = require(GameModules:FindFirstChild("Game"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local System = SystemCoordinator.newSystem("GameStats")

---

local playersStats = {}
local unitDamageTakenConnections = {}

---

local GameStats = {}

GameStats.IncrementPlayerStat = function(userId: number, stat: string, increment: number)
    local stats = playersStats[userId]
    if (not stats) then return end

    stats[stat] = (stats[stat] or 0) + increment
end

GameStats.GetGameStats = function(): {[string]: number}
    local stats = {}

    for stat in pairs(GameEnum.GameStat) do
        if (stat == GameEnum.GameStat.TimePlayed) then
            stats[stat] = Game.GetDerivedGameState().PlayTime
        end
    end

    return stats
end

GameStats.GetPlayerStats = function(userId: number): {[string]: number}
    return playersStats[userId]
end

GameStats.GetStats = function(userId: number): {[string]: number}
    local gameStats = GameStats.GetGameStats()
    local playerStats = GameStats.GetPlayerStats(userId)
    local mergedStats = {}

    for stat, value in pairs(gameStats) do
        mergedStats[stat] = value
    end

    for stat, value in pairs(playerStats) do
        mergedStats[stat] = value
    end

    return mergedStats
end

---

Players.PlayerAdded:Connect(function(player)
    playersStats[player.UserId] = {}
end)

Players.PlayerRemoving:Connect(function(player)
    local stats = playersStats[player.UserId]
    if (not stats) then return end

    playersStats[player.UserId] = nil
end)

Unit.UnitAdded:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    if (not unit) then return end

    unitDamageTakenConnections[unitId] = unit.DamageTaken:Connect(function(damage: number, damageSourceType: string, damageSource: string | number | nil)
        if (damageSourceType ~= GameEnum.DamageSourceType.Unit) then return end

        local sourceUnit = Unit.fromId(damageSource)
        local sourceUnitOwner = sourceUnit.Owner

        GameStats.IncrementPlayerStat(sourceUnitOwner, GameEnum.PlayerStat.TotalDMG, damage)
    end)
end)

Unit.UnitRemoving:Connect(function(unitId)
    if (unitDamageTakenConnections[unitId]) then
        unitDamageTakenConnections[unitId]:Disconnect()
        unitDamageTakenConnections[unitId] = nil
    end
end)

System.addFunction("GetGameStats", GameStats.GetGameStats)

System.addFunction("GetPlayerStats", t.wrap(function(callingPlayer: Player, userId: number)
    if (callingPlayer.UserId ~= userId) then return end

    return GameStats.GetPlayerStats(userId)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

System.addFunction("GetStats", t.wrap(function(callingPlayer: Player, userId: number)
    if (callingPlayer.UserId ~= userId) then return end

    return GameStats.GetStats(userId)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

return GameStats