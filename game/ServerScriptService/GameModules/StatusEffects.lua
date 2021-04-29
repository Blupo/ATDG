local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService(("ServerScriptService"))

---

local EffectData = ServerScriptService:FindFirstChild("EffectData")
local StatusEffectsCommunicators = ReplicatedStorage:FindFirstChild("Communicators"):FindFirstChild("StatusEffects")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local t = require(SharedModules:FindFirstChild("t"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local RemoteUtils = require(GameModules:FindFirstChild("RemoteUtils"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local EffectAppliedEvent = Instance.new("BindableEvent")
local EffectRemovedEvent = Instance.new("BindableEvent")

local EffectAppliedRemoteEvent = Instance.new("RemoteEvent")
local EffectRemovedRemoteEvent = Instance.new("RemoteEvent")
local UnitHasEffectRemoteFunction = Instance.new("RemoteFunction")
local GetUnitEffectsRemoteFunction = Instance.new("RemoteFunction")

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
			
			if (result == GameEnums.StatusEffectInteractionResult.DoNotApply) then
				return
			end
		end
	end
	
	-- initial apply
	duration = (duration >= (1/60)) and duration or (1/60)
	effectConfig = effectConfig or {}
	effectData.OnApplying(unit, effectConfig)
	
	-- schedule next action
	if (effectType == GameEnums.StatusEffectType.Lingering) then		
		unitEffects[effectName] = scheduleCallback(nil, function()
			local onRemoving = effectData.OnRemoving

			if (onRemoving) then
				onRemoving(unit)
			end
			
			unitEffects[effectName] = nil
		end, duration)
	elseif (effectType == GameEnums.StatusEffectType.Periodic) then
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
local UnitHasEffectRemoteFunctionParameters = t.tuple(t.string, t.string)
local GetUnitEffectsRemoteFunctionParameters = t.string

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

UnitHasEffectRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(function(_: Player, unitId: string, effectName: string): boolean
	if (not UnitHasEffectRemoteFunctionParameters(unitId, effectName)) then return false end
	
	local unit = Unit.fromId(unitId)
	if (not unit) then return false end
	
	return StatusEffects.UnitHasEffect(unit, effectName)
end)

GetUnitEffectsRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(function(_: Player, unitId: string): {string}
	if (not GetUnitEffectsRemoteFunctionParameters(unitId)) then return {} end
	
	local unit = Unit.fromId(unitId)
	if (not unit) then return {} end
	
	return StatusEffects.GetUnitEffects(unit)
end)

EffectAppliedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)
EffectRemovedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)

EffectAppliedRemoteEvent.Name = "EffectApplied"
EffectRemovedRemoteEvent.Name = "EffectRemoved"
UnitHasEffectRemoteFunction.Name = "UnitHasEffect"
GetUnitEffectsRemoteFunction.Name = "GetUnitEffects"

EffectAppliedRemoteEvent.Parent = StatusEffectsCommunicators
EffectRemovedRemoteEvent.Parent = StatusEffectsCommunicators
UnitHasEffectRemoteFunction.Parent = StatusEffectsCommunicators
GetUnitEffectsRemoteFunction.Parent = StatusEffectsCommunicators

return StatusEffects