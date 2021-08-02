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
		PathType = GameEnum.PathType.Ground,
	},
	
	Progression = {
		[1] = {
			Attributes = {
				DMG = 2,
				CD = 5,
				RANGE = 10,
			},

			Abilities = {
				Freezer = true,
			}
		},
	}
}