-- Chance to do another shot

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

local CHANCE = 20/100

return {
	UnitType = GameEnum.UnitType.TowerUnit,
	AbilityType = GameEnum.AbilityType.OnHit,
	
	Callback = function()
		local roll = math.random()
		if (roll > CHANCE) then return end
	end,
}