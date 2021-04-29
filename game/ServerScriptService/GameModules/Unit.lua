local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local UnitCommunicators = ReplicatedStorage:FindFirstChild("Communicators"):FindFirstChild("Unit")
local UnitModels = ReplicatedStorage:FindFirstChild("UnitModels")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local t = require(SharedModules:FindFirstChild("t"))

local AbilityData = ServerScriptService:FindFirstChild("AbilityData")
local UnitData = ReplicatedStorage:FindFirstChild("UnitData")

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local RemoteUtils = require(GameModules:FindFirstChild("RemoteUtils"))

local UnitAddedEvent = Instance.new("BindableEvent")
local UnitRemovingEvent = Instance.new("BindableEvent")

local SetAttributeRemoteFunction = Instance.new("RemoteFunction")

---

local units = {}
local unitProgressionData = {}
local unitDataCache = {}
local abilitiesCache = {}

local attributeChangedCallbacks = {
	HP = function(unit, newHP)
		if (unit.Type ~= GameEnums.UnitType.FieldUnit) then return end
		
		if (newHP <= 0) then
			unit.__diedEvent:Fire()
			unit:Destroy()
		end
	end,
}

local dictionaryCount = function(dictionary)
	local count = 0
	
	for _ in pairs(dictionary) do
		count = count + 1
	end
	
	return count
end

local copy
copy = function(tab)
	local tCopy = {}

	for k, v in pairs(tab) do
		tCopy[(type(k) == "table") and copy(k) or k] = (type(v) == "table") and copy(v) or v
	end

	return tCopy
end

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

Unit.new = function(unitName: string, owner: number?)
	owner = owner or 0
	
	local unitData = unitDataCache[unitName]
	if (not unitData) then return end
	
	local unitModel = UnitModels:FindFirstChild(unitName)
	if (not unitModel) then return end
	
	local newUnitLevel = 1
	
	if (unitProgressionData[owner]) then
		newUnitLevel = unitProgressionData[owner][unitName] or 1
	end
	
	local newBaseAttributes = copy(unitData.Progression[newUnitLevel].Attributes)
	newBaseAttributes.HP = newBaseAttributes.MaxHP
	
	local newBaseModel = unitModel:Clone()
	local diedEvent = Instance.new("BindableEvent")
	local attributeChangedEvent = Instance.new("BindableEvent")
	
	local self = setmetatable({
		Id = HttpService:GenerateGUID(false),
		Name = unitName,
		Type = unitData.Type,
		Owner = owner,
		Level = newUnitLevel,
		Model = newBaseModel,
		
		Died = diedEvent.Event,
		AttributeChanged = attributeChangedEvent.Event,
		
		__diedEvent = diedEvent,
		__attributeChangedEvent = attributeChangedEvent,
		__baseAttributes = newBaseAttributes,
		__attributeModifiers = {},
		__abilities = {},
	}, {
		__index = Unit,
		
		__tostring = function(unit)
			return unit.Id
		end,
		
		__eq = function(unitA, unitB)
			return unitA.Id == unitB.Id
		end,
	})
	
	newBaseModel.Name = self.Id
	newBaseModel:SetAttribute("Id", self.Id)
	newBaseModel:SetAttribute("Name", self.Name)
	newBaseModel:SetAttribute("Type", self.Type)
	newBaseModel:SetAttribute("Owner", self.Owner)
	newBaseModel:SetAttribute("Level", self.Level)
	
	for key, value in pairs(self.__baseAttributes) do
		newBaseModel:SetAttribute(key, value)
	end
	
	self.AttributeChanged:Connect(function(attributeName: string, newValue: any)
		newBaseModel:SetAttribute(attributeName, newValue)
		
		local attributeChangedCallback = attributeChangedCallbacks[attributeName]
		if (not attributeChangedCallback) then return end
		
		attributeChangedCallback(self, newValue)
	end)
	
	-- temp?
	game:GetService("CollectionService"):AddTag(newBaseModel, "Unit")
	--
	
	units[self.Id] = self
	UnitAddedEvent:Fire(self.Id)
	return self
