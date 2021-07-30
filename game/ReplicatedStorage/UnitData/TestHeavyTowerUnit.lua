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
				CD = 3,
				RANGE = 50,
				SPD = 0,

				PathType = GameEnum.PathType.Ground,
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