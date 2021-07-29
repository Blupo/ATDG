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
				DMG = 100,
				CD = 4,
				RANGE = 12.5,
				SPD = 0,

				UnitTargeting = GameEnum.UnitTargeting.First,
				PathType = GameEnum.PathType.Air,
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