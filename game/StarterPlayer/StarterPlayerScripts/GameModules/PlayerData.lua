local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local Communicators = ReplicatedStorage:WaitForChild("Communicators"):WaitForChild("PlayerData")

local Util = script.Parent.Parent:WaitForChild("Util")
local RemoteFunctionWrapper = require(Util:WaitForChild("RemoteFunctionWrapper"))

local GetPlayerInventory = Communicators:WaitForChild("GetPlayerInventory")
local PlayerHasObjectGrant = Communicators:WaitForChild("PlayerHasObjectGrant")
local GetPlayerAllCurrenciesBalances = Communicators:WaitForChild("GetPlayerAllCurrenciesBalances")
local GetPlayerCurrencyBalance = Communicators:WaitForChild("GetPlayerCurrencyBalance")
local CurrencyDeposited = Communicators:WaitForChild("CurrencyDeposited")
local CurrencyWithdrawn = Communicators:WaitForChild("CurrencyWithdrawn")

---

local LocalPlayer = Players.LocalPlayer

-- todo: should cache the local player's currency balances
local localPlayerCurrenciesBalances

---

local PlayerData = {}

PlayerData.CurrencyDeposited = CurrencyDeposited.OnClientEvent
PlayerData.CurrencyWithdrawn = CurrencyWithdrawn.OnClientEvent

PlayerData.GetPlayerAllCurrenciesBalances = RemoteFunctionWrapper(GetPlayerAllCurrenciesBalances)
PlayerData.GetPlayerCurrencyBalance = RemoteFunctionWrapper(GetPlayerCurrencyBalance)

---

return PlayerData