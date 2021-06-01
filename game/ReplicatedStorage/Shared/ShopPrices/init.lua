local root = script

local ItemPrices = require(root:WaitForChild("ItemPrices"))
local ObjectPlacementPrices = require(root:WaitForChild("ObjectPlacementPrices"))
local UnitUpgradePrices = require(root:WaitForChild("UnitUpgradePrices"))

---

return {
    ItemPrices = ItemPrices,
    ObjectPlacementPrices = ObjectPlacementPrices,
    UnitUpgradePrices = UnitUpgradePrices,
}