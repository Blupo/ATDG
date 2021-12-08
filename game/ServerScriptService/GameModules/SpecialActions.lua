local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SpecialActionCallbacks = ServerScriptService:FindFirstChild("SpecialActionCallbacks")
local SpecialActionData = ReplicatedStorage:FindFirstChild("SpecialActionData")

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local PlayerData = require(GameModules:FindFirstChild("PlayerData"))
local ServerMaster = require(GameModules:FindFirstChild("ServerMaster"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))
local TimeSyncService = require(SharedModules:FindFirstChild("TimeSyncService"))

local ActionUsedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("SpecialActions")

---

local syncedClock = TimeSyncService:GetSyncedClock()
local serverType = ServerMaster.GetServerType() or ServerMaster.ServerInitialised:Wait()

local actionDataCache = {}
local actionCallbackCache = {}

local actionUsageCooldownExpirys = {}
local actionUsageCounts = {}

---

local SpecialActions = {}

SpecialActions.DoesActionExist = function(actionName: string): boolean
    return actionDataCache[actionName] and actionCallbackCache[actionName]
end

SpecialActions.GetActions = function()
    local actions = {}

    for action in pairs(actionDataCache) do
        if (SpecialActions.DoesActionExist(action)) then
            actions[action] = true
        end
    end

    return actions
end

if (serverType == GameEnum.ServerType.Game) then
    SpecialActions.ActionUsed = ActionUsedEvent.Event

    SpecialActions.GetPlayerActionCooldownExpiry = function(userId: number, action: string): number?
        if (not SpecialActions.DoesActionExist(action)) then return end

        return actionUsageCooldownExpirys[action][userId] or 0
    end

    SpecialActions.GetPlayerActionUsageCount = function(userId: number, action: string): number?
        if (not SpecialActions.DoesActionExist(action)) then return end

        return actionUsageCounts[action][userId] or 0
    end

    SpecialActions.GetPlayerAllActionsCooldownExpirys = function(userId: number)
        local actions = SpecialActions.GetActions()
        local cooldownExpirys = {}

        for action in pairs(actions) do
            cooldownExpirys[action] = SpecialActions.GetPlayerActionCooldownExpiry(userId, action)
        end

        return cooldownExpirys
    end

    SpecialActions.GetPlayerAllActionsUsageCounts = function(userId: number)
        local actions = SpecialActions.GetActions()
        local usageCounts = {}

        for action in pairs(actions) do
            usageCounts[action] = SpecialActions.GetPlayerActionUsageCount(userId, action)
        end

        return usageCounts
    end

    SpecialActions.CanPlayerUseAction = function(userId: number, action: string): boolean
        if (not SpecialActions.DoesActionExist(action)) then return end

        local actionLimits = actionDataCache[action].Limits
        local cooldownExpiry = SpecialActions.GetPlayerActionCooldownExpiry(userId, action)
        local usageCount = SpecialActions.GetPlayerActionUsageCount(userId, action)

        return (syncedClock:GetTime() >= cooldownExpiry) and (usageCount < (actionLimits[GameEnum.SpecialActionLimitType.PlayerLimit] or math.huge))
    end

    SpecialActions.UseAction = function(userId: number, action: string): boolean
        if (not SpecialActions.DoesActionExist(action)) then return false end
        if (not SpecialActions.CanPlayerUseAction(userId, action)) then return false end

        local specialActionTokenCount = PlayerData.GetPlayerInventoryItemCount(userId, GameEnum.ItemType.SpecialAction, action)
        if ((specialActionTokenCount or 0) < 1) then return false end

        local usageCounts = actionUsageCounts[action]
        local usageCooldownExpiry = actionUsageCooldownExpirys[action]

        local actionLimits = actionDataCache[action].Limits
        local actionCallback = actionCallbackCache[action]

        local callbackResult = actionCallback()
        if (callbackResult == false) then return false end

        local now = syncedClock:GetTime()
        local newUsageCount = (usageCounts[userId] or 0) + 1
        local newUsageCooldownExpiry = now + (actionLimits[GameEnum.SpecialActionLimitType.PlayerCooldown] or 0)

        usageCounts[userId] = newUsageCount
        usageCooldownExpiry[userId] = newUsageCooldownExpiry
        PlayerData.RemoveItemFromInventory(userId, GameEnum.ItemType.SpecialAction, action, 1) -- TODO: what if this fails

        ActionUsedEvent:Fire(userId, action, newUsageCooldownExpiry, newUsageCount)
        return true
    end
end

---

for _, actionDataScript in pairs(SpecialActionData:GetChildren()) do
    local action = actionDataScript.Name

    if (actionDataScript:IsA("ModuleScript") and (not actionDataCache[action])) then
        actionDataCache[action] = require(actionDataScript)
        actionUsageCounts[action] = {}
        actionUsageCooldownExpirys[action] = {}
    end
end

for _, actionCallbackScript in pairs(SpecialActionCallbacks:GetChildren()) do
    local action = actionCallbackScript.Name

    if (actionCallbackScript:IsA("ModuleScript") and (not actionCallbackCache[action])) then
        actionCallbackCache[action] = require(actionCallbackScript)
    end
end

System.addFunction("GetActions", t.wrap(function()
    return SpecialActions.GetActions()
end, t.tuple(t.instanceOf("Player"))), true)

if (serverType == GameEnum.ServerType.Game) then
    System.addEvent("ActionUsed", SpecialActions.ActionUsed)

    System.addFunction("GetPlayerActionCooldownExpiry", t.wrap(function(callingPlayer: Player, userId: number, action: string)
        if (callingPlayer.UserId ~= userId) then return end

        return SpecialActions.GetPlayerActionCooldownExpiry(userId, action)
    end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)

    System.addFunction("GetPlayerActionUsageCount", t.wrap(function(callingPlayer: Player, userId: number, action: string)
        if (callingPlayer.UserId ~= userId) then return end

        return SpecialActions.GetPlayerActionUsageCount(userId, action)
    end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)

    System.addFunction("GetPlayerAllActionsCooldownExpirys", t.wrap(function(callingPlayer: Player, userId: number)
        if (callingPlayer.UserId ~= userId) then return end

        return SpecialActions.GetPlayerAllActionsCooldownExpirys(userId)
    end, t.tuple(t.instanceOf("Player"), t.number)), true)

    System.addFunction("GetPlayerAllActionsUsageCounts", t.wrap(function(callingPlayer: Player, userId: number)
        if (callingPlayer.UserId ~= userId) then return end

        return SpecialActions.GetPlayerAllActionsUsageCounts(userId)
    end, t.tuple(t.instanceOf("Player"), t.number)), true)

    System.addFunction("CanPlayerUseAction", t.wrap(function(callingPlayer: Player, userId: number, action: string)
        if (callingPlayer.UserId ~= userId) then return false end

        return SpecialActions.CanPlayerUseAction(userId, action)
    end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)
    
    System.addFunction("UseAction", t.wrap(function(callingPlayer: Player, userId: number, action: string)
        if (callingPlayer.UserId ~= userId) then return end

        return SpecialActions.UseAction(userId, action)
    end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)
end

return SpecialActions