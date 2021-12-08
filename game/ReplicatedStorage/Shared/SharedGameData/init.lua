local root = script

local AutomaticObjectGrants = require(root:WaitForChild("AutomaticObjectGrants"))
local EphemeralCurrencies = require(root:WaitForChild("EphemeralCurrencies"))
local GameConstants = require(root:WaitForChild("GameConstants"))
local PlaceIds = require(root:WaitForChild("PlaceIds"))

---

return {
    AutomaticObjectGrants = AutomaticObjectGrants,
    EphemeralCurrencies = EphemeralCurrencies,
    GameConstants = GameConstants,
    PlaceIds = PlaceIds,

    Scope = "InDev",
}