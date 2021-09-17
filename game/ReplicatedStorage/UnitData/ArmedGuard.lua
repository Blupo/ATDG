local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	DisplayName = "Armed Guard",
	Type = GameEnum.UnitType.TowerUnit,
	SurfaceType = GameEnum.SurfaceType.Terrain,

	ImmutableAttributes = {
		MaxHP = 1,
		DEF = 0,
		SPD = 0,

		PathType = GameEnum.PathType.GroundAndAir,
	},
	
	Progression = {
		[1] = {
			Attributes = {
				DMG = 1,
				CD = 0.35,
				RANGE = 25,
			},
		},
		
		[2] = {
			Attributes = {
				DMG = 1.05,
				CD = 0.3,
			},
		},
		
		[3] = {
			Attributes = {
				DMG = 1.15,
				CD = 0.2,
				RANGE = 30,
			},
		},

		[4] = {
			Attributes = {
				DMG = 1.3,
				CD = 0.15,
			}
		}
	}
}