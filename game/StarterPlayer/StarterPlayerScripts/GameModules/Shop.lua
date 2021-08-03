local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local PlayerScripts = script.Parent.Parent
local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local Shop = SystemCoordinator.getSystem("Shop")

---

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

Shop.GetUnitSellingPrice = function(unitId: string): number?
    local unit = Unit.fromId(unitId)
    if (not unit) then return end

    local unitSpending = ShopPrices.ObjectPlacementPrices[GameEnum.ObjectType.Unit][unit.Name]
    local unitUpgradePrices = ShopPrices.UnitUpgradePrices[unit.Name]

    for i = 2, unit.Level do
        local levelUpgradePrices = unitUpgradePrices[i]

        unitSpending = unitSpending + (levelUpgradePrices and levelUpgradePrices.Individual or 0)
    end

    return (unitSpending / 2)
end

---

return Shop