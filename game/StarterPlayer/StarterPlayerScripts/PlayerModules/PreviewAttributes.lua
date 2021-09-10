local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

return {
    [GameEnum.UnitType.TowerUnit] = {"DMG", "RANGE", "CD", "PathType"},
    [GameEnum.UnitType.FieldUnit] = {"MaxHP", "DEF", "SPD", "PathType"},
}