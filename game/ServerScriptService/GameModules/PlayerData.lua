local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

---

local ProfileService = require(ServerScriptService:FindFirstChild("ProfileService"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local CopyTable = require(SharedModules:FindFirstChild("CopyTable"))
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local MakeActionResult = require(SharedModules:FindFirstChild("MakeActionResult"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local SharedGameData = require(SharedModules:WaitForChild("SharedGameData"))
local AutomaticObjectGrants = SharedGameData.AutomaticObjectGrants
local EphemeralCurrencies = SharedGameData.EphemeralCurrencies
local GameConstants = SharedGameData.GameConstants

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local ServerMaster = require(GameModules:FindFirstChild("ServerMaster"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local CurrencyBalanceChangedEvent = Instance.new("BindableEvent")
local ObjectGrantedEvent = Instance.new("BindableEvent")
local InventoryChangedEvent = Instance.new("BindableEvent")
local HotbarChangedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("PlayerData")
local CurrencyBalanceChangedRemoteEvent = System.addEvent("CurrencyBalanceChanged")
local ObjectGrantedRemoteEvent = System.addEvent("ObjectGranted")
local InventoryChangedRemoteEvent = System.addEvent("InventoryChanged")
local HotbarChangedRemoteEvent = System.addEvent("HotbarChanged")

---

type dictionary<T, TT> = {[T]: TT}
type array<T> = {[number]: T}

type PlayerObjectGrants = {
    Unit: dictionary<string, boolean>,
}

type PlayerInventory = {
    SpecialAction: dictionary<string, number>
}

type PlayerHotbars = {
    TowerUnit: array<string>,
    FieldUnit: array<string>,
}

type PlayerData = {
    Currencies: dictionary<string, number>,
    ObjectGrants: PlayerObjectGrants,
    Inventory: PlayerInventory,
    Hotbars: PlayerHotbars,
    Transactions: dictionary<string, boolean>
}

type TransactionRecordingResult = {
    Success: boolean,
    FailureReason: string,
}

---

local PlayerDataTemplate: PlayerData = {
    Transactions = {},

    Hotbars = {
        [GameEnum.UnitType.TowerUnit] = {},
        [GameEnum.UnitType.FieldUnit] = {},
    },
    
    Currencies = {
        [GameEnum.CurrencyType.Tickets] = 10,
    },

    ObjectGrants = {
        [GameEnum.ObjectType.Unit] = {},
    },
    
    Inventory = {
        [GameEnum.ItemType.SpecialAction] = {
            Expel_TEST = 1,
        },
    },
}

local ProfileStore = ProfileService.GetProfileStore({
    Name = "PlayerData",
    Scope = SharedGameData.Scope
}, PlayerDataTemplate)

ProfileStore = RunService:IsStudio() and ProfileStore.Mock or ProfileStore

local playerProfiles = {}
local ephemeralCurrenciesBalances = {}
local serverType = ServerMaster.GetServerType() or ServerMaster.ServerInitialised:Wait()

local playerAdded = function(player: Player)
    local userId = player.UserId
    local ephemeralCurrenciesBalance = {}
    local profile = ProfileStore:LoadProfileAsync(tostring(userId), "ForceLoad")

    if (profile) then
        -- todo: provide a mechanism for merging old data versions
        profile:AddUserId(userId)

        profile:ListenToRelease(function()
            playerProfiles[userId] = nil
            player:Kick("Player data is no longer available")
        end)

        if (player:IsDescendantOf(Players)) then
            --- INDEV
            profile.Data.ObjectGrants.Roadblocks = nil
            profile.Data.Hotbars.Roadblocks = nil
            ---

            -- verify hotbars
            local towerUnitHotbar = profile.Data.Hotbars[GameEnum.UnitType.TowerUnit]
            local fieldUnitHotbar = profile.Data.Hotbars[GameEnum.UnitType.FieldUnit]

            for i = #towerUnitHotbar, 1, -1 do
                local unitName = towerUnitHotbar[i]

                local unitExists = Unit.DoesUnitExist(unitName)
                local permaGrantStatus = AutomaticObjectGrants[GameEnum.ObjectType.Unit][unitName]
                local grantStatus = profile.Data.ObjectGrants[GameEnum.ObjectType.Unit][unitName]

                if (not (unitExists and (permaGrantStatus or grantStatus))) then
                    table.remove(towerUnitHotbar, i)
                end
            end

            for i = #fieldUnitHotbar, 1, -1 do
                local unitName = fieldUnitHotbar[i]

                local unitExists = Unit.DoesUnitExist(unitName)
                local permaGrantStatus = AutomaticObjectGrants[GameEnum.ObjectType.Unit][unitName]
                local grantStatus = profile.Data.ObjectGrants[GameEnum.ObjectType.Unit][unitName]

                if (not (unitExists and (permaGrantStatus or grantStatus))) then
                    table.remove(fieldUnitHotbar, i)
                end
            end

            -- verify object grants
            local unitGrants = profile.Data.ObjectGrants[GameEnum.ObjectType.Unit]

            for unitName in pairs(unitGrants) do
                if (not Unit.DoesUnitExist(unitName)) then
                    unitGrants[unitName] = nil
                end
            end

            -- setup ephemeral currencies
            if (serverType == GameEnum.ServerType.Game) then
                for currencyType in pairs(EphemeralCurrencies) do
                    ephemeralCurrenciesBalance[currencyType] = 0
                end
            end

            playerProfiles[userId] = profile
            ephemeralCurrenciesBalances[userId] = ephemeralCurrenciesBalance
        else
            profile:Release()
        end
    else
        player:Kick("Could not load player data, please try again later.")
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

local PlayerData = {
    CurrencyBalanceChanged = CurrencyBalanceChangedEvent.Event,
    ObjecctGranted = ObjectGrantedEvent.Event,
    InventoryChanged = InventoryChangedEvent.Event,
    HotbarChanged = HotbarChangedEvent.Event,
}

PlayerData.WaitForPlayerProfile = function(userId: number)
    return Promise.new(function(resolve)
        while (not playerProfiles[userId]) do
            RunService.Heartbeat:Wait()
        end

        resolve(playerProfiles[userId])
    end)
end

PlayerData.WaitForPlayerData = function(userId: number)
    while (not playerProfiles[userId]) do
        RunService.Heartbeat:Wait()
    end

    return playerProfiles[userId].Data
end

PlayerData.RecordTransaction = function(userId: number, transactionType: string, transactionId: string, transactionInfo: {[string]: any})
    transactionId = transactionId or HttpService:GenerateGUID(false)

    local profile = playerProfiles[userId]
    if (not profile) then return MakeActionResult(GameEnum.TransactionRecordingFailureReason.ProfileNotReady) end

    local transactions = profile.Data.Transactions
    if (transactions[transactionId]) then return MakeActionResult(GameEnum.TransactionRecordingFailureReason.TransactionAlreadyRecorded) end

    transactionInfo = CopyTable(transactionInfo)
    transactionInfo.TransactionType = transactionType
    transactionInfo.TransactionDate = DateTime.now():ToIsoDate()
    transactions[transactionId] = transactionInfo

    --- FOR DEBUG ONLY
    print("Transaction " .. transactionId .. " Information")

    for k, v in pairs(transactionInfo) do
        print(k .. ": ", v)
    end

    print("--------------------")
    ---

    return MakeActionResult()
end

PlayerData.GetPlayerInventory = function(userId: number): PlayerInventory?
    local profile = playerProfiles[userId]
    if (not profile) then return end

    return CopyTable(profile.Data.Inventory)
end

PlayerData.GetPlayerInventoryItemCount = function(userId: number, itemType: string, itemName: string): number?
    local profile = playerProfiles[userId]
    if (not profile) then return end

    local inventory = profile.Data.Inventory[itemType]
    if (not inventory) then return end

    return inventory[itemName] or 0
end

-- todo: validate that the item actually exists
PlayerData.AddItemToPlayerInventory = function(userId: number, itemType: string, itemName: string, amount: number): boolean
    local profile = playerProfiles[userId]
    if (not profile) then return false end

    local inventory = profile.Data.Inventory[itemType]
    if (not inventory) then return false end

    local itemCount = inventory[itemName]
    
    if (itemCount) then
        inventory[itemName] = itemCount + amount
    else
        inventory[itemName] = amount
    end

    InventoryChangedEvent:Fire(userId, itemType, itemName, inventory[itemName], amount)
    return true
end

-- todo: validate that the item actually exists
PlayerData.RemoveItemFromInventory = function(userId: number, itemType: string, itemName: string, amount: number): boolean
    local profile = playerProfiles[userId]
    if (not profile) then return false end

    local inventory = profile.Data.Inventory[itemType]
    if (not inventory) then return false end

    local itemCount = inventory[itemName] or 0
    
    if (itemCount >= amount) then
        inventory[itemName] = itemCount - amount

        InventoryChangedEvent:Fire(userId, itemType, itemName, inventory[itemName], -amount)
        return true
    else
        return false
    end
end

PlayerData.GetPlayerObjectGrants = function(userId: number): PlayerObjectGrants?
    local profile = playerProfiles[userId]
    if (not profile) then return end

    local grants = CopyTable(profile.Data.ObjectGrants)

    for objectType, permaGrants in pairs(AutomaticObjectGrants) do
        for objectName in pairs(permaGrants) do
            grants[objectType][objectName] = true
        end
    end

    return grants
end

PlayerData.PlayerHasObjectGrant = function(userId: number, objectType: string, objectName: string): boolean
    local profile = playerProfiles[userId]
    if (not profile) then return false end

    local permaGrantStatus = AutomaticObjectGrants[objectType][objectName]
    if (permaGrantStatus) then return permaGrantStatus end

    return profile.Data.ObjectGrants[objectType][objectName] and true or false
end

-- should we distinguish between success, fail, and already granted?
PlayerData.GrantObjectToPlayer = function(userId: number, objectType: string, objectName: string): boolean
    local profile = playerProfiles[userId]
    if (not profile) then return false end

    -- perma-granted items do not save to player data
    local permaGrantStatus = AutomaticObjectGrants[objectType][objectName]
    if (permaGrantStatus) then return true end

    local grants = profile.Data.ObjectGrants[objectType]

    if (grants[objectName]) then
        return true
    else
        grants[objectName] = true

        ObjectGrantedEvent:Fire(userId, objectType, objectName)
        return true
    end
end

PlayerData.GetPlayerHotbars = function(userId: number): PlayerHotbars?
    local profile = playerProfiles[userId]
    if (not profile) then return end

    return CopyTable(profile.Data.Hotbars)
end

PlayerData.GetPlayerHotbar = function(userId: number, objectType: string): array<string>?
    local profile = playerProfiles[userId]
    if (not profile) then return end

    local hotbar = profile.Data.Hotbars[objectType]
    if (not hotbar) then return end

    return CopyTable(hotbar)
end

PlayerData.SetPlayerHotbar = function(userId: number, objectType: string, newHotbar: array<string>): boolean
    if (#newHotbar > GameConstants.MaxHotbarItems) then return false end
    
    local profile = playerProfiles[userId]
    if (not profile) then return false end

    if ((objectType == GameEnum.UnitType.TowerUnit) or (objectType == GameEnum.UnitType.FieldUnit)) then
        for i = 1, #newHotbar do
            local unitName = newHotbar[i]

            local unitExists = Unit.DoesUnitExist(unitName)
            local permaGrantStatus = AutomaticObjectGrants[GameEnum.ObjectType.Unit][unitName]
            local grantStatus = profile.Data.ObjectGrants[GameEnum.ObjectType.Unit][unitName]

            if (not (unitExists and (permaGrantStatus or grantStatus))) then return false end
        end
    end

    local hotbars = profile.Data.Hotbars
    hotbars[objectType] = CopyTable(newHotbar)

    HotbarChangedEvent:Fire(userId, objectType, newHotbar)
    return true
end

PlayerData.GetPlayerAllCurrenciesBalances = function(userId: number): dictionary<string, number>?
    local profile = playerProfiles[userId]
    if (not profile) then return end

    local currenciesBalances = {}

    for currency in pairs(GameEnum.CurrencyType) do -- badness
        if (EphemeralCurrencies[currency]) then
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

    if (EphemeralCurrencies[currencyType]) then
        return ephemeralCurrenciesBalances[userId][currencyType] or 0
    else
        return profile.Data.Currencies[currencyType] or 0
    end
end

PlayerData.DepositCurrencyToPlayer = function(userId: number, currencyType: string, amount: number): boolean
    if (amount <= 0) then return false end

    local profile = playerProfiles[userId]
    if (not profile) then return false end

    local currenciesBalances

    if (EphemeralCurrencies[currencyType]) then
        currenciesBalances = ephemeralCurrenciesBalances[userId]
    else
        currenciesBalances = profile.Data.Currencies
    end

    if (currenciesBalances[currencyType]) then
        currenciesBalances[currencyType] = currenciesBalances[currencyType] + amount
    else
        currenciesBalances[currencyType] = amount
    end

    CurrencyBalanceChangedEvent:Fire(userId, currencyType, currenciesBalances[currencyType], amount)
    return true
end

PlayerData.DepositCurrencyToAllPlayers = function(currencyType: string, amount: number)
    local players = Players:GetPlayers()

    for i = 1, #players do
        PlayerData.DepositCurrencyToPlayer(players[i].UserId, currencyType, amount)
    end
end

PlayerData.WithdrawCurrencyFromPlayer = function(userId: number, currencyType: string, amount: number): boolean
    if (amount <= 0) then return false end

    local profile = playerProfiles[userId]
    if (not profile) then return false end

    local currenciesBalances

    if (EphemeralCurrencies[currencyType]) then
        currenciesBalances = ephemeralCurrenciesBalances[userId]
    else
        currenciesBalances = profile.Data.Currencies
    end

    if (currenciesBalances[currencyType]) then
        local balance = currenciesBalances[currencyType]
        if (amount > balance) then return false end

        currenciesBalances[currencyType] = balance - amount
    else
        return false
    end

    CurrencyBalanceChangedEvent:Fire(userId, currencyType, currenciesBalances[currencyType], -amount)
    return true
end

---

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)

CurrencyBalanceChangedEvent.Event:Connect(function(userId, ...)
    local player = Players:GetPlayerByUserId(userId)
    if (not player) then return end

    CurrencyBalanceChangedRemoteEvent:FireClient(player, userId, ...)
end)

ObjectGrantedEvent.Event:Connect(function(userId, ...)
    local player = Players:GetPlayerByUserId(userId)
    if (not player) then return end

    ObjectGrantedRemoteEvent:FireClient(player, userId, ...)
end)

InventoryChangedEvent.Event:Connect(function(userId, ...)
    local player = Players:GetPlayerByUserId(userId)
    if (not player) then return end

    InventoryChangedRemoteEvent:FireClient(player, userId, ...)
end)

HotbarChangedEvent.Event:Connect(function(userId, ...)
    local player = Players:GetPlayerByUserId(userId)
    if (not player) then return end

    HotbarChangedRemoteEvent:FireClient(player, userId, ...)
end)

System.addFunction("WaitForPlayerData", t.wrap(function(player: Player, userId: number)
    if (player.UserId ~= userId) then return end

    return PlayerData.WaitForPlayerData(userId)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

System.addFunction("GetPlayerInventory", t.wrap(function(player: Player, userId: number)
    if (player.UserId ~= userId) then return end

    return PlayerData.GetPlayerInventory(userId)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

System.addFunction("GetPlayerInventoryItemCount", t.wrap(function(player: Player, userId: number, itemType: string, itemName: string)
    if (player.UserId ~= userId) then return end

    return PlayerData.GetPlayerInventoryItemCount(userId, itemType, itemName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string, t.string)), true)

System.addFunction("GetPlayerObjectGrants", t.wrap(function(player: Player, userId: number)
    if (player.UserId ~= userId) then return end

    return PlayerData.GetPlayerObjectGrants(userId)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

System.addFunction("PlayerHasObjectGrant", t.wrap(function(player: Player, userId: number, objectType: string, objectName: string)
    if (player.UserId ~= userId) then return false end

    return PlayerData.PlayerHasObjectGrant(userId, objectType, objectName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string, t.string)), true)

System.addFunction("GetPlayerHotbars", t.wrap(function(player: Player, userId: number)
    if (player.UserId ~= userId) then return end

    return PlayerData.GetPlayerHotbars(userId)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

System.addFunction("GetPlayerHotbar", t.wrap(function(player: Player, userId: number, objectType: string, subType: string?)
    if (player.UserId ~= userId) then return end

    PlayerData.GetPlayerHotbar(userId, objectType, subType)
end, t.tuple(t.instanceOf("Player"), t.number, t.string, t.optional(t.string))), true)

System.addFunction("SetPlayerHotbar", t.wrap(function(player: Player, userId: number, objectType: string, newHotbar: array<string>)
    if (player.UserId ~= userId) then return false end

    return PlayerData.SetPlayerHotbar(userId, objectType, newHotbar)
end, t.tuple(t.instanceOf("Player"), t.number, t.string, t.array(t.string))), true)

System.addFunction("GetPlayerAllCurrenciesBalances", t.wrap(function(player: Player, userId: number)
    if (player.UserId ~= userId) then return end

    return PlayerData.GetPlayerAllCurrenciesBalances(userId)
end, t.tuple(t.instanceOf("Player"), t.nubmer)), true)

System.addFunction("GetPlayerCurrencyBalance", t.wrap(function(player: Player, userId: number, currencyType: string)
    if (player.UserId ~= userId) then return end

    return PlayerData.GetPlayerCurrencyBalance(userId, currencyType)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)

---

do
    local players = Players:GetPlayers()

    for i = 1, #players do
        playerAdded(players[i])
    end
end

return PlayerData