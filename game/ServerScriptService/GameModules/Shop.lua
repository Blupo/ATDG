local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local Communicators = ReplicatedStorage:FindFirstChild("Communicators"):FindFirstChild("Shop")

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Game = require(GameModules:FindFirstChild("Game"))
local Placement = require(GameModules:FindFirstChild("Placement"))
local PlayerData = require(GameModules:FindFirstChild("PlayerData"))
local RemoteUtils = require(GameModules:FindFirstChild("RemoteUtils"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnums"))
local ShopPrices = require(SharedModules:FindFirstChild("ShopPrices"))
local t = require(SharedModules:FindFirstChild("t"))

local PurchaseTicketsRemoteFunction = Instance.new("RemoteFunction")
local PurchaseObjectGrantRemoteFunction = Instance.new("RemoteFunction")
local PurchaseSpecialActionTokenRemoteFunction = Instance.new("RemoteFunction")
local PurchaseObjectPlacementRemoteFunction = Instance.new("RemoteFunction")
local PurchaseUnitUpgradeRemoteFunction = Instance.new("RemoteFunction")
local PurchaseUnitPersistentUpgradeRemoteFunction = Instance.new("RemoteFunction")

---

type PurchaseResult = {
    Success: boolean,
    FailureReason: PurchaseFailureReason,
    TransactionId: string?
}

type TransactionLog = {
    Id: string,
    Status: TransactionStatus,
    PurchaseType: PurchaseType,
    Price: number,
}

---

local Shop = {}

Shop.PurchaseTickets = function(userId: number, ticketItemId: string): PurchaseResult

end

Shop.PurchaseObjectGrant = function(userId: number, objectType: ObjectType, objectName: string): PurchaseResult
    local alreadyHasGrant = PlayerData.PlayerHasObjectGrant(userId, objectType, objectName)
    if (alreadyHasGrant) then return end

    local grantPrice = ShopPrices.ItemPrices[objectType][objectName]
    if (not grantPrice) then return end -- item does not have a listed price
    
    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return end -- ???

    if (grantPrice > ticketsBalance) then
        return false
    else
        -- is it possible that one of these succeeds and one doesn't?
        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Tickets, grantPrice)
        PlayerData.GrantObjectToPlayer(userId, objectType, objectName)
    end
end

Shop.PurchaseSpecialActionToken = function(userId: number, actionName: string): PurchaseResult
    local tokenPrice = ShopPrices.ItemPrices[GameEnum.ItemType.SpecialAction][actionName]
    if (not tokenPrice) then return end -- item does not have a listed price
    
    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return end -- ???

    if (tokenPrice > ticketsBalance) then
        return false
    else
        -- is it possible that one of these succeeds and one doesn't?
        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Tickets, tokenPrice)
        PlayerData.GiveSpecialActionToken(userId, actionName)
        return true
    end
end

Shop.PurchaseObjectPlacement = function(userId: number, objectType: ObjectType, objectName: string, position: Vector3, rotation: number): boolean
    if (not Game.HasStarted()) then return end

    local placementPrice = ShopPrices.ObjectPlacementPrices[objectType][objectName]
    print(placementPrice)
    if (not placementPrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Points)
    print(pointsBalance)
    if (not pointsBalance) then return false end

    if (placementPrice > pointsBalance) then
        return false
    else
        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Points, placementPrice)
        Placement.PlaceObject(userId, objectType, objectName, position, rotation)
        return true
    end
end

Shop.PurchaseUnitUpgrade = function(userId: number, unitId: string): boolean
    if (not Game.HasStarted()) then return end

    local unit = Unit.fromId(unitId)
    if (not unit) then return false end
    if (unit.Owner ~= userId) then return false end

    local upgradePrice = ShopPrices.UnitUpgradePrices[unit.Name].Individual[unit.Level + 1]
    if (not upgradePrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (upgradePrice > pointsBalance) then
        return false
    else
        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Points, upgradePrice)
        unit:Upgrade()
        return true
    end
end

Shop.PurchaseUnitPersistentUpgrade = function(userId: number, unitName: string): boolean
    if (not Game.HasStarted()) then return end

    local upgradePrice = ShopPrices.UnitUpgradePrices[unitName].Persistent[Unit.GetUnitPersistentUpgradeLevel(userId, unitName) + 1]
    if (not upgradePrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (upgradePrice > pointsBalance) then
        return false
    else
        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Points, upgradePrice)
        Unit.PersistentUpgradeUnit(userId, unitName)
        return true
    end
end

---

MarketplaceService.ProcessReceipt = function(receiptInfo)
    warn("implement pls")
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

PurchaseTicketsRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number)

end, t.tuple(t.instanceOf("Player"), t.number)))

PurchaseObjectGrantRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number)

end, t.tuple(t.instanceOf("Player"), t.number)))

PurchaseSpecialActionTokenRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number)

end, t.tuple(t.instanceOf("Player"), t.number)))

PurchaseObjectPlacementRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number, objectType: string, objectName: string, position: Vector3, rotation: number)
    if (callingPlayer.UserId ~= userId) then return end

    return Shop.PurchaseObjectPlacement(userId, objectType, objectName, position, rotation)
end, t.tuple(t.instanceOf("Player"), t.number, t.string, t.string, t.Vector3, t.number)))

PurchaseUnitUpgradeRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number, unitId: string)
    if (callingPlayer.UserId ~= userId) then return end

    return Shop.PurchaseUnitUpgrade(userId, unitId)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)))

PurchaseUnitPersistentUpgradeRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number, unitName: string)
    if (callingPlayer.UserId ~= userId) then return end

    return Shop.PurchaseUnitPersistentUpgrade(userId, unitName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)))

PurchaseTicketsRemoteFunction.Name = "PurchaseTickets"
PurchaseObjectGrantRemoteFunction.Name = "PurchaseObjectGrant"
PurchaseSpecialActionTokenRemoteFunction.Name = "PurchaseSpecialActionToken"
PurchaseObjectPlacementRemoteFunction.Name = "PurchaseObjectPlacement"
PurchaseUnitUpgradeRemoteFunction.Name = "PurchaseUnitUpgrade"
PurchaseUnitPersistentUpgradeRemoteFunction.Name = "PurchaseUnitPersistentUpgrade"

PurchaseTicketsRemoteFunction.Parent = Communicators
PurchaseObjectGrantRemoteFunction.Parent = Communicators
PurchaseSpecialActionTokenRemoteFunction.Parent = Communicators
PurchaseObjectPlacementRemoteFunction.Parent = Communicators
PurchaseUnitUpgradeRemoteFunction.Parent = Communicators
PurchaseUnitPersistentUpgradeRemoteFunction.Parent = Communicators

return Shop