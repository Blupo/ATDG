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
        TestAoETowerUnit = 220,
        TestAirTargetingTowerUnit = 370,
        TestPassiveIncomeTowerUnit = 200,
        TestFreezerTowerUnit = 200,

        TestFieldUnit = 10,
        TestAirFieldUnit = 30,
    },

    [GameEnum.ObjectType.Roadblock] = {
        
    },
}