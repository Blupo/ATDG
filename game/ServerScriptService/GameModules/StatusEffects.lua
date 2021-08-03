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
local EffectAppliedRemoteEvent = System.addEvent("EffectApplied")
local EffectRemovedRemoteEvent = System.addEvent("EffectRemoved")

---

local unitEffectPromises = {}

local scheduleCallback = function(andThenCallback, finallyCallback, interval)
	local delayPromise = Promise.delay(interval)
	
	delayPromise:andThen(andThenCallback):finally(finallyCallback)
	return delayPromise
end

---

local StatusEffects = {}

StatusEffects.EffectApplied = EffectAppliedEvent.Event
StatusEffects.EffectRemoved = EffectRemovedEvent.Event

StatusEffects.UnitHasEffect = function(unit, effectName: string): boolean
	local unitEffects = unitEffectPromises[unit.Id]
	if (not unitEffects) then return false end
	
	return unitEffects[effectName] and true or false
end

StatusEffects.GetUnitEffects = function(unit): {string}
	local effectNames = {}
	
	local unitEffects = unitEffectPromises[unit.Id]
	if (not unitEffects) then return effectNames end
	
	for effectName in pairs(unitEffects) do
		table.insert(effectNames, effectName)
	end
	
	return effectNames
end

StatusEffects.ApplyEffect = function(unit, effectName: string, duration: number, effectConfig: {[string]: any}?)
	local unitEffects = unitEffectPromises[unit.Id]
	
	if (not unitEffects) then
		unitEffectPromises[unit.Id] = {}
		unitEffects = unitEffectPromises[unit.Id]
	end
	
	if (unitEffects[effectName]) then return end
	
	local effectDataScript = EffectData:FindFirstChild(effectName)
	if (not effectDataScript) then return end
	
	local effectData = require(effectDataScript)
	local effectType = effectData.EffectType
	local interactions = effectData.Interactions
	
	-- interactions
	for interactingEffectName, interaction in pairs(interactions) do
		if (StatusEffects.UnitHasEffect(unit, interactingEffectName)) then
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
	
	EffectAppliedEvent:Fire(unit.Id, effectName)
end

StatusEffects.RemoveEffect = function(unit, effectName: string)
	local unitEffects = unitEffectPromises[unit.Id]
	if (not unitEffects) then return end
	
	local effectPromise = unitEffects[effectName]
	if (not effectPromise) then return end
	
	effectPromise:cancel()
	unitEffects[effectName] = nil
	
	EffectRemovedEvent:Fire(unit, effectName)
end

StatusEffects.ClearEffects = function(unit)
	local unitEffects = unitEffectPromises[unit.Id]
	if (not unitEffects) then return end
	
	for effectName, effectPromise in pairs(unitEffects) do
		effectPromise:cancel()
		unitEffects[effectName] = nil
		
		EffectRemovedEvent:Fire(unit, effectName)
	end
end

---

Unit.UnitRemoving:Connect(function(unitId)
	if (not unitEffectPromises[unitId]) then return end
	
	StatusEffects.ClearEffects(Unit.fromId(unitId))
	unitEffectPromises[unitId] = nil
end)

EffectAppliedEvent.Event:Connect(function(unit, effectName: string)
	EffectAppliedRemoteEvent:FireAllClients(unit.Id, effectName)
end)

EffectRemovedEvent.Event:Connect(function(unit, effectName: string)
	EffectRemovedRemoteEvent:FireAllClients(unit.Id, effectName)
end)

System.addFunction("UnitHasEffect", t.wrap(function(_: Player, unitId: string, effectName: string): boolean
	local unit = Unit.fromId(unitId)
	if (not unit) then return false end
	
	return StatusEffects.UnitHasEffect(unit, effectName)
end, t.tuple(t.instanceOf("Player"), t.string, t.string)), true)

System.addFunction("GetUnitEffects", t.wrap(function(_: Player, unitId: string): {string}
	local unit = Unit.fromId(unitId)
	if (not unit) then return {} end
	
	return StatusEffects.GetUnitEffects(unit)
end, t.tuple(t.instanceOf("Player"), t.string)), true)

return StatusEffects