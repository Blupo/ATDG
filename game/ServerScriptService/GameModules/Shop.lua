local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local GameCommunicators = ReplicatedStorage:FindFirstChild("Communicators"):FindFirstChild("Shop")

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Game = require(GameModules:FindFirstChild("Game"))
local PlayerData = require(GameModules:FindFirstChild("PlayerData"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local ShopPrices = require(SharedModules:FindFirstChild("ShopPrices"))

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

Shop.PurchaseTickets = function(player: Player, ticketItemId: string): PurchaseResult

end

Shop.PurchaseObjectGrant = function(player: Player, objectType: ObjectType, objectName: string): PurchaseResult
    local alreadyHasGrant = PlayerData.PlayerHasObjectGrant(player, objectType, objectName)
    if (alreadyHasGrant) then return end

    local grantPrice = ShopPrices.ItemPrices[objectType][objectName]
    if (not grantPrice) then return end -- item does not have a listed price
    
    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(player, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return end -- ???

    if (ticketsBalance >= grantPrice) then
        -- is it possible that one of these succeeds and one doesn't?
        PlayerData.WithdrawCurrencyFromPlayer(player, GameEnum.CurrencyType.Tickets, grantPrice)
        PlayerData.GrantObjectToPlayer(player, objectType, objectName)
    else
        return
        -- not enough tickets
    end
end

Shop.PurchaseSpecialActionToken = function(player: Player, actionName: string): PurchaseResult
    local tokenPrice = ShopPrices.ItemPrices[GameEnum.ItemType.SpecialAction][actionName]
    if (not tokenPrice) then return end -- item does not have a listed price
    
    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(player, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return end -- ???

    if (ticketsBalance >= tokenPrice) then
        -- is it possible that one of these succeeds and one doesn't?
        PlayerData.WithdrawCurrencyFromPlayer(player, GameEnum.CurrencyType.Tickets, tokenPrice)
        PlayerData.GiveSpecialActionToken(player, actionName)
    else
        return
        -- not enough tickets
    end
end

Shop.PurchaseObjectPlacement = function(player: Player, objectType: ObjectType, objectName: string): boolean
    local placementPrice = ShopPrices.ObjectPlacementPrices[objectType][objectName]
    if (not placementPrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(player, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (pointsBalance >= placementPrice) then
        PlayerData.WithdrawCurrencyFromPlayer(player, GameEnum.CurrencyType.Tickets, placementPrice)
        return true
    else
        return false
    end
end

Shop.PurchaseUnitUpgrade = function(player: Player, unitId: string): boolean
    local unit = Unit.fromId(unitId)
    if (not unit) then return false end
    if (unit.Owner ~= player.UserId) then return false end

    local upgradePrice = ShopPrices.UnitUpgradePrices[unit.Name].Individual[unit.Level + 1]
    if (not upgradePrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(player, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (pointsBalance >= upgradePrice) then
        PlayerData.WithdrawCurrencyFromPlayer(player, GameEnum.CurrencyType.Tickets, upgradePrice)
        unit:Upgrade()
        return true
    else
        return false
    end
end

Shop.PurchasePersistentUnitUpgrade = function(player: Player, unitName: string): boolean
    local upgradePrice = ShopPrices.UnitUpgradePrices[unitName].Persistent[Unit.GetUnitPersistentUpgradeLevel(player.UserId, unitName) + 1]
    if (not upgradePrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(player, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (pointsBalance >= upgradePrice) then
        PlayerData.WithdrawCurrencyFromPlayer(player, GameEnum.CurrencyType.Tickets, upgradePrice)
        Unit.PersistentUpgradeUnit(player.UserId, unitName)
        return true
    else
        return false
    end
end

---

MarketplaceService.ProcessReceipt = function(receiptInfo)
    warn("implement pls")
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

return Shop