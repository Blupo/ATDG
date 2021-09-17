local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

-- Prices in Points

return {
    [GameEnum.ObjectType.Unit] = {
        ArmedGuard = 700,
        Bob = 300,
        Bank = 450,
        FreezerTower = 600,
        GiantBob = 900,

        DEBUG_Obliterator = 0,
    },
}