end

Unit.Destroy = function(self)
	UnitRemovingEvent:Fire(self.Id)
	
	self.__diedEvent:Destroy()
	self.__attributeChangedEvent:Destroy()
	self.Model:Destroy()
	
	-- defer so that subscriptions have a chance to obtain the Unit for cleanup
	Promise.defer(function(resolve)
		units[self.Id] = nil
		resolve()
	end)
end

Unit.GetAttribute = function(self, attributeName: string)
	local attributeValue = self.__baseAttributes[attributeName]
	local attributeModifiers = self.__attributeModifiers[attributeName]
	
	if (attributeModifiers) then
		local multiplicativeModifiers = attributeModifiers[GameEnums.AttributeModifierType.Multiplicative]
		local additiveModifiers = attributeModifiers[GameEnums.AttributeModifierType.Additive]
		local setModifiers = attributeModifiers[GameEnums.AttributeModifierType.Set]
		
		if (dictionaryCount(setModifiers) > 0) then		
			local _, modification = next(setModifiers)
			
			attributeValue = modification()
		else
			if (type(attributeValue) == "number") then
				for _, modification in pairs(multiplicativeModifiers) do
					attributeValue = modification(attributeValue)
				end
				
				for _, modification in pairs(additiveModifiers) do
					attributeValue = attributeValue + modification()
				end
			end
		end
	end
	
	if ((attributeName == "DEF") or (attributeName == "DMG")) then
		-- minimum 0
		attributeValue = (attributeValue >= 0) and attributeValue or 0
	elseif (attributeName == "CD") then
		attributeValue = (attributeValue >= (1/60)) and attributeValue or (1/60)
	end
	
	return attributeValue
end

Unit.SetAttribute = function(self, attributeName: string, newValue: any)
	local oldValue = self:GetAttribute(attributeName)
	if (type(oldValue) ~= type(newValue)) then return end
	
	-- HP has special handling
	if (attributeName == "HP") then
		-- minimum 0
		-- integer
		newValue = (newValue >= 0) and newValue or 0
		newValue = math.floor(newValue + 0.5)
	end
	
	if (oldValue == newValue) then return end
	self.__baseAttributes[attributeName] = newValue
	self.__attributeChangedEvent:Fire(attributeName, self:GetAttribute(attributeName))
end

Unit.TakeDamage = function(self, damage: number, ignoreDEF: boolean?)
	if (damage <= 0) then return end
	
	local hp = self:GetAttribute("HP")
	local def = ignoreDEF and 0 or self:GetAttribute("DEF")
	local effectiveDMG = (damage * damage) / (damage + def)
	
	self:SetAttribute("HP", hp - effectiveDMG)
end

Unit.HasAbility = function(self, abilityName: string): boolean
	return self.__abilities[abilityName] and true or false
end

Unit.GetAbilities = function(self, abilityType: string?): {string}
	local abilities = {}
	
	for ability in pairs(self.__abilities) do
		if (abilitiesCache[ability].Type == abilityType) then
			table.insert(abilities, ability)
		end
	end
	
	return abilities
end

Unit.GiveAbility = function(self, abilityName: string)
	if (not abilitiesCache[abilityName]) then return end
	if (self:HasAbility(abilityName)) then return end
	
	self.__abilities[abilityName] = true
end

Unit.RemoveAbility = function(self, abilityName: string)
	if (not self:HasAbility(abilityName)) then return end

	self.__abilities[abilityName] = nil
end

