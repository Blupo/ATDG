local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    Type = GameEnum.UnitType.FieldUnit,

    ImmutableAttributes = {
        DMG = 0,
        CD = 0,
        RANGE = 0,

        PathType = GameEnum.PathType.Ground,
    },
    
    Progression = {
        [1] = {
            Attributes = {
                MaxHP = 10,
                DEF = 0,
                SPD = 8,
            },
        },
    }
}