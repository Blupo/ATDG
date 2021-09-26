local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    DisplayName = "Unit Data Example",
    Type = GameEnum.UnitType.TowerUnit,
    SurfaceType = GameEnum.SurfaceType.Terrain,
    
    ImmutableAttributes = {
        MaxHP = 1,
        DEF = 0,
        SPD = 0,

        UnitTargeting = GameEnum.UnitTargeting.AreaOfEffect,
        PathType = GameEnum.PathType.GroundAndAir,
    },

    Progression = {
        [1] = {
            Attributes = {
                DMG = 0,
                CD = 3,
                RANGE = 30,
            },

            Abilities = {
                Freezer = true,
            }
        },
        
        [2] = {
            Attributes = {
                DMG = 5,
                CD = 2.5,
            },
        },
        
        [3] = {
            Attributes = {
                DMG = 10,
                CD = 2,
            },

            Abilities = {
                Freezer = false,
                Freezer2 = true,
            }
        },

        [4] = {
            Attributes = {
                DMG = 20,
                CD = 1,
            },

            Abilities = {
                Freezer2 = false,
                Freezer3 = true,
            }
        }
    }
}