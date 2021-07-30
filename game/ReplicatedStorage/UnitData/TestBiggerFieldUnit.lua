local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	Type = GameEnum.UnitType.FieldUnit,
	
	Progression = {
		[1] = {
			Attributes = {
				MaxHP = 1000,
				DEF = 30,
				DMG = 0,
				CD = 0,
				RANGE = 0,
				SPD = 2,

				PathType = GameEnum.PathType.Ground,
			},
		},
	}
}