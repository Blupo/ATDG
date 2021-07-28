local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    [GameEnum.ObjectType.Unit] = {
        TestTowerUnit = true,
        TestHeavyTowerUnit = true,
    },

    [GameEnum.ObjectType.Roadblock] = {

    }
}