Unit.ApplyAttributeModifier = function(self, id: string, attributeName: string, modifierType: string, modifier: (any) -> any)
	if ((attributeName == "HP") or (attributeName == "MaxHP")) then return end
	
	local attributeModifiers = self.__attributeModifiers[attributeName]
	
	if (not attributeModifiers) then
		self.__attributeModifiers[attributeName] = {
			[GameEnums.AttributeModifierType.Multiplicative] = {},
			[GameEnums.AttributeModifierType.Additive] = {},
			[GameEnums.AttributeModifierType.Set] = {},
		}
		
		attributeModifiers = self.__attributeModifiers[attributeName]
	end
	
	local specificAttributeModifiers = attributeModifiers[modifierType]
	if (not specificAttributeModifiers) then return end
	if (specificAttributeModifiers[id]) then return end
	
	local oldAttributeValue = self:GetAttribute(attributeName)
	
	if ((type(oldAttributeValue) ~= "number") and (modifierType ~= GameEnums.AttributeModifierType.Set)) then
		return
	end
	
	specificAttributeModifiers[id] = modifier
	
	if ((modifierType == GameEnums.AttributeModifierType.Set) and (dictionaryCount(specificAttributeModifiers) > 1)) then
		warn("Multiple attribute modifiers of type Set are present, there should be at most 1")
	end
	
	local newAttributeValue = self:GetAttribute(attributeName)
	
	if (oldAttributeValue ~= newAttributeValue) then
		self.__attributeChangedEvent:Fire(attributeName, newAttributeValue)
	end
end

Unit.RemoveAttributeModifier = function(self, id: string, attributeName: string, modifierType: string)
	local attributeModifiers = self.__attributeModifiers[attributeName]
	if (not attributeModifiers) then return end
	
	local specificAttributeModifiers = attributeModifiers[modifierType]
	if (not specificAttributeModifiers) then return end
	
	local oldAttributeValue = self:GetAttribute(attributeName)	

	specificAttributeModifiers[id] = nil
	
	local newAttributeValue = self:GetAttribute(attributeName)
	
	if (oldAttributeValue ~= newAttributeValue) then
		self.__attributeChangedEvent:Fire(attributeName, newAttributeValue)
	end
end

Unit.Upgrade = function(self)
	local currentLevel = self.Level
	local nextLevelProgression = unitDataCache[self.Name].Progression[currentLevel + 1]
	if (not nextLevelProgression) then return end
	
	if (nextLevelProgression.Attributes) then
		for attributeName, newValue in pairs(nextLevelProgression.Attributes) do
			self:SetAttribute(attributeName, newValue)
		end
	end
	
	if (nextLevelProgression.Abilities) then
		for abilityName, action in pairs(nextLevelProgression.Abilities) do
			if (action == true) then
				self:GiveAbility(abilityName)
			elseif (action == false) then
				self:RemoveAbility(abilityName)
			end
		end
	end
end

Unit.UpgradeUnitType = function(unitName: string, owner: number)
	local progressionData = unitProgressionData[owner]

	if (not progressionData) then
		unitProgressionData[owner] = {}
		progressionData = unitProgressionData[owner]
	end

	local currentLevel = progressionData[unitName] or 1
	local nextLevelProgression = unitDataCache[unitName].Progression[currentLevel + 1]
	if (not nextLevelProgression) then return end

	progressionData[unitName] = currentLevel + 1
end

---

local SetAttributeRemoteFunctionParameters = t.tuple(t.string, t.string, t.any)

for _, abilityDataScript in pairs(AbilityData:GetChildren()) do
	abilitiesCache[abilityDataScript.Name] = require(abilityDataScript)
end

for _, unitDataScript in pairs(UnitData:GetChildren()) do
	unitDataCache[unitDataScript.Name] = require(unitDataScript)
end

-- Players can only change the targeting on tower units for now
SetAttributeRemoteFunction.OnServerInvoke = RemoteUtils.ConnectPlayerDebounce(function(_: Player, unitId: string, attributeName: string, newValue: any)
	if (not SetAttributeRemoteFunctionParameters(unitId, attributeName, newValue)) then return end
	
	local unit = Unit.fromId(unitId)
	if (not unit) then return end
	if (unit.Type ~= GameEnums.UnitType.TowerUnit) then return end
	if (attributeName ~= "UnitTargeting") then return end
	
	unit:SetAttribute(attributeName, newValue)
end)

SetAttributeRemoteFunction.Name = "SetAttribute"
SetAttributeRemoteFunction.Parent = UnitCommunicators

return Unit