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
				CD = 1.5,
				RANGE = 15,
				SPD = 0,

				UnitTargeting = GameEnum.UnitTargeting.AreaOfEffect,
				PathType = GameEnum.PathType.Ground,
			},
		},
		
		[2] = {
			Attributes = {
				CD = 1.25,
			},
		},
		
		[3] = {
			Attributes = {
				CD = 1,
			},
		}
	}
}