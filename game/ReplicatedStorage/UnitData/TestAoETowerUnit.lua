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
				DMG = 1,
				CD = 1.5,
				RANGE = 15,
			},
		},
		
		[2] = {
			Attributes = {
				CD = 1.25,
			},
		},
		
		[3] = {
			Attributes = {
				CD = 1,
			},
		}
	}
}