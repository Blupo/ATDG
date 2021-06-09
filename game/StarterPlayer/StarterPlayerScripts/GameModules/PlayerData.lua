local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local Communicators = ReplicatedStorage:WaitForChild("Communicators"):WaitForChild("PlayerData")

local Util = script.Parent.Parent:WaitForChild("Util")
local RemoteFunctionWrapper = require(Util:WaitForChild("RemoteFunctionWrapper"))

local GetPlayerInventory = Communicators:WaitForChild("GetPlayerInventory")
local GetPlayerInventoryItemCount = Communicators:WaitForChild("GetPlayerInventoryItemCount")

local GetPlayerObjectGrants = Communicators:WaitForChild("GetPlayerObjectGrants")
local PlayerHasObjectGrant = Communicators:WaitForChild("PlayerHasObjectGrant")

local GetPlayerHotbars = Communicators:WaitForChild("GetPlayerHotbars")
local GetPlayerHotbar = Communicators:WaitForChild("GetPlayerHotbar")
local SetPlayerHotbar = Communicators:WaitForChild("SetPlayerHotbar")

local GetPlayerAllCurrenciesBalances = Communicators:WaitForChild("GetPlayerAllCurrenciesBalances")
local GetPlayerCurrencyBalance = Communicators:WaitForChild("GetPlayerCurrencyBalance")

local CurrencyBalanceChanged = Communicators:WaitForChild("CurrencyBalanceChanged")
local ObjectGranted = Communicators:WaitForChild("ObjectGranted")
local InventoryChanged = Communicators:WaitForChild("InventoryChanged")
local HotbarChanged = Communicators:WaitForChild("HotbarChanged")

---

local LocalPlayer = Players.LocalPlayer

-- todo: should cache the local player's currency balances
local localPlayerCurrenciesBalances

---

local PlayerData = {
    GetPlayerInventory = RemoteFunctionWrapper(GetPlayerInventory),
    GetPlayerInventoryItemCount = RemoteFunctionWrapper(GetPlayerInventoryItemCount),

    GetPlayerObjectGrants = RemoteFunctionWrapper(GetPlayerObjectGrants),
    PlayerHasObjectGrant = RemoteFunctionWrapper(PlayerHasObjectGrant),

    GetPlayerHotbars = RemoteFunctionWrapper(GetPlayerHotbars),
    GetPlayerHotbar = RemoteFunctionWrapper(GetPlayerHotbar),
    SetPlayerHotbar = RemoteFunctionWrapper(SetPlayerHotbar),

    GetPlayerAllCurrenciesBalances = RemoteFunctionWrapper(GetPlayerAllCurrenciesBalances),
    GetPlayerCurrencyBalance = RemoteFunctionWrapper(GetPlayerCurrencyBalance),

    CurrencyBalanceChanged = CurrencyBalanceChanged.OnClientEvent,
    ObjectGranted = ObjectGranted.OnClientEvent,
    InventoryChanged = InventoryChanged.OnClientEvent,
    HotbarChanged = HotbarChanged.OnClientEvent,
}

return PlayerData