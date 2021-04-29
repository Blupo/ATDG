local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))

---

return {
	Type = GameEnums.UnitType.FieldUnit,
	
	Progression = {
		[1] = {
			Attributes = {
				MaxHP = 1000,
				DEF = 30,
				DMG = 0,
				CD = 0,
				RANGE = 0,
				SPD = 2,

				UnitTargeting = GameEnums.UnitTargeting.None,
				PathType = GameEnums.PathType.Ground,
			},
		},
	}
}