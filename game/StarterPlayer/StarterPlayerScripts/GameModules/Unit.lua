local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local Promise = require(SharedModules:WaitForChild("Promise"))

local UnitAddedEvent = Instance.new("BindableEvent")
local UnitRemovingEvent = Instance.new("BindableEvent")

---

local IGNORED_ATTRIBUTES = {
	Id = true,
	Name = true,
	Type = true,
	Owner = true,
}

local units = {}

---

local Unit = {}

Unit.UnitAdded = UnitAddedEvent.Event
Unit.UnitRemoving = UnitRemovingEvent.Event

Unit.fromModel = function(model: Model)
	for _, unit in pairs(units) do
		if (unit.Model == model) then
			return unit
		end
	end
end

Unit.fromId = function(id: string)
	return units[id]
end

Unit.GetUnits = function(filterCallback: (any) -> boolean)
	local unitList = {}

	for _, unit in pairs(units) do
		if (filterCallback and filterCallback(unit)) then
			table.insert(unitList, unit)
		end
	end

	return unitList
end

local constructUnit = function(unitModel)
	local unitName = unitModel:GetAttribute("Name")
	
	local diedEvent = Instance.new("BindableEvent")
	local attributeChangedEvent = Instance.new("BindableEvent")
	
	local unit = setmetatable({
		Id = unitModel:GetAttribute("Id"),
		Name = unitName,
		Type = unitModel:GetAttribute("Type"),
		Owner = unitModel:GetAttribute("Owner"),
		Level = unitModel:GetAttribute("Level"),
		Model = unitModel,
		
		Died = diedEvent.Event,
		AttributeChanged = attributeChangedEvent.Event,
		
		__diedEvent = diedEvent,
		__attributeChangedEvent = attributeChangedEvent,
	}, {
		__index = Unit,

		__tostring = function(self)
			return self.Id
		end,

		__eq = function(unitA, unitB)
			return unitA.Id == unitB.Id
		end,
	})
	
	unitModel.AttributeChanged:Connect(function(attributeName)
		if (IGNORED_ATTRIBUTES[attributeName]) then return end
		
		if (attributeName == "HP") then
			local newHP = unitModel:GetAttribute(attributeName)
			
			if (newHP <= 0) then
				unit.__diedEvent:Fire()
			end
		end
		
		attributeChangedEvent:Fire(unitModel:GetAttribute(attributeName))
	end)
	
	units[unit.Id] = unit
	UnitAddedEvent:Fire(unit.Id)
end

local destroyUnit = function(unit)
	UnitRemovingEvent:Fire(unit.Id)
	
	unit.__diedEvent:Destroy()
	unit.__attributeChangedEvent:Destroy()
	
	-- defer so that subscriptions have a chance to obtain the Unit for cleanup
	Promise.defer(function(resolve)
		units[unit.Id] = nil
		resolve()
	end)
end

---

CollectionService:GetInstanceAddedSignal("Unit"):Connect(constructUnit)

CollectionService:GetInstanceRemovedSignal("Unit"):Connect(function(unitModel)
	local unit = Unit.fromModel(unitModel)
	if (not unit) then return end
	
	destroyUnit(unit)
end)

for _, unitModel in pairs(CollectionService:GetTagged("Unit")) do
	constructUnit(unitModel)
end

return Unit