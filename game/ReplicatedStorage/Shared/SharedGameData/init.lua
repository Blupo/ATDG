local root = script

local AutomaticObjectGrants = require(root:WaitForChild("AutomaticObjectGrants"))
local EphemeralCurrencies = require(root:WaitForChild("EphemeralCurrencies"))
local GameConstants = require(root:WaitForChild("GameConstants"))

---

return {
    AutomaticObjectGrants = AutomaticObjectGrants,
    EphemeralCurrencies = EphemeralCurrencies,
    GameConstants = GameConstants,

    Scope = "InDev",
}