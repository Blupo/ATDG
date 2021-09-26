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

        UnitTargeting = GameEnum.UnitTargeting.AreaOfEffect,
        PathType = GameEnum.PathType.GroundAndAir,
    },
    
    Progression = {
        [1] = {
            Attributes = {
                DMG = math.huge,
                CD = 1/60,
                RANGE = math.huge,
            },
        },
    }
}