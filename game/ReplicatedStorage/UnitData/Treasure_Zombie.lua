local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    DisplayName = "Zombie",
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
                MaxHP = 4,
                DEF = 0,
                SPD = 4,
            },
        },
    }
}