local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

return {
    [GameEnum.ObjectType.Unit] = {
        ArmedGuard = true,
        Bob = true,
        Bank = true,
        FreezerTower = true,
        GiantBob = true,

        DEBUG_Obliterator = true,
    },
}