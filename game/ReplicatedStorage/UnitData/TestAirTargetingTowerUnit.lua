local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	Type = GameEnum.UnitType.TowerUnit,
	SurfaceType = GameEnum.SurfaceType.ElevatedTerrain,

	ImmutableAttributes = {
		MaxHP = 1,
		DEF = 0,
		SPD = 0,

		PathType = GameEnum.PathType.Air,
	},
	
	Progression = {
		[1] = {
			Attributes = {
				DMG = 100,
				CD = 4,
				RANGE = 12.5,
			},
		},
		
		[2] = {
			Attributes = {
				CD = 3.9,
			},
		},
		
		[3] = {
			Attributes = {
				CD = 3.7,
			},
		}
	}
}