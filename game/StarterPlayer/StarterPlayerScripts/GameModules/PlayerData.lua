local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:FindFirstChild("CopyTable"))
local EphemeralCurrencies = require(SharedModules:FindFirstChild("EphemeralCurrencies"))
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local PermanentObjectGrants = require(SharedModules:FindFirstChild("PermanentObjectGrants"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local LocalPlayer = Players.LocalPlayer
local PlayerData = SystemCoordinator.waitForSystem("PlayerData")

---

local localPlayerData = {}
local localPlayerEphemeralCurrenciesBalances = {}

local localPlayerProxy = function(proxyCallback, mainCallback)
    return function(userId, ...)
        if (userId == LocalPlayer.UserId) then
            return proxyCallback(userId, ...)
        else
            return mainCallback(userId, ...)
        end
    end
end

---

local CacheProxy = {}

CacheProxy.GetPlayerInventory = localPlayerProxy(function()
    return CopyTable(localPlayerData.Inventory)
end, PlayerData.GetPlayerInventory)

CacheProxy.GetPlayerInventoryItemCount = localPlayerProxy(function(_, itemType: string, itemName: string)
    local inventory = localPlayerData.Inventory[itemType]
    if (not inventory) then return end

    return inventory[itemName] or 0
end, PlayerData.GetPlayerInventoryItemCount)

CacheProxy.GetPlayerObjectGrants = localPlayerProxy(function()
    local grants = CopyTable(localPlayerData.ObjectGrants)

    for objectType, permaGrants in pairs(PermanentObjectGrants) do
        for objectName in pairs(permaGrants) do
            grants[objectType][objectName] = true
        end
    end

    return grants
end, PlayerData.GetPlayerObjectGrants)

CacheProxy.PlayerHasObjectGrant = localPlayerProxy(function(_, objectType: string, objectName: string)
    local permaGrantStatus = PermanentObjectGrants[objectType][objectName]
    if (permaGrantStatus) then return permaGrantStatus end

    return localPlayerData.ObjectGrants[objectType][objectName] and true or false
end, PlayerData.PlayerHasObjectGrant)

CacheProxy.GetPlayerHotbars = localPlayerProxy(function()
    return CopyTable(localPlayerData.Hotbars)
end, PlayerData.GetPlayerHotbars)

CacheProxy.GetPlayerHotbar = localPlayerProxy(function(_, objectType: string)
    local hotbar = localPlayerData.Hotbars[objectType]
    if (not hotbar) then return end

    return CopyTable(hotbar)
end, PlayerData.GetPlayerHotbar)

CacheProxy.GetPlayerAllCurrenciesBalances = localPlayerProxy(function()
    local currenciesBalances = {}

    for currency in pairs(GameEnum.CurrencyType) do -- badness
        if (EphemeralCurrencies[currency]) then
            currenciesBalances[currency] = localPlayerEphemeralCurrenciesBalances[currency] or 0
        else
            currenciesBalances[currency] = localPlayerData.Currencies[currency] or 0
        end
    end

    return currenciesBalances
end, PlayerData.GetPlayerAllCurrenciesBalances)

CacheProxy.GetPlayerCurrencyBalance = localPlayerProxy(function(_, currencyType: string)
    if (EphemeralCurrencies[currencyType]) then
        return localPlayerEphemeralCurrenciesBalances[currencyType] or 0
    else
        return localPlayerData.Currencies[currencyType] or 0
    end
end, PlayerData.GetPlayerCurrencyBalance)

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

PlayerData.CurrencyBalanceChanged:Connect(function(userId: number, currencyType: string, newBalance: number, delta: number)
    if (userId ~= LocalPlayer.UserId) then return end

    if (EphemeralCurrencies[currencyType]) then
        localPlayerEphemeralCurrenciesBalances[currencyType] = newBalance
    else
        localPlayerData.Currencies[currencyType] = newBalance
    end
end)

PlayerData.ObjectGranted:Connect(function(userId: number, objectType: string, objectName: string)
    if (userId ~= LocalPlayer.UserId) then return end

    localPlayerData.ObjectGrants[objectType][objectName] = true
end)

PlayerData.InventoryChanged:Connect(function(userId: number, itemType: string, itemName: string, newAmount: number, delta: number)
    if (userId ~= LocalPlayer.UserId) then return end

    localPlayerData.Inventory[itemType][itemName] = newAmount
end)

PlayerData.HotbarChanged:Connect(function(userId: number, objectType: string, newHotbar: array<string>)
    if (userId ~= LocalPlayer.UserId) then return end

    localPlayerData.Hotbars[objectType] = newHotbar
end)

return setmetatable(CacheProxy, { __index = PlayerData })