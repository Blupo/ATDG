local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SpecialActionData = ReplicatedStorage:FindFirstChild("SpecialActionData")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local ClientScripts = PlayerScripts:WaitForChild("ClientScripts")
local EventProxy = require(ClientScripts:WaitForChild("EventProxy"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local TimeSyncService = require(SharedModules:WaitForChild("TimeSyncService"))

local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")
local SpecialActions = SystemCoordinator.waitForSystem("SpecialActions")

---

local syncedClock = TimeSyncService:GetSyncedClock()
local serverType = ServerMaster.GetServerType() or ServerMaster.ServerInitialised:Wait()

local actionDataCache = {}
local localPlayerActionUsageCooldownExpirys = {}
local localPlayerActionUsageCounts = {}

local localPlayerProxy = function(mainCallback, proxyCallback)
    return function(userId, ...)
        if (userId == LocalPlayer.UserId) then
            return proxyCallback(userId, ...)
        else
            return mainCallback(userId, ...)
        end
    end
end

---

if (serverType == GameEnum.ServerType.Game) then
    SpecialActions.ActionUsed = EventProxy(SpecialActions.ActionUsed, function(userId: number, action: string, cooldownExpires: number, usageCount: number)
        if (userId ~= LocalPlayer.UserId) then return end

        localPlayerActionUsageCooldownExpirys[action] = cooldownExpires
        localPlayerActionUsageCounts[action] = usageCount
    end)
end

---

local CacheProxy = {}

CacheProxy.DoesActionExist = function(actionName: string): boolean
    return actionDataCache[actionName] and true or false
end

CacheProxy.GetActionData = function(action: string)
    return CopyTable(actionDataCache[action])
end

if (serverType == GameEnum.ServerType.Game) then
    CacheProxy.GetPlayerActionCooldownExpiry = localPlayerProxy(SpecialActions.GetPlayerActionCooldownExpiry, function(_, action: string)
        if (not CacheProxy.DoesActionExist(action)) then return end

        return localPlayerActionUsageCooldownExpirys[action] or 0
    end)

    CacheProxy.GetPlayerActionUsageCount = localPlayerProxy(SpecialActions.GetPlayerActionUsageCount, function(_, action: string)
        if (not CacheProxy.DoesActionExist(action)) then return end

        return localPlayerActionUsageCounts[action] or 0
    end)

    CacheProxy.CanPlayerUseAction = localPlayerProxy(SpecialActions.CanPlayerUseAction, function(_, action: string)
        if (not CacheProxy.DoesActionExist(action)) then return end

        local actionLimits = actionDataCache[action].Limits
        local cooldownExpiry = CacheProxy.GetPlayerActionCooldownExpiry(LocalPlayer.UserId, action)
        local usageCount = CacheProxy.GetPlayerActionUsageCount(LocalPlayer.UserId, action)

        return (syncedClock:GetTime() >= cooldownExpiry) and (usageCount < (actionLimits[GameEnum.SpecialActionLimitType.PlayerLimit] or math.huge))
    end)
end

---

if (serverType == GameEnum.ServerType.Game) then
    localPlayerActionUsageCooldownExpirys = SpecialActions.GetPlayerAllActionsCooldownExpirys(LocalPlayer.UserId)
    localPlayerActionUsageCounts = SpecialActions.GetPlayerAllActionsUsageCounts(LocalPlayer.UserId)
end

local actions = SpecialActions.GetActions()

for action in pairs(actions) do
    local actionDataScript = SpecialActionData:WaitForChild(action)

    actionDataCache[action] = require(actionDataScript)
end

return setmetatable(CacheProxy, { __index = SpecialActions })