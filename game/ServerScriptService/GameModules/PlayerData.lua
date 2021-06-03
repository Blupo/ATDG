local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

---

local ProfileService = require(ServerScriptService:FindFirstChild("ProfileService"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local RemoteUtils = require(GameModules:FindFirstChild("RemoteUtils"))

local Communicators = ReplicatedStorage:FindFirstChild("Communicators"):WaitForChild("PlayerData")
local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnums"))
local t = require(SharedModules:FindFirstChild("t"))

local CurrencyDepositedEvent = Instance.new("BindableEvent")
local CurrencyWithdrawnEvent = Instance.new("BindableEvent")

local GetPlayerInventoryRemoteFunction = Instance.new("RemoteFunction")
local PlayerHasObjectGrantRemoteFunction = Instance.new("RemoteFunction")
local GetPlayerAllCurrenciesBalancesRemoteFunction = Instance.new("RemoteFunction")
local GetPlayerCurrencyBalanceRemoteFunction = Instance.new("RemoteFunction")
local CurrencyDepositedRemoteEvent = Instance.new("RemoteEvent")
local CurrencyWithdrawnRemoteEvent = Instance.new("RemoteEvent")

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
    local userId = player.UserId
    local ephemeralCurrenciesBalance = {}
    local profile = ProfileStore:LoadProfileAsync(tostring(userId), "ForceLoad")

    if (profile) then
        -- todo: provide a mechanism for merging old data versions
        playerProfiles[userId] = profile

        profile:ListenToRelease(function()
            playerProfiles[userId] = nil
            -- todo: come up with a better message than this
            player:Kick("User profile was released")
        end)

        if player:IsDescendantOf(Players) then
            for currencyType in pairs(EPHEMERAL_CURRENCIES) do
                ephemeralCurrenciesBalance[currencyType] = 0
            end

            playerProfiles[userId] = profile
            ephemeralCurrenciesBalances[userId] = ephemeralCurrenciesBalance
        else
            profile:Release()
        end
    else
        -- todo: come up with a better message than this
        player:Kick("Could not load user profile")
    end
end

local playerRemoving = function(player: Player)
    local userId = player.UserId
    local profile = playerProfiles[userId]
    if (not profile) then return end

    profile:Release()
    ephemeralCurrenciesBalances[userId] = nil
end

---

local PlayerData = {}
PlayerData.CurrencyDeposited = CurrencyDepositedEvent.Event
PlayerData.CurrencyWithdrawn = CurrencyWithdrawnEvent.Event

PlayerData.GetPlayerProfile = function(userId: number)
    return playerProfiles[userId]
end

PlayerData.WaitForPlayerProfile = function(userId: number)
    while (not playerProfiles[userId]) do
        RunService.Heartbeat:Wait()
    end

    return playerProfiles[userId]
end

PlayerData.GetPlayerInventory = function(userId: number): PlayerInventory?
    local profile = playerProfiles[userId]
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

PlayerData.PlayerHasObjectGrant = function(userId: number, objectType: string, objectName: string): boolean
    -- check perma grants
    if (PERMA_GRANTS[objectType][objectName]) then return true end

    local profile = playerProfiles[userId]
    if (not profile) then return false end

    return profile.Data.Inventory[objectType][objectName] and true or false
end

PlayerData.GetPlayerAllCurrenciesBalances = function(userId: number): dictionary<string, number>
    local profile = playerProfiles[userId]
    if (not profile) then return {} end

    local currenciesBalances = {}

    for currency in pairs(GameEnum.CurrencyType) do
        if (EPHEMERAL_CURRENCIES[currency]) then
            currenciesBalances[currency] = ephemeralCurrenciesBalances[userId][currency] or 0
        else
            currenciesBalances[currency] = profile.Data.Currencies[currency] or 0
        end
    end

    return currenciesBalances
end

PlayerData.GetPlayerCurrencyBalance = function(userId: number, currencyType: string): number?
    local profile = playerProfiles[userId]
    if (not profile) then return end

    if (EPHEMERAL_CURRENCIES[currencyType]) then
        return ephemeralCurrenciesBalances[userId][currencyType] or 0
    else
        return profile.Data.Currencies[currencyType] or 0
    end
end

PlayerData.DepositCurrencyToPlayer = function(userId: number, currencyType: string, amount: number)
    if (amount <= 0) then return end

    local profile = playerProfiles[userId]
    if (not profile) then return end

    local currenciesBalances

    if (EPHEMERAL_CURRENCIES[currencyType]) then
        currenciesBalances = ephemeralCurrenciesBalances[userId]
    else
        currenciesBalances = profile.Data.Currencies
    end

    if (currenciesBalances[currencyType]) then
        currenciesBalances[currencyType] = currenciesBalances[currencyType] + amount
    else
        currenciesBalances[currencyType] = amount
    end

    CurrencyDepositedEvent:Fire(userId, currencyType, amount, currenciesBalances[currencyType])
end

PlayerData.DepositCurrencyToAllPlayers = function(currencyType: string, amount: number)
    local players = Players:GetPlayers()

    for i = 1, #players do
        PlayerData.DepositCurrencyToPlayer(players[i].UserId, currencyType, amount)
    end
end

PlayerData.WithdrawCurrencyFromPlayer = function(userId: number, currencyType: string, amount: number)
    if (amount <= 0) then return end

    local profile = playerProfiles[userId]
    assert(profile, "profile is missing")

    local currenciesBalances

    if (EPHEMERAL_CURRENCIES[currencyType]) then
        currenciesBalances = ephemeralCurrenciesBalances[userId]
    else
        currenciesBalances = profile.Data.Currencies
    end

    if (currenciesBalances[currencyType]) then
        local balance = currenciesBalances[currencyType]
        if (amount > balance) then return end

        currenciesBalances[currencyType] = balance - amount
    else
        return
    end

    CurrencyWithdrawnEvent:Fire(userId, currencyType, amount, currenciesBalances[currencyType])
end

PlayerData.GrantObjectToPlayer = function(userId: number, objectType: string, objectName: string)
    local profile = playerProfiles[userId]
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

PlayerData.RevokeObjectFromPlayer = function(userId: number, objectType: string, objectName: string)
    local profile = playerProfiles[userId]
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

PlayerData.GiveSpecialActionToken = function(userId: number, actionName: string, amount: number?)
    amount = amount or 1
    
    local profile = playerProfiles[userId]
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

CurrencyDepositedEvent.Event:Connect(function(userId, ...)
    local player = Players:GetPlayerByUserId(userId)
    if (not player) then return end

    CurrencyDepositedRemoteEvent:FireClient(player, userId, ...)
end)

CurrencyWithdrawnEvent.Event:Connect(function(userId, ...)
    local player = Players:GetPlayerByUserId(userId)
    if (not player) then return end
    
    CurrencyWithdrawnRemoteEvent:FireClient(player, userId, ...)
end)

GetPlayerInventoryRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(function(player: Player)
    return PlayerData.GetPlayerInventory(player)
end)

PlayerHasObjectGrantRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number, unitName: string): boolean?
    if (callingPlayer.UserId ~= userId) then return end

    return PlayerData.PlayerHasObjectGrant(userId, unitName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)))

GetPlayerAllCurrenciesBalancesRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number)
    if (callingPlayer.UserId ~= userId) then return end

    return PlayerData.GetPlayerAllCurrenciesBalances(userId)
end, t.tuple(t.instanceOf("Player"), t.number)))

GetPlayerCurrencyBalanceRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(t.wrap(function(callingPlayer: Player, userId: number, currencyType: string): number?
    if (callingPlayer.UserId ~= userId) then return end

    return PlayerData.GetPlayerCurrencyBalance(userId, currencyType)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)))

GetPlayerInventoryRemoteFunction.Name = "GetPlayerInventory"
PlayerHasObjectGrantRemoteFunction.Name = "PlayerHasObjectGrant"
GetPlayerAllCurrenciesBalancesRemoteFunction.Name = "GetPlayerAllCurrenciesBalances"
GetPlayerCurrencyBalanceRemoteFunction.Name = "GetPlayerCurrencyBalance"
CurrencyDepositedRemoteEvent.Name = "CurrencyDeposited"
CurrencyWithdrawnRemoteEvent.Name = "CurrencyWithdrawn"

GetPlayerInventoryRemoteFunction.Parent = Communicators
PlayerHasObjectGrantRemoteFunction.Parent = Communicators
GetPlayerAllCurrenciesBalancesRemoteFunction.Parent = Communicators
GetPlayerCurrencyBalanceRemoteFunction.Parent = Communicators
CurrencyDepositedRemoteEvent.Parent = Communicators
CurrencyWithdrawnRemoteEvent.Parent = Communicators

return PlayerData