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
        TestPassiveIncomeTowerUnit = 5,
        TestFreezerTowerUnit = 10,

        TestFieldUnit = 2,
        TestBiggerFieldUnit = 5,
        TestAirFieldUnit = 3,

        DEBUG_Obliterator = math.huge,
    },
}