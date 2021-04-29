local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))

---

local DMG_RATIO = 5/100
local BURST_RATIO = 10/100

return {
	EffectType = GameEnums.StatusEffectType.Periodic,
	Interval = 1,
	
	OnApplying = function(unit)
		unit:TakeDamage(unit:GetAttribute("HP") * DMG_RATIO)
		
		-- chance to apply to nearby units
	end,
	
	Interactions = {
		Frozen = function(StatusEffects, unit)
			StatusEffects.RemoveEffect(unit, "Frozen")
			unit:TakeDamage(unit:GetAttribute("HP") * BURST_RATIO)

			return GameEnums.StatusEffectInteractionResult.DoNotApply
		end,
		
		Immune = function()
			return GameEnums.StatusEffectInteractionResult.DoNotApply
		end,
	}
}