local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local GameModules = script.Parent
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local Game = SystemCoordinator.waitForSystem("Game")
local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")
local Shop = SystemCoordinator.waitForSystem("Shop")

---

local serverType = ServerMaster.GetServerType() or ServerMaster.ServerInitialised:Wait()

---

local Proxy = {}

Proxy.GetObjectGrantPrice = function(objectType: string, objectName: string): number?
    return ShopPrices.ObjectGrantPrices[objectType][objectName]
end

Proxy.GetObjectPlacementPrice = function(objectType: string, objectName: string): number?
    return ShopPrices.ObjectPlacementPrices[objectType][objectName]
end

Proxy.GetItemPrice = function(itemType: string, itemName: string): number?
    return ShopPrices.ItemPrices[itemType][itemName]
end

Proxy.GetUnitUpgradePrice = function(unitName: string, level: number): number?
    local unitPrices = ShopPrices.UnitUpgradePrices[unitName]
    if (not unitPrices) then return end

    local prices = unitPrices[level + 1]
    if (not prices) then return end

    return prices.Individual
end

Proxy.GetUnitPersistentUpgradePrice = function(unitName: string, level: number): number?
    local unitPrices = ShopPrices.UnitUpgradePrices[unitName]
    if (not unitPrices) then return end

    local prices = unitPrices[level + 1]
    if (not prices) then return end

    return prices.Persistent
end

Proxy.GetUnitSellingPrice = function(unitName: string, level: number): number?
    local unitSpending = ShopPrices.ObjectPlacementPrices[GameEnum.ObjectType.Unit][unitName]
    local unitUpgradePrices = ShopPrices.UnitUpgradePrices[unitName]

    for i = 2, level do
        local levelUpgradePrices = unitUpgradePrices[i]

        unitSpending = unitSpending + (levelUpgradePrices and levelUpgradePrices.Individual or 0)
    end

    return (unitSpending / 2)
end

Proxy.PurchaseObjectGrant = function(userId: number, objectType: ObjectType, objectName: string): boolean
    local alreadyHasGrant = PlayerData.PlayerHasObjectGrant(userId, objectType, objectName)
    if (alreadyHasGrant) then return false end

    local grantPrice = Proxy.GetObjectGrantPrice(objectType, objectName)
    if (not grantPrice) then return false end
    
    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return false end

    if (grantPrice > ticketsBalance) then
        return false
    else
        return Shop.PurchaseObjectGrant(userId, objectType, objectName)
    end
end

Proxy.PurchaseItem = function(userId: number, itemType: string, itemName: string): boolean
    local itemPrice = Proxy.GetItemPrice(itemType, itemName)
    if (not itemPrice) then return false end

    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return false end

    if (itemPrice > ticketsBalance) then
        return false
    else
        return Shop.PurchaseItem(userId, itemType, itemName)
    end
end

if (serverType == GameEnum.ServerType.Game) then
    Proxy.PurchaseObjectPlacement = function(userId: number, objectType: ObjectType, objectName: string, rayOrigin: Vector3, rayDirection: Vector3, rotation: number): boolean
        if (not Game.IsRunning()) then return false end

        local placementPrice = Proxy.GetObjectPlacementPrice(objectType, objectName)
        if (not placementPrice) then return false end

        local pointsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Points)
        if (not pointsBalance) then return false end

        if (placementPrice > pointsBalance) then
            return false
        else
            return Shop.PurchaseObjectPlacement(userId, objectType, objectName, rayOrigin, rayDirection, rotation)
        end
    end

    Proxy.PurchaseUnitUpgrade = function(unitId: string): boolean
        if (not Game.IsRunning()) then return false end

        local unit = Unit.fromId(unitId)
        if (not unit) then return false end
        if (unit.Owner == 0) then return false end
        if (unit.Type == GameEnum.UnitType.FieldUnit) then return false end

        local ownerId = unit.Owner

        local upgradePrice = Proxy.GetUnitUpgradePrice(unit.Name, unit.Level)
        if (not upgradePrice) then return false end

        local pointsBalance = PlayerData.GetPlayerCurrencyBalance(ownerId, GameEnum.CurrencyType.Points)
        if (not pointsBalance) then return false end

        if (upgradePrice > pointsBalance) then
            return false
        else
            return Shop.PurchaseUnitUpgrade(unitId)
        end
    end

    Proxy.PurchaseUnitPersistentUpgrade = function(userId: number, unitName: string): boolean
        if (not Game.IsRunning()) then return false end

        local upgradePrice = Proxy.GetUnitPersistentUpgradePrice(unitName, Unit.GetUnitPersistentUpgradeLevel(userId, unitName))
        if (not upgradePrice) then return false end

        local pointsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Points)
        if (not pointsBalance) then return false end

        if (upgradePrice > pointsBalance) then
            return false
        else
            return Shop.PurchaseUnitPersistentUpgrade(userId, unitName)
        end
    end

    Proxy.SellUnit = function(unitId: string): boolean
        if (not Game.IsRunning()) then return false end

        local unit = Unit.fromId(unitId)
        if (not unit) then return false end
        if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return false end
        if (unit.Owner == 0) then return false end

        return Shop.SellUnit(unitId)
    end
end

---

return setmetatable(Proxy, { __index = Shop })