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
				DMG = 0.1,
				CD = 0.1,
				RANGE = 10,
			},
		},
		
		[2] = {
			Attributes = {
				CD = 0.05,
			},
		},
		
		[3] = {
			Attributes = {
				DMG = 2
			},
		}
	}
}