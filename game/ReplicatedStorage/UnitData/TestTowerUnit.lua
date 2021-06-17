local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))

---

return {
	Type = GameEnums.UnitType.TowerUnit,
	
	Progression = {
		[1] = {
			Attributes = {
				MaxHP = 1,
				DEF = 0,
				DMG = 1,
				CD = 0.1,
				RANGE = 10,
				SPD = 0,

				UnitTargeting = GameEnums.UnitTargeting.First,
				PathType = GameEnums.PathType.GroundAndAir,
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