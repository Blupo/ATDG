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
        TestAoETowerUnit = 20,
        TestAirTargetingTowerUnit = 35,

        TestFieldUnit = 2,
        TestAirFieldUnit = 3,
    },

    [GameEnum.ObjectType.Roadblock] = {

    }
}