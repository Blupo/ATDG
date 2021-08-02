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
				DMG = 100,
				CD = 3,
				RANGE = 50,
			},
		},
		
		[2] = {
			Attributes = {
				CD = 2.75,
			},
		},
		
		[3] = {
			Attributes = {
				CD = 2.5,
			},
		}
	}
}