-- Chance to do another shot

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))

---

local CHANCE = 20/100

return {
	UnitType = GameEnums.UnitType.TowerUnit,
	AbilityType = GameEnums.AbilityType.OnHit,
	
	Callback = function()
		local roll = math.random()
		if (roll > CHANCE) then return end
	end,
}