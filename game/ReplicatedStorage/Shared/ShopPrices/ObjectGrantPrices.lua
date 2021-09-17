local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

-- Prices in Tickets

return {
    [GameEnum.ObjectType.Unit] = {
        ArmedGuard = 0,
        Bob = 0,
        Bank = 0,
        FreezerTower = 0,
        GiantBob = 0,

        DEBUG_Obliterator = math.huge,
    },
}