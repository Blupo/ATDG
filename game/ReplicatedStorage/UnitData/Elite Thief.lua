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
				MaxHP = 40,
				DEF = 0,
				DMG = 0,
				CD = 0,
				RANGE = 0,
				SPD = 16,

				PathType = GameEnum.PathType.Ground,
			},
		},
	}
}