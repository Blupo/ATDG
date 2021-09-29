local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    DisplayName = "Frost Zombie",
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
                MaxHP = 160,
                DEF = 2,
                SPD = 8,
            },

            Abilities = {
                InnateFrost = true,
            }
        },
    }
}