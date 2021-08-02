local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

return {
    [GameEnum.ObjectType.Unit] = {
        TestTowerUnit = true,
        TestHeavyTowerUnit = true,
        TestAoETowerUnit = true,
        TestAirTargetingTowerUnit = true,
        TestPassiveIncomeTowerUnit = true,
        TestFreezerTowerUnit = true,
    },

    [GameEnum.ObjectType.Roadblock] = {

    }
}