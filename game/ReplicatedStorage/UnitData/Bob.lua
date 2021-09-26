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

        PathType = GameEnum.PathType.Ground,
    },
    
    Progression = {
        [1] = {
            Attributes = {
                DMG = 0.75,
                CD = 0.5,
                RANGE = 10,
            },
        },
        
        [2] = {
            Attributes = {
                DMG = 0.85,
                CD = 0.4,
            },
        },
        
        [3] = {
            Attributes = {
                DMG = 0.95
            },
        },

        [4] = {
            Attributes = {
                DMG = 1.05,
                CD = 0.3,
            }
        }
    }
}