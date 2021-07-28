local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

local BURST_RATIO = 10/100

return {
	EffectType = GameEnum.StatusEffectType.Lingering,
	
	OnApplying = function(unit)
		unit:ApplyAttributeModifier("Frozen", "SPD", GameEnum.AttributeModifierType.Set, function()
			return 0
		end)
	end,
	
	OnRemoving = function(unit)
		unit:RemoveAttributeModifier("Frozen", "SPD", GameEnum.AttributeModifierType.Set)
	end,
	
	Interactions = {
		Burning = function(StatusEffects, unit)
			StatusEffects.RemoveEffect(unit, "Burning")
			unit:TakeDamage(unit:GetAttribute("HP") * BURST_RATIO)
			
			return GameEnum.StatusEffectInteractionResult.DoNotApply
		end,
	}
}