local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SpecialActionData = ServerScriptService:FindFirstChild("SpecialActionData")

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local PlayerData = require(GameModules:FindFirstChild("PlayerData"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local MakeActionResult = require(SharedModules:FindFirstChild("MakeActionResult"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local SpecialActionUsedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("SpecialActions")

---

local specialActionDataCache = {}

local specialActionUsageTimes = {
    ActionName = {
        PlayerName = 0,
    }    
}

local specialActionUsageCounts = {
    ActionName = {
        PlayerName = 0,
    }
}

---

local SpecialActions = {
    SpecialActionUsed = SpecialActionUsedEvent.Event,
}

SpecialActions.UseSpecialAction = function(userId: number, actionName: string)
    local specialActionData = specialActionDataCache[actionName]
    if (not specialActionData) then return MakeActionResult(GameEnum.SpecialActionUsageResult.InvalidActionName) end

    local specialActionTokenCount = PlayerData.GetPlayerInventoryItemCount(userId, GameEnum.ItemType.SpecialAction, actionName)
    if ((not specialActionTokenCount) or (specialActionTokenCount < 1)) then return MakeActionResult(GameEnum.SpecialActionUsageResult.NoInventory) end

    -- check limits in the order: PlayerLimit, GameLimit, PlayerCooldowm, GameCooldown
    local specialActionLimits = specialActionData.Limits
    local actionUsageCounts = specialActionUsageCounts[actionName]
    local actionUsageTimes = specialActionUsageTimes[actionName]

    local playerUsageCount = actionUsageCounts[userId] or 0
    local playerLastUsageTime = actionUsageTimes[userId]

    local gameUsageCount = 0
    local gameLastUsageTime = 0

    for _, usageCount in pairs(actionUsageCounts) do
        gameUsageCount = gameUsageCount + usageCount
    end

    for _, lastUsageTime in pairs(actionUsageTimes) do
        gameLastUsageTime = ((gameLastUsageTime or 0) < lastUsageTime) and lastUsageTime or gameLastUsageTime
    end
    
    local now = os.clock()
    local playerUsageLimit = specialActionLimits[GameEnum.SpecialActionLimitType.PlayerLimit]
    local gameUsageLimit = specialActionLimits[GameEnum.SpecialActionLimitType.GameLimit]
    local playerUsageCooldown = specialActionLimits[GameEnum.SpecialActionLimitType.PlayerCooldown]
    local gameUsageCooldown = specialActionLimits[GameEnum.SpecialActionLimitType.GameCooldown]

    if (playerUsageLimit and (playerUsageCount >= playerUsageLimit)) then
        return MakeActionResult(GameEnum.SpecialActionUsageResult.PlayerLimited)
    end

    if (gameUsageLimit and (gameUsageCount >= gameUsageLimit)) then
        return MakeActionResult(GameEnum.SpecialActionUsageResult.GameLimited)
    end

    if (playerUsageCooldown and ((now - (playerLastUsageTime or 0)) < playerUsageCooldown)) then
        return MakeActionResult(GameEnum.SpecialActionUsageResult.PlayerCooldown)
    end

    if (gameUsageCooldown and ((now - (gameLastUsageTime or 0)) < gameUsageCooldown)) then
        return MakeActionResult(GameEnum.SpecialActionUsageResult.GameCooldown)
    end

    -- execute
    PlayerData.RemoveItemFromInventory(userId, GameEnum.ItemType.SpecialAction, actionName, 1)
    actionUsageCounts[userId] = (actionUsageCounts[userId] or 0) + 1
    actionUsageTimes[userId] = now

    specialActionData.Callback()
    SpecialActionUsedEvent:Fire(userId, actionName)

    return MakeActionResult()
end

---

for _, specialActionDataScript in pairs(SpecialActionData:GetChildren()) do
    local actionName = specialActionDataScript.Name

    if (specialActionDataScript:IsA("ModuleScript") and (not specialActionDataCache[actionName])) then
        specialActionDataCache[actionName] = require(specialActionDataScript)
        specialActionUsageCounts[actionName] = {}
        specialActionUsageTimes[actionName] = {}
    end
end

System.addEvent("SpecialActionUsed", SpecialActions.SpecialActionUsed)

System.addFunction("UseSpecialAction", t.wrap(function(callingPlayer: Player, userId: number, actionName: string)
    if (callingPlayer.UserId ~= userId) then return end

    return SpecialActions.UseSpecialAction(userId, actionName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)

return SpecialActions