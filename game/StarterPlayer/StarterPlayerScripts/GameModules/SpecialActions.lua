local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local SpecialActions = SystemCoordinator.waitForSystem("SpecialActions")

---

local specialActionsUsageLimits = {}

---

local CacheProxy = {}

CacheProxy.GetAllSpecialActionsUsageLimits = function()
    return specialActionsUsageLimits
end

CacheProxy.GetSpecialActionUsageLimits = function(actionName: string)
    return specialActionsUsageLimits[actionName]
end

---

specialActionsUsageLimits = SpecialActions.GetAllSpecialActionsUsageLimits()

return setmetatable(CacheProxy, { __index = SpecialActions })