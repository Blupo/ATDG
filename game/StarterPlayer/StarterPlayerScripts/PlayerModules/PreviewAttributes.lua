local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

return {
    [GameEnum.UnitType.TowerUnit] = {"DMG", "RANGE", "CD", "PathType"},
    [GameEnum.UnitType.FieldUnit] = {"HP", "DEF", "SPD", "PathType"},
    [GameEnum.ObjectType.Roadblock] = {} -- todo
}