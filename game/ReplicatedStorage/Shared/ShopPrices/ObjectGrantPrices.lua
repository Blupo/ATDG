local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

-- Prices in Tickets

return {
    [GameEnum.ObjectType.Unit] = {
        TestTowerUnit = 10,
        TestHeavyTowerUnit = 30,

        TestFieldUnit = 2,
    },

    [GameEnum.ObjectType.Roadblock] = {

    }
}