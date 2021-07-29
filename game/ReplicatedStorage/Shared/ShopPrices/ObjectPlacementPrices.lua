local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

-- Prices in Points

return {
    [GameEnum.ObjectType.Unit] = {
        TestTowerUnit = 100,
        TestHeavyTowerUnit = 300,

        TestFieldUnit = 10,
    },

    [GameEnum.ObjectType.Roadblock] = {
        
    },
}