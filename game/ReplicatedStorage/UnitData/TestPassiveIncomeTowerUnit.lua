local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	Type = GameEnum.UnitType.TowerUnit,
	SurfaceType = GameEnum.SurfaceType.Terrain,

	ImmutableAttributes = {
		MaxHP = 1,
		DEF = 0,
		DMG = 0,
		CD = math.huge,
		RANGE = 0,
		SPD = 0,
		
		UnitTargeting = GameEnum.UnitTargeting.None,
		PathType = GameEnum.PathType.GroundAndAir,
	},
	
	Progression = {
		[1] = {
			Abilities = {
				PassiveIncome = true,
			}
		},
	}
}