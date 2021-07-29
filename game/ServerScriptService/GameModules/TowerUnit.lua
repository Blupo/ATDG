local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Path = require(GameModules:FindFirstChild("Path"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local HitEvent = Instance.new("BindableEvent")

---

local getModelBottom = function(model): Vector3
	local modelCFrame, modelSize = model:GetBoundingBox()
	
	return modelCFrame.Position - Vector3.new(0, modelSize.Y / 2, 0)
end

local SORT_CALLBACKS = {
	[GameEnum.UnitTargeting.Closest] = function(unit)
		local thisUnitModel: Model = unit.Model
		local thisModelBottom: Vector3 = getModelBottom(thisUnitModel)
		
		return function(a, b)
			local unitModelA: Model = a.Model
			local modelABottom: Vector3 = getModelBottom(unitModelA)
			
			local unitModelB: Model = b.Model
			local modelBBottom: Vector3 = getModelBottom(unitModelB)
			
			return (
				(thisModelBottom - modelABottom).Magnitude <
				(thisModelBottom - modelBBottom).Magnitude
			)
		end
	end,
	
	[GameEnum.UnitTargeting.Farthest] = function(unit)
		local thisUnitModel: Model = unit.Model
		local thisModelBottom: Vector3 = getModelBottom(thisUnitModel)

		return function(a, b)
			local unitModelA: Model = a.Model
			local modelABottom: Vector3 = getModelBottom(unitModelA)

			local unitModelB: Model = b.Model
			local modelBBottom: Vector3 = getModelBottom(unitModelB)

			return (
				(thisModelBottom - modelABottom).Magnitude >
				(thisModelBottom - modelBBottom).Magnitude
			)
		end
	end,
	
	[GameEnum.UnitTargeting.First] = function()
		return function(a, b)
			local aPursuitInfo, bPursuitInfo = Path.GetPursuitInfo(a), Path.GetPursuitInfo(b)

			if (aPursuitInfo and bPursuitInfo) then
				return aPursuitInfo.Progress > bPursuitInfo.Progress
			elseif (aPursuitInfo and (not bPursuitInfo)) then
				return true
			elseif ((not aPursuitInfo) and bPursuitInfo) then
				return false
			else
				return false
			end
		end
	end,

	[GameEnum.UnitTargeting.Last] = function()
		return function(a, b)
			local aPursuitInfo, bPursuitInfo = Path.GetPursuitInfo(a), Path.GetPursuitInfo(b)

			if (aPursuitInfo and bPursuitInfo) then
				return aPursuitInfo.Progress < bPursuitInfo.Progress
			elseif (aPursuitInfo and (not bPursuitInfo)) then
				return true
			elseif ((not aPursuitInfo) and bPursuitInfo) then
				return false
			else
				return false
			end
		end
	end,
	
	[GameEnum.UnitTargeting.Strongest] = function()
		return function(a, b)
			return a:GetAttribute("HP") > b:GetAttribute("HP")
		end
	end,
	
	[GameEnum.UnitTargeting.Fastest] = function()
		return function(a, b)
			return a:GetAttribute("SPD") > b:GetAttribute("SPD")
		end
	end,
}

local unitTimers = {}
local unitAttributeChangedConnections = {}

local scheduleCallback = function(andThenCallback, finallyCallback, interval)
	local delayPromise = Promise.delay(interval)

	delayPromise:andThen(andThenCallback):finally(finallyCallback)
	return delayPromise
end

local unitDamageCallback = function(thisUnit)
	local range: number = thisUnit:GetAttribute("RANGE")
	local thisModelBottom: Vector3 = getModelBottom(thisUnit.Model)
	local thisUnitPathType = thisUnit:GetAttribute("PathType")
	local unitTargeting = thisUnit:GetAttribute("UnitTargeting")

	local unitsInRange = Unit.GetUnits(function(unit)
		if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return false end
		if (unit:GetAttribute("HP") <= 0) then return false end

		if (thisUnitPathType ~= GameEnum.PathType.GroundAndAir) then
			local unitPathType = unit:GetAttribute("PathType")

			if (
				((thisUnitPathType == GameEnum.PathType.Ground) and (unitPathType ~= GameEnum.PathType.Ground)) or
				((thisUnitPathType == GameEnum.PathType.Air) and (unitPathType ~= GameEnum.PathType.Air))
			) then
				return false
			end
		end
		
		local unitModel: Model = unit.Model
		local unitModelBottom: Vector3 = getModelBottom(unitModel)
		
		return ((unitModelBottom - thisModelBottom).Magnitude <= range)
	end)
	
	if (#unitsInRange < 1) then return end

	if (unitTargeting == GameEnum.UnitTargeting.AreaOfEffect) then
		for i = 1, #unitsInRange do
			local targetUnit = unitsInRange[i]

			if (targetUnit:GetAttribute("HP") > 0) then
				targetUnit:TakeDamage(thisUnit:GetAttribute("DMG"))
				HitEvent:Fire(thisUnit.Id, targetUnit.Id)
			end
		end
	else
		local targetUnit
		
		if (unitTargeting == GameEnum.UnitTargeting.Random) then
			targetUnit = unitsInRange[math.random(1, #unitsInRange)]
		else
			table.sort(unitsInRange, SORT_CALLBACKS[unitTargeting](thisUnit))
			targetUnit = unitsInRange[1]				
		end
		
		-- make sure that the target wasn't destroyed or died in the time it took to calculate all that
		if (not Unit.fromId(targetUnit.Id)) then return end
		if (targetUnit:GetAttribute("HP") <= 0) then return end
		
		targetUnit:TakeDamage(thisUnit:GetAttribute("DMG"))
		HitEvent:Fire(thisUnit.Id, targetUnit.Id)
	end
end

local initUnit = function(unit)
	if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return end

	local unitId = unit.Id
	local lastCheckpoint = os.clock()
	local finallyCallback
	
	finallyCallback = function()
		-- if the timer was removed then don't do anything
		if (not unitTimers[unitId]) then return end
		
		unitDamageCallback(unit)
		lastCheckpoint = os.clock()
		unitTimers[unitId] = scheduleCallback(nil, finallyCallback, unit:GetAttribute("CD"))
	end
	
	unitAttributeChangedConnections[unitId] = unit.AttributeChanged:Connect(function(attributeName: string, newValue: any)
		if (attributeName ~= "CD") then return end
		
		if ((os.clock() - lastCheckpoint) >= newValue) then
			local unitTimer = unitTimers[unitId]
			
			if (unitTimer) then
				unitTimer:cancel()
			end
		end
	end)
	
	unitTimers[unitId] = scheduleCallback(nil, finallyCallback, unit:GetAttribute("CD"))
end

---

local TowerUnit = {}

TowerUnit.Hit = HitEvent.Event

---

Unit.UnitAdded:Connect(function(unitId)
	local unit = Unit.fromId(unitId)
	if (not unit) then return end
	
	initUnit(unit)
end)

Unit.UnitRemoving:Connect(function(unitId)
	if (Unit.fromId(unitId).Type ~= GameEnum.UnitType.TowerUnit) then return end
	
	local unitTimer = unitTimers[unitId]
	local unitAttributeChangedConnection = unitAttributeChangedConnections[unitId]
	
	if (unitTimer) then
		unitTimers[unitId] = nil
		unitTimer:cancel()
	end
	
	if (unitAttributeChangedConnection) then
		unitAttributeChangedConnections[unitId] = nil
		unitAttributeChangedConnection:Disconnect()
	end
end)

for _, unit in pairs(Unit.GetUnits()) do
	initUnit(unit)
end

return TowerUnit