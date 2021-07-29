local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---

local root = script

local ItemPrices = require(root:WaitForChild("ItemPrices"))
local ObjectGrantPrices = require(root:WaitForChild("ObjectGrantPrices"))
local ObjectPlacementPrices = require(root:WaitForChild("ObjectPlacementPrices"))
local UnitUpgradePrices = require(root:WaitForChild("UnitUpgradePrices"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

local Unit

local unitGrantPrices = ObjectGrantPrices[GameEnum.ObjectType.Unit]
local unitPlacementPrices = ObjectPlacementPrices[GameEnum.ObjectType.Unit]

if (RunService:IsServer()) then
    local ServerScriptService = game:GetService("ServerScriptService")
    local GameModules = ServerScriptService:FindFirstChild("GameModules")

    Unit = require(GameModules:FindFirstChild("Unit"))
elseif (RunService:IsClient()) then
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
    local GameModules = PlayerScripts:WaitForChild("GameModules")

    Unit = require(GameModules:WaitForChild("Unit"))
end

for unitName in pairs(unitGrantPrices) do
    if (not Unit.DoesUnitExist(unitName)) then
        unitGrantPrices[unitName] = nil
    end
end

for unitName in pairs(unitPlacementPrices) do
    if (not Unit.DoesUnitExist(unitName)) then
        unitPlacementPrices[unitName] = nil
    end
end

for unitName in pairs(UnitUpgradePrices) do
    if (not Unit.DoesUnitExist(unitName)) then
        UnitUpgradePrices[unitName] = nil
    else
        local maxPurchasableLevel = -1
        local maxUnitLevel = Unit.GetUnitMaxLevel(unitName)

        for level in pairs(UnitUpgradePrices[unitName]) do
            if (level > maxPurchasableLevel) then
                maxPurchasableLevel = level
            end
        end

        if (maxPurchasableLevel > maxUnitLevel) then
            UnitUpgradePrices[unitName] = nil
        end
    end
end

---

return {
    ItemPrices = ItemPrices,
    ObjectGrantPrices = ObjectGrantPrices,
    ObjectPlacementPrices = ObjectPlacementPrices,
    UnitUpgradePrices = UnitUpgradePrices,
}