local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    Type = GameEnum.UnitType.TowerUnit,
    SurfaceType = GameEnum.SurfaceType.Terrain,
    
    ImmutableAttributes = {
        MaxHP = 1,
        DEF = 0,
        SPD = 0,

        UnitTargeting = GameEnum.UnitTargeting.None,
        PathType = GameEnum.PathType.Ground,
    },

    Progression = {
        [1] = {
            Attributes = {
                DMG = 0,
                CD = math.huge,
                RANGE = 0,
            },

            Abilities = {
                PassiveIncome = true,
            }
        },
        
        [2] = {
            Abilities = {
                PassiveIncome2 = true,
            }
        },
        
        [3] = {
            Abilities = {
                PassiveIncome3 = true,
            }
        },

        [4] = {
            Abilities = {
                PassiveIncome4 = true,
            }
        }
    }
}