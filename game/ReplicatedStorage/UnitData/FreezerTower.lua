local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	DisplayName = "Freezer Tower",
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
				DMG = 5,
				CD = 9.5,
				RANGE = 30,
			},

			Abilities = {
				Freezer = true,
			}
		},
		
		[2] = {
			Attributes = {
				DMG = 12,
				CD = 9,
			},
		},
		
		[3] = {
			Attributes = {
				DMG = 19,
				CD = 8.5,
			},

			Abilities = {
				Freezer = false,
				Freezer2 = true,
			}
		},

		[4] = {
			Attributes = {
				DMG = 26,
				CD = 8,
			},

			Abilities = {
				Freezer2 = false,
				Freezer3 = true,
			}
		}
	}
}