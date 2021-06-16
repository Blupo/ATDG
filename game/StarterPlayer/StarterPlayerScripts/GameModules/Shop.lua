local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local PlayerScripts = script.Parent.Parent
local Util = PlayerScripts:WaitForChild("Util")
local RemoteFunctionWrapper = require(Util:WaitForChild("RemoteFunctionWrapper"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local ShopPrices = require(SharedModules:FindFirstChild("ShopPrices"))

local Communicators = ReplicatedStorage:WaitForChild("Communicators"):WaitForChild("Shop")
local PurchaseTickets = Communicators:WaitForChild("PurchaseTickets")
local PurchaseObjectGrant = Communicators:WaitForChild("PurchaseObjectGrant")
local PurchaseSpecialActionToken = Communicators:WaitForChild("PurchaseSpecialActionToken")
local PurchaseObjectPlacement = Communicators:WaitForChild("PurchaseObjectPlacement")
local PurchaseUnitUpgrade = Communicators:WaitForChild("PurchaseUnitUpgrade")
local PurchaseUnitPersistentUpgrade = Communicators:WaitForChild("PurchaseUnitPersistentUpgrade")

---

local Shop = {}

Shop.PurchaseTickets = RemoteFunctionWrapper(PurchaseTickets)
Shop.PurchaseObjectGrant = RemoteFunctionWrapper(PurchaseObjectGrant)
Shop.PurchaseSpecialActionToken = RemoteFunctionWrapper(PurchaseSpecialActionToken)
Shop.PurchaseObjectPlacement = RemoteFunctionWrapper(PurchaseObjectPlacement)
Shop.PurchaseUnitUpgrade = RemoteFunctionWrapper(PurchaseUnitUpgrade)
Shop.PurchaseUnitPersistentUpgrade = RemoteFunctionWrapper(PurchaseUnitPersistentUpgrade)

Shop.GetObjectGrantPrice = function(objectType: string, objectName: string): number?
    return ShopPrices.ObjectGrantPrices[objectType][objectName]
end

Shop.GetObjectPlacementPrice = function(objectType: string, objectName: string): number?
    return ShopPrices.ObjectPlacementPrices[objectType][objectName]
end

Shop.GetUnitUpgradePrice = function(unitId: string): number?
    local unit = Unit.fromId(unitId)
    if (not unit) then return end

    local unitPrices = ShopPrices.UnitUpgradePrices[unit.Name]
    if (not unitPrices) then return end

    local prices = unitPrices[unit.Level + 1]
    if (not prices) then return end

    return prices.Individual
end

Shop.GetUnitPersistentUpgradePrice = function(owner: number, unitName: string): number?
    local currentLevel = Unit.GetUnitPersistentUpgradeLevel(owner, unitName)
    if (not currentLevel) then return end

    local unitPrices = ShopPrices.UnitUpgradePrices[unitName]
    if (not unitPrices) then return end

    local prices = unitPrices[currentLevel + 1]
    if (not prices) then return end

    return prices.Persistent
end

---

return Shop