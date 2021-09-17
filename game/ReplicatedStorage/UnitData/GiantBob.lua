local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	DisplayName = "Giant Bob",
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
				DMG = 10,
				CD = 10,
				RANGE = 30,
			},
		},
		
		[2] = {
			Attributes = {
				DMG = 25,
				CD = 9.5,
				RANGE = 35,
			},
		},
		
		[3] = {
			Attributes = {
				DMG = 50,
				CD = 9.25,
				RANGE = 40,
			},
		},

		[4] = {
			Attributes = {
				DMG = 100,
				CD = 9,
				RANGE = 50,
			},
		}
	}
}