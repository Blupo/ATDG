local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

local DMG_RATIO = 5/100
local BURST_RATIO = 10/100

return {
    EffectType = GameEnum.StatusEffectType.Periodic,
    Interval = 1,
    
    OnApplying = function(unit)
        unit:TakeDamage(unit:GetAttribute("HP") * DMG_RATIO)
        
        -- chance to apply to nearby units
    end,
    
    Interactions = {
        Frozen = function(StatusEffects, unit)
            StatusEffects.RemoveEffect(unit.Id, "Frozen")
            unit:TakeDamage(unit:GetAttribute("HP") * BURST_RATIO)

            return GameEnum.StatusEffectInteractionResult.DoNotApply
        end,
        
        Immune = function()
            return GameEnum.StatusEffectInteractionResult.DoNotApply
        end,
    }
}