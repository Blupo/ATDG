local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	Type = GameEnum.UnitType.TowerUnit,
	
	Progression = {
		[1] = {
			Attributes = {
				MaxHP = 1,
				DEF = 0,
				DMG = 1,
				CD = 0.1,
				RANGE = 10,
				SPD = 0,

				UnitTargeting = GameEnum.UnitTargeting.First,
				PathType = GameEnum.PathType.GroundAndAir,
			},
		},
		
		[2] = {
			Attributes = {
				CD = 0.25,
			},
			
			Abilities = {
				LuckyShot = true
			}
		},
		
		[3] = {
			Attributes = {
				DMG = 2
			},
		}
	}
}