local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	Type = GameEnum.UnitType.FieldUnit,

	ImmutableAttributes = {
		DMG = 0,
		CD = 0,
		RANGE = 0,

		PathType = GameEnum.PathType.Air,
	},
	
	Progression = {
		[1] = {
			Attributes = {
				MaxHP = 32,
				DEF = 10,
				SPD = 16,
			},
		},
	}
}