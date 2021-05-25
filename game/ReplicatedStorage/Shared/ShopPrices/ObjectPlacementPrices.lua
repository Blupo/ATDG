local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

---

return {
    [GameEnum.ObjectType.Unit] = {
        TestTowerUnit = 100,
        TestFieldUnit = 10,
    },

    [GameEnum.ObjectType.Roadblock] = {
        
    },
}