local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService(("ServerScriptService"))

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Unit = require(GameModules:FindFirstChild("Unit"))

local EffectData = ServerScriptService:FindFirstChild("EffectData")

local EffectAppliedEvent = Instance.new("BindableEvent")
local EffectRemovedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("StatusEffects")

---

local unitEffectPromises = {}

local scheduleCallback = function(andThenCallback, finallyCallback, interval)
    local delayPromise = Promise.delay(interval)
    
    delayPromise:andThen(andThenCallback):finally(finallyCallback)
    return delayPromise
end

---

local StatusEffects = {
    EffectApplied = EffectAppliedEvent.Event,
    EffectRemoved = EffectRemovedEvent.Event,
}

StatusEffects.UnitHasEffect = function(unitId: string, effectName: string): boolean
    local unitEffects = unitEffectPromises[unitId]
    if (not unitEffects) then return false end
    
    return unitEffects[effectName] and true or false
end

StatusEffects.GetUnitEffects = function(unitId: string): {string}
    local effectNames = {}

    local unitEffects = unitEffectPromises[unitId]
    if (not unitEffects) then return effectNames end
    
    for effectName in pairs(unitEffects) do
        table.insert(effectNames, effectName)
    end
    
    return effectNames
end

StatusEffects.ApplyEffect = function(unitId: string, effectName: string, duration: number, effectConfig: {[string]: any}?)
    local unit = Unit.fromId(unitId)
    if (not unit) then return end

    local unitEffects = unitEffectPromises[unitId]
    
    if (not unitEffects) then
        unitEffectPromises[unitId] = {}
        unitEffects = unitEffectPromises[unitId]
    end
    
    if (unitEffects[effectName]) then return end
    
    local effectDataScript = EffectData:FindFirstChild(effectName)
    if (not effectDataScript) then return end
    
    local effectData = require(effectDataScript)
    local effectType = effectData.EffectType
    local interactions = effectData.Interactions
    
    -- interactions
    for interactingEffectName, interaction in pairs(interactions) do
        if (StatusEffects.UnitHasEffect(unitId, interactingEffectName)) then
            local result = interaction(StatusEffects, unit)
            
            if (result == GameEnum.StatusEffectInteractionResult.DoNotApply) then
                return
            end
        end
    end
    
    -- initial apply
    duration = (duration >= (1/60)) and duration or (1/60)
    effectConfig = effectConfig or {}
    effectData.OnApplying(unit, effectConfig)
    
    -- schedule next action
    if (effectType == GameEnum.StatusEffectType.Lingering) then        
        unitEffects[effectName] = scheduleCallback(nil, function()
            local onRemoving = effectData.OnRemoving

            if (onRemoving) then
                onRemoving(unit)
            end
            
            unitEffects[effectName] = nil
            EffectRemovedEvent:Fire(unitId, effectName)
        end, duration)
    elseif (effectType == GameEnum.StatusEffectType.Periodic) then
        local totalElapsed = 0
        local periodicCallback
        
        periodicCallback = function(elapsed)
            totalElapsed = totalElapsed + elapsed
            
            if (totalElapsed <= duration) then
                effectData.OnApplying(unit, effectConfig)
                unitEffects[effectName] = scheduleCallback(periodicCallback, nil, effectData.Interval)
            else
                unitEffects[effectName] = nil
            end
        end
        
        unitEffects[effectName] = scheduleCallback(periodicCallback, nil, effectData.Interval)
    end
    
    EffectAppliedEvent:Fire(unitId, effectName)
end

StatusEffects.RemoveEffect = function(unitId: string, effectName: string)
    local unitEffects = unitEffectPromises[unitId]
    if (not unitEffects) then return end
    
    local effectPromise = unitEffects[effectName]
    if (not effectPromise) then return end
    
    effectPromise:cancel()
    unitEffects[effectName] = nil
    
    EffectRemovedEvent:Fire(unitId, effectName)
end

StatusEffects.ClearEffects = function(unitId: string)
    local unitEffects = unitEffectPromises[unitId]
    if (not unitEffects) then return end
    
    for effectName, effectPromise in pairs(unitEffects) do
        effectPromise:cancel()
        unitEffects[effectName] = nil
        
        EffectRemovedEvent:Fire(unitId, effectName)
    end
end

---

Unit.UnitAdded:Connect(function(unitId: string)
    unitEffectPromises[unitId] = {}
end)

Unit.UnitRemoving:Connect(function(unitId: string)
    local unitEffects = unitEffectPromises[unitId]
    if (not unitEffects) then return end
    
    for effectName, effectPromise in pairs(unitEffects) do
        effectPromise:cancel()
        unitEffects[effectName] = nil
    end
    
    unitEffectPromises[unitId] = nil
end)

System.addEvent("EffectApplied", StatusEffects.EffectApplied)
System.addEvent("EffectRemoved", StatusEffects.EffectRemoved)

System.addFunction("UnitHasEffect", t.wrap(function(_: Player, unitId: string, effectName: string): boolean
    return StatusEffects.UnitHasEffect(unitId, effectName)
end, t.tuple(t.instanceOf("Player"), t.string, t.string)), true)

System.addFunction("GetUnitEffects", t.wrap(function(_: Player, unitId: string): {string}
    return StatusEffects.GetUnitEffects(unitId)
end, t.tuple(t.instanceOf("Player"), t.string)), true)

return StatusEffects