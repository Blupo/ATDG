-- todo: needs to work with ServerMaster

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Game = require(GameModules:FindFirstChild("Game"))
local Placement = require(GameModules:FindFirstChild("Placement"))
local PlayerData = require(GameModules:FindFirstChild("PlayerData"))
local ServerMaster = require(GameModules:FindFirstChild("ServerMaster"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local ShopPrices = require(SharedModules:FindFirstChild("ShopPrices"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local System = SystemCoordinator.newSystem("Shop")

---

local devProductTypes = {}
local devProductPromotions = {}

local devProducts = {
    [GameEnum.DevProductType.Ticket] = {
        [GameEnum.PromotionalPricing.None] = {
            [5] = 1195695901,
            [10] = 1195695933,
            [25] = 1195695982,
            [100] = 1195697350,
            [250] = 1195698157,
        },

        [GameEnum.PromotionalPricing.Summer] = {
            [5] = 1195698990,
            [10] = 1195699016,
            [25] = 1195699094,
            [100] = 1195699199,
            [250] = 1195699341,
        }
    },

    [GameEnum.DevProductType.ValuePack] = {

    }
}

---

local Shop = {}

Shop.GetObjectGrantPrice = function(objectType: string, objectName: string): number?
    return ShopPrices.ObjectGrantPrices[objectType][objectName]
end

Shop.GetObjectPlacementPrice = function(objectType: string, objectName: string): number?
    return ShopPrices.ObjectPlacementPrices[objectType][objectName]
end

Shop.GetItemPrice = function(itemType: string, itemName: string): number?
    return ShopPrices.ItemPrices[itemType][itemName]
end

Shop.GetUnitUpgradePrice = function(unitName: string, level: number): number?
    local unitPrices = ShopPrices.UnitUpgradePrices[unitName]
    if (not unitPrices) then return end

    local prices = unitPrices[level + 1]
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

Shop.GetUnitSellingPrice = function(unitName: string, level: number): number?
    local unitSpending = ShopPrices.ObjectPlacementPrices[GameEnum.ObjectType.Unit][unitName]
    local unitUpgradePrices = ShopPrices.UnitUpgradePrices[unitName]

    for i = 2, level do
        local levelUpgradePrices = unitUpgradePrices[i]

        unitSpending = unitSpending + (levelUpgradePrices and levelUpgradePrices.Individual or 0)
    end

    return (unitSpending / 2)
end

-- Displays the appropriate dev product to prompt, Marketplace.ProcessReceipt handles the actual purchases
Shop.PurchaseTickets = function(userId: number, quantity: number)
    local player = Players:GetPlayerByUserId(userId)
    if (not player) then return end

    -- todo: implement sales
    local now = DateTime.now().UnixTimestamp

    local currentPromotion = GameEnum.PromotionalPricing.None
    local products = devProducts[GameEnum.DevProductType.Ticket][currentPromotion]
    if (not products) then return end

    local productId = products[quantity]
    if (not productId) then return end

    MarketplaceService:PromptProductPurchase(player, productId, false)
end

Shop.PurchaseObjectGrant = function(userId: number, objectType: ObjectType, objectName: string): boolean
    local alreadyHasGrant = PlayerData.PlayerHasObjectGrant(userId, objectType, objectName)
    if (alreadyHasGrant) then return false end

    local grantPrice = Shop.GetObjectGrantPrice(objectType, objectName)
    if (not grantPrice) then return false end -- item does not have a listed price
    
    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return false end -- ???

    if (grantPrice > ticketsBalance) then
        return false
    else
        -- is it possible that one of these succeeds and one doesn't?
        PlayerData.RecordTransaction(userId, GameEnum.TransactionType.TicketSpending, nil, {
            ObjectType = objectType,
            ObjectName = objectName,
            AmountPaid = grantPrice,
        })

        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Tickets, grantPrice)
        PlayerData.GrantObjectToPlayer(userId, objectType, objectName)

        return true
    end
end

Shop.PurchaseItem = function(userId: number, itemType: string, itemName: string): boolean
    local itemPrice = Shop.GetItemPrice(itemType, itemName)
    if (not itemPrice) then return false end -- item does not have a listed price
    
    local ticketsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Tickets)
    if (not ticketsBalance) then return false end -- ???

    if (itemPrice > ticketsBalance) then
        return false
    else
        -- is it possible that one of these succeeds and one doesn't?
        PlayerData.RecordTransaction(userId, GameEnum.TransactionType.TicketSpending, nil, {
            ItemType = itemType,
            ItemName = itemName,
            AmountPaid = itemPrice,
        })

        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Tickets, itemPrice)
        PlayerData.AddItemToPlayerInventory(userId, itemType, itemName, 1)

        return true
    end
end

Shop.PurchaseObjectPlacement = function(userId: number, objectType: ObjectType, objectName: string, position: Vector3, rotation: number): boolean
    if (not Game.IsRunning()) then return false end

    local placementPrice = Shop.GetObjectPlacementPrice(objectType, objectName)
    if (not placementPrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (placementPrice > pointsBalance) then
        return false
    else
        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Points, placementPrice)

        -- todo: handle roadblocks and field units
        Placement.PlaceObject(userId, objectType, objectName, position, rotation)

        return true
    end
end

Shop.PurchaseUnitUpgrade = function(unitId: string): boolean
    if (not Game.IsRunning()) then return false end

    local unit = Unit.fromId(unitId)
    if (not unit) then return false end
    if (unit.Owner == 0) then return false end
    if (unit.Type == GameEnum.UnitType.FieldUnit) then return false end -- Field Units cannot be upgraded once deployed

    local ownerId = unit.Owner

    local upgradePrice = Shop.GetUnitUpgradePrice(unit.Name, unit.Level)
    if (not upgradePrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(ownerId, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (upgradePrice > pointsBalance) then
        return false
    else
        PlayerData.WithdrawCurrencyFromPlayer(ownerId, GameEnum.CurrencyType.Points, upgradePrice)
        unit:Upgrade()
        return true
    end
end

Shop.PurchaseUnitPersistentUpgrade = function(userId: number, unitName: string): boolean
    if (not Game.IsRunning()) then return false end

    local upgradePrice = Shop.GetUnitPersistentUpgradePrice(userId, unitName)
    if (not upgradePrice) then return false end

    local pointsBalance = PlayerData.GetPlayerCurrencyBalance(userId, GameEnum.CurrencyType.Points)
    if (not pointsBalance) then return false end

    if (upgradePrice > pointsBalance) then
        return false
    else
        PlayerData.WithdrawCurrencyFromPlayer(userId, GameEnum.CurrencyType.Points, upgradePrice)
        Unit.DoUnitPersistentUpgrade(userId, unitName)
        return true
    end
end

Shop.SellUnit = function(unitId: string): boolean
    if (not Game.IsRunning()) then return false end

    local unit = Unit.fromId(unitId)
    if (not unit) then return false end
    if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return false end
    if (unit.Owner == 0) then return false end

    unit:Destroy()
    PlayerData.DepositCurrencyToPlayer(unit.Owner, GameEnum.CurrencyType.Points, Shop.GetUnitSellingPrice(unit.Name, unit.Level))
    return true
end

---

for productType, promotions in pairs(devProducts) do
    for promotion, products in pairs(promotions) do
        for _, productId in pairs(products) do
            devProductTypes[productId] = productType
            devProductPromotions[productId] = promotion
        end
    end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
    local purchaseId = receiptInfo.PurchaseId
    local productId = receiptInfo.ProductId
    local playerId = receiptInfo.PlayerId

    local productType = devProductTypes[productId]
    local promotionType = devProductPromotions[productId]

    if (not productType) then
        warn("Unable to process purchase " .. purchaseId .. ": Attempted to purchase an invalid product")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- check if the product is purchasable
    -- todo: implement sales
    local now = DateTime.now().UnixTimestamp

    local currentPromotion = GameEnum.PromotionalPricing.None

    if (promotionType ~= currentPromotion) then
        warn("Unable to process purchase " .. purchaseId .. ": Attempted to purchase a product outside if its promotion period")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- record purchase
    local recordTransactionResult = PlayerData.RecordTransaction(playerId, GameEnum.TransactionType.DevProductPurchase, purchaseId, {
        ProductType = productType,
        ProductId = productId,
        AmountPaid = receiptInfo.CurrencySpent,
    })

    if (not recordTransactionResult.Success) then
        if (recordTransactionResult.FailureReason == GameEnum.TransactionRecordingFailureReason.TransactionAlreadyRecorded) then
            return Enum.ProductPurchaseDecision.PurchaseGranted 
        else
            warn("Unable to process purchase " .. purchaseId .. ": Could not record transaction, " .. recordTransactionResult.FailureReason)
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
    end

    -- todo: the purchase should also be recorded by a third party

    -- grant product
    if (productType == GameEnum.DevProductType.Ticket) then
        local ticketAmount
        local ticketProducts = devProducts[GameEnum.DevProductType.Ticket][currentPromotion]

        for amount, ticketProductId in pairs(ticketProducts) do
            if (productId == ticketProductId) then
                ticketAmount = amount
            end
        end

        -- todo: how do we handle this failing?
        PlayerData.DepositCurrencyToPlayer(playerId, GameEnum.CurrencyType.Tickets, ticketAmount)
    elseif (productType == GameEnum.DevProductType.ValuePack) then
        -- todo
    end

    -- todo: notify the user that their purchase was successful, and give them the purchase ID to record
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

System.addFunction("PurchaseTickets", t.wrap(function(callingPlayer: Player, userId: number, quantity: number)
    if (callingPlayer.UserId ~= userId) then return end

    Shop.PurchaseTickets(userId, quantity)
end, t.tuple(t.instanceOf("Player"), t.number, t.number)), true)

System.addFunction("PurchaseObjectGrant", t.wrap(function(callingPlayer: Player, userId: number, objectType: string, objectName: string)
    if (callingPlayer.UserId ~= userId) then return end

    Shop.PurchaseObjectGrant(userId, objectType, objectName)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

System.addFunction("PurchaseItem", t.wrap(function(callingPlayer: Player, userId: number, itemType: string, itemName: string)
    if (callingPlayer.UserId ~= userId) then return end

    return Shop.PurchaseItem(userId, itemType, itemName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string, t.string)), true)

System.addFunction("PurchaseObjectPlacement", t.wrap(function(callingPlayer: Player, userId: number, objectType: string, objectName: string, position: Vector3, rotation: number)
    if (callingPlayer.UserId ~= userId) then return false end

    return Shop.PurchaseObjectPlacement(userId, objectType, objectName, position, rotation)
end, t.tuple(t.instanceOf("Player"), t.number, t.string, t.string, t.Vector3, t.number)), true)

System.addFunction("PurchaseUnitUpgrade", t.wrap(function(callingPlayer: Player, unitId: string)
    local unit = Unit.fromId(unitId)
    if (not unit) then return false end
    if (unit.Owner ~= callingPlayer.UserId) then return false end

    return Shop.PurchaseUnitUpgrade(unitId)
end, t.tuple(t.instanceOf("Player"), t.string)), true)

System.addFunction("PurchaseUnitPersistentUpgrade", t.wrap(function(callingPlayer: Player, userId: number, unitName: string)
    if (callingPlayer.UserId ~= userId) then return end

    return Shop.PurchaseUnitPersistentUpgrade(userId, unitName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)

System.addFunction("SellUnit", t.wrap(function(callingPlayer: Player, unitId: string)
    local unit = Unit.fromId(unitId)
    if (not unit) then return false end
    if (unit.Owner ~= callingPlayer.UserId) then return false end

    return Shop.SellUnit(unitId)
end, t.tuple(t.instanceOf("Player"), t.string)), true)

return Shop