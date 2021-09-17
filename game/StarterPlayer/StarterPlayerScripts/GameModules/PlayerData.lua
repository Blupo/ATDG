local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local ClientScripts = PlayerScripts:WaitForChild("ClientScripts")
local EventProxy = require(ClientScripts:WaitForChild("EventProxy"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:FindFirstChild("CopyTable"))
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local SharedGameData = require(SharedModules:WaitForChild("SharedGameData"))
local AutomaticObjectGrants = SharedGameData.AutomaticObjectGrants
local EphemeralCurrencies = SharedGameData.EphemeralCurrencies

local PlayerData = SystemCoordinator.waitForSystem("PlayerData")

---

local localPlayerData = {}
local localPlayerEphemeralCurrenciesBalances = {}

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

PlayerData.CurrencyBalanceChanged = EventProxy(PlayerData.CurrencyBalanceChanged, function(userId: number, currencyType: string, newBalance: number, _)
    if (userId ~= LocalPlayer.UserId) then return end

    if (EphemeralCurrencies[currencyType]) then
        localPlayerEphemeralCurrenciesBalances[currencyType] = newBalance
    else
        localPlayerData.Currencies[currencyType] = newBalance
    end
end)

PlayerData.ObjectGranted = EventProxy(PlayerData.ObjectGranted, function(userId: number, objectType: string, objectName: string)
    if (userId ~= LocalPlayer.UserId) then return end

    localPlayerData.ObjectGrants[objectType][objectName] = true
end)

PlayerData.InventoryChanged = EventProxy(PlayerData.InventoryChanged, function(userId: number, itemType: string, itemName: string, newAmount: number, _)
    if (userId ~= LocalPlayer.UserId) then return end

    localPlayerData.Inventory[itemType][itemName] = newAmount
end)

PlayerData.HotbarChanged = EventProxy(PlayerData.HotbarChanged, function(userId: number, objectType: string, newHotbar: array<string>)
    if (userId ~= LocalPlayer.UserId) then return end

    localPlayerData.Hotbars[objectType] = newHotbar
end)

---

local CacheProxy = {}

CacheProxy.GetPlayerInventory = localPlayerProxy(PlayerData.GetPlayerInventory, function()
    return CopyTable(localPlayerData.Inventory)
end)

CacheProxy.GetPlayerInventoryItemCount = localPlayerProxy(PlayerData.GetPlayerInventoryItemCount, function(_, itemType: string, itemName: string)
    local inventory = localPlayerData.Inventory[itemType]
    if (not inventory) then return end

    return inventory[itemName] or 0
end)

CacheProxy.GetPlayerObjectGrants = localPlayerProxy(PlayerData.GetPlayerObjectGrants, function()
    local grants = CopyTable(localPlayerData.ObjectGrants)

    for objectType, permaGrants in pairs(AutomaticObjectGrants) do
        for objectName in pairs(permaGrants) do
            grants[objectType][objectName] = true
        end
    end

    return grants
end)

CacheProxy.PlayerHasObjectGrant = localPlayerProxy(PlayerData.PlayerHasObjectGrant, function(_, objectType: string, objectName: string)
    local permaGrantStatus = AutomaticObjectGrants[objectType][objectName]
    if (permaGrantStatus) then return permaGrantStatus end

    return localPlayerData.ObjectGrants[objectType][objectName] and true or false
end)

CacheProxy.GetPlayerHotbars = localPlayerProxy(PlayerData.GetPlayerHotbars, function()
    return CopyTable(localPlayerData.Hotbars)
end)

CacheProxy.GetPlayerHotbar = localPlayerProxy(PlayerData.GetPlayerHotbar, function(_, objectType: string)
    local hotbar = localPlayerData.Hotbars[objectType]
    if (not hotbar) then return end

    return CopyTable(hotbar)
end)

CacheProxy.GetPlayerAllCurrenciesBalances = localPlayerProxy(PlayerData.GetPlayerAllCurrenciesBalances, function()
    local currenciesBalances = {}

    for currency in pairs(GameEnum.CurrencyType) do -- badness
        if (EphemeralCurrencies[currency]) then
            currenciesBalances[currency] = localPlayerEphemeralCurrenciesBalances[currency] or 0
        else
            currenciesBalances[currency] = localPlayerData.Currencies[currency] or 0
        end
    end

    return currenciesBalances
end)

CacheProxy.GetPlayerCurrencyBalance = localPlayerProxy(PlayerData.GetPlayerCurrencyBalance, function(_, currencyType: string)
    if (EphemeralCurrencies[currencyType]) then
        return localPlayerEphemeralCurrenciesBalances[currencyType] or 0
    else
        return localPlayerData.Currencies[currencyType] or 0
    end
end)

---

do
    localPlayerData = PlayerData.WaitForPlayerData(LocalPlayer.UserId)
    local allCurrenciesBalances = PlayerData.GetPlayerAllCurrenciesBalances(LocalPlayer.UserId)

    for currencyType, balance in pairs(allCurrenciesBalances) do
        if (EphemeralCurrencies[currencyType]) then
            localPlayerEphemeralCurrenciesBalances[currencyType] = balance
        end
    end
end

return setmetatable(CacheProxy, { __index = PlayerData })