local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))

---

local BURST_RATIO = 10/100

return {
	EffectType = GameEnums.StatusEffectType.Lingering,
	
	OnApplying = function(unit)
		unit:ApplyAttributeModifier("Frozen", "SPD", GameEnums.AttributeModifierType.Set, function()
			return 0
		end)
	end,
	
	OnRemoving = function(unit)
		unit:RemoveAttributeModifier("Frozen", "SPD", GameEnums.AttributeModifierType.Set)
	end,
	
	Interactions = {
		Burning = function(StatusEffects, unit)
			StatusEffects.RemoveEffect(unit, "Burning")
			unit:TakeDamage(unit:GetAttribute("HP") * BURST_RATIO)
			
			return GameEnums.StatusEffectInteractionResult.DoNotApply
		end,
	}
}