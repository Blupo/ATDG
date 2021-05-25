local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

---

local ProfileService = require(ServerScriptService:FindFirstChild("ProfileService"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnums"))

---

type dictionary<T, TT> = {[T]: TT}
type array<T> = {[number]: T}

type PlayerInventory = {
    Units: dictionary<string, boolean>,
    Roadblocks: dictionary<string, boolean>,
    SpecialActions: dictionary<string, number>
}

type PlayerData = {
    Currencies: dictionary<CurrencyType, number>,
    Inventory: PlayerInventory,
    Hotbars: array<array<string>>,
    Transactions: dictionary<string, boolean>
}

---

-- Perma-grants must not save to player data
local PERMA_GRANTS = {
    [GameEnum.ObjectType.Unit] = {

    },

    [GameEnum.ObjectType.Roadblock] = {

    }
}

-- Ephemeral currencies only exist in a single game session
local EPHEMERAL_CURRENCIES = {
    [GameEnum.CurrencyType.Points] = true,
}

local PlayerDataTemplate: PlayerData = {
    Currencies = {},
    Transactions = {},
    Hotbars = {},
    
    Inventory = {
        Units = {},
        Roadblocks = {},
        SpecialActions = {},
    },
}

local ProfileStore = ProfileService.GetProfileStore("PlayerData", PlayerDataTemplate)
ProfileService = RunService:IsStudio() and ProfileStore.Mock or ProfileStore

local playerProfiles = {}
local ephemeralCurrenciesBalances = {}

local copy
copy = function(t)
    local tCopy = {}

    for k, v in pairs(t) do
        tCopy[k] = (type(v) == "table") and copy(v) or v
    end

    return tCopy
end

local playerAdded = function(player: Player)
    local playerId = player.UserId
    local ephemeralCurrenciesBalance = {}
    local profile = ProfileStore:LoadProfileAsync(tostring(playerId), "ForceLoad")

    if (profile) then
        -- todo: provide a mechanism for merging old data versions
        playerProfiles[playerId] = profile

        profile:ListenToRelease(function()
            playerProfiles[playerId] = nil
            -- todo: come up with a better message than this
            player:Kick("User profile was released")
        end)

        if player:IsDescendantOf(Players) then
            for currencyType in pairs(EPHEMERAL_CURRENCIES) do
                ephemeralCurrenciesBalance[currencyType] = 0
            end

            playerProfiles[playerId] = profile
            ephemeralCurrenciesBalances[playerId] = ephemeralCurrenciesBalance
        else
            profile:Release()
        end
    else
        -- todo: come up with a better message than this
        player:Kick("Could not load user profile")
    end
end

local playerRemoving = function(player: Player)
    local playerId = player.UserId
    local profile = playerProfiles[playerId]
    if (not profile) then return end

    profile:Release()
    ephemeralCurrenciesBalances[playerId] = nil
end

---

local PlayerData = {}

-- This is an internal function
PlayerData.GetPlayerProfile = function(player: Player)
    return playerProfiles[player.UserId]
end

PlayerData.GetPlayerInventory = function(player: Player): PlayerInventory?
    local profile = playerProfiles[player.UserId]
    if (not profile) then return end

    local inventoryCopy = copy(profile.Data.Inventory)

    for unitName in pairs(PERMA_GRANTS[GameEnum.ObjectType.Unit]) do
        inventoryCopy.Units[unitName] = true
    end

    for roadblockName in pairs(PERMA_GRANTS[GameEnum.ObjectType.Roadblock]) do
        inventoryCopy.Roadblocks[roadblockName] = true
    end

    return inventoryCopy
end

PlayerData.PlayerHasObjectGrant = function(player: Player, objectType: string, objectName: string): boolean
    -- check perma grants
    if (PERMA_GRANTS[objectType][objectName]) then return true end

    local profile = playerProfiles[player.UserId]
    if (not profile) then return false end

    return profile.Data.Inventory[objectType][objectName] and true or false
end

PlayerData.GetPlayerAllCurrencyBalances = function(player: Player): dictionary<string, number>
    local profile = playerProfiles[player.UserId]
    if (not profile) then return {} end

    return copy(profile.Data.Currencies)
end

PlayerData.GetPlayerCurrencyBalance = function(player: Player, currencyType: string): number?
    local profile = playerProfiles[player.UserId]
    if (not profile) then return end

    return profile.Data.Currencies[currencyType]
end

PlayerData.DepositCurrencyToPlayer = function(player: Player, currencyType: string, amount: number)
    local playerId = player.UserId
    local profile = playerProfiles[playerId]
    if (not profile) then return end

    local currenciesBalance

    if (EPHEMERAL_CURRENCIES[currencyType]) then
        currenciesBalance = ephemeralCurrenciesBalances[playerId]
    else
        currenciesBalance = profile.Data.Currencies
    end

    if (currenciesBalance[currencyType]) then
        currenciesBalance[currencyType] = currenciesBalance[currencyType] + amount
    else
        currenciesBalance[currencyType] = amount
    end
end

PlayerData.DepositCurrencyToAllPlayers = function(currencyType: string, amount: number)
    local players = Players:GetPlayers()

    for i = 1, #players do
        PlayerData.DepositCurrencyToPlayer(players[i], currencyType, amount)
    end
end

PlayerData.WithdrawCurrencyFromPlayer = function(player: Player, currencyType: string, amount: number)
    local playerId = player.UserId
    local profile = playerProfiles[playerId]
    assert(profile, "profile is missing")

    local currenciesBalance

    if (EPHEMERAL_CURRENCIES[currencyType]) then
        currenciesBalance = ephemeralCurrenciesBalances[playerId]
    else
        currenciesBalance = profile.Data.Currencies
    end

    if (currenciesBalance[currencyType]) then
        currenciesBalance[currencyType] = currenciesBalance[currencyType] + amount
    else
        currenciesBalance[currencyType] = amount
    end
end

PlayerData.GrantObjectToPlayer = function(player: Player, objectType: string, objectName: string)
    local profile = playerProfiles[player.UserId]
    if (not profile) then return end

    local inventory = profile.Data.Inventory

    if (objectType == GameEnum.ObjectType.Unit) then
        inventory = inventory.Units
    elseif (objectType == GameEnum.ObjectType.Roadblock) then
        inventory = inventory.Roadblocks
    else
        return
    end

    -- todo: check if the object actually exists
    inventory[objectName] = true
end

PlayerData.RevokeObjectFromPlayer = function(player: Player, objectType: string, objectName: string)
    local profile = playerProfiles[player.UserId]
    if (not profile) then return end

    local inventory = profile.Data.Inventory

    if (objectType == GameEnum.ObjectType.Unit) then
        inventory = inventory.Units
    elseif (objectType == GameEnum.ObjectType.Roadblock) then
        inventory = inventory.Roadblocks
    else
        return
    end

    -- todo: check if the object actually exists
    inventory[objectName] = nil
end

PlayerData.GiveSpecialActionToken = function(player: Player, actionName: string, amount: number?)
    amount = amount or 1
    
    local profile = playerProfiles[player.UserId]
    if (not profile) then return end

    local specialActions = profile.Data.Inventory.SpecialActions

    if (specialActions[actionName]) then
        specialActions[actionName] = specialActions[actionName] + amount
    else
        specialActions[actionName] = amount
    end
end

---

do
    local players = Players:GetPlayers()

    for i = 1, #players do
        playerAdded(players[i])
    end
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)

return PlayerData