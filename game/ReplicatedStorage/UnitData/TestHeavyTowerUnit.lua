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
				DMG = 100,
				CD = 3,
				RANGE = 50,
				SPD = 0,

				UnitTargeting = GameEnums.UnitTargeting.First,
				PathType = GameEnums.PathType.Ground,
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