-- todo: unit upgrade prices should be validated

local root = script

local ItemPrices = require(root:WaitForChild("ItemPrices"))
local ObjectGrantPrices = require(root:WaitForChild("ObjectGrantPrices"))
local ObjectPlacementPrices = require(root:WaitForChild("ObjectPlacementPrices"))
local UnitUpgradePrices = require(root:WaitForChild("UnitUpgradePrices"))

---

return {
    ItemPrices = ItemPrices,
    ObjectGrantPrices = ObjectGrantPrices,
    ObjectPlacementPrices = ObjectPlacementPrices,
    UnitUpgradePrices = UnitUpgradePrices,
}