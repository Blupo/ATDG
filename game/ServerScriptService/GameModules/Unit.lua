local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local UnitModels = ReplicatedStorage:FindFirstChild("UnitModels")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local CopyTable = require(SharedModules:FindFirstChild("CopyTable"))
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local AbilityData = ServerScriptService:FindFirstChild("AbilityData")
local UnitData = ReplicatedStorage:FindFirstChild("UnitData")

local UnitAddedEvent = Instance.new("BindableEvent")
local UnitRemovingEvent = Instance.new("BindableEvent")
local UnitPersistentUpgradedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("Unit")
local UnitPersistentUpgradedRemoteEvent = System.addEvent("UnitPersistentUpgraded")

---

local units = {}
local unitPersistentUpgradeLevels = {}
local unitDataCache = {}
local abilitiesCache = {}

local attributeChangedCallbacks = {
	HP = function(unit, newHP)
		if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return end
		
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


--- Static

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

Unit.DoesUnitExist = function(unitName: string): boolean
	local unitData = unitDataCache[unitName]
	if (not unitData) then return false end
	
	local unitModel = UnitModels:FindFirstChild(unitName)
	if (not unitModel) then return false end

	return true
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

Unit.GetUnitType = function(unitName: string): string?
	if (not Unit.DoesUnitExist(unitName)) then return end

	return unitDataCache[unitName].Type
end

Unit.GetAllUnitsPersistentUpgradeLevels = function(owner: number): {[string]: number}?
	local persistentUpgradeLevels = unitPersistentUpgradeLevels[owner]

	if (not persistentUpgradeLevels) then
		unitPersistentUpgradeLevels[owner] = {}
		persistentUpgradeLevels = unitPersistentUpgradeLevels[owner]
	end

	persistentUpgradeLevels = CopyTable(persistentUpgradeLevels)

	for unitName in pairs(unitDataCache) do
		if ((not persistentUpgradeLevels[unitName]) and Unit.DoesUnitExist(unitName)) then
			persistentUpgradeLevels[unitName] = 1
		end
	end

	return persistentUpgradeLevels
end

Unit.GetUnitPersistentUpgradeLevel = function(owner: number, unitName: string): number?
	if (not Unit.DoesUnitExist(unitName)) then return end

	local persistentUpgradeLevels = unitPersistentUpgradeLevels[owner]

	if (not persistentUpgradeLevels) then
		unitPersistentUpgradeLevels[owner] = {}
		persistentUpgradeLevels = unitPersistentUpgradeLevels[owner]
	end

	return persistentUpgradeLevels[unitName] or 1
end

Unit.GetUnitBaseAttributes = function(unitName: string, level: number): dictionary<string, any>?
	if (not Unit.DoesUnitExist(unitName)) then return end

	local unitData = unitDataCache[unitName]
	local attributes = {}

	for i = 1, level do
		local progressionData = unitData.Progression[i]
		local progressionDataAttributes = progressionData and progressionData.Attributes or nil

		if (progressionDataAttributes) then
			for attributeName, baseValue in pairs(progressionDataAttributes) do
				attributes[attributeName] = baseValue
			end
		end
	end

	return attributes
end

Unit.GetUnitMaxLevel = function(unitName: string): number?
	if (not Unit.DoesUnitExist(unitName)) then return end

	return #unitDataCache[unitName].Progression
end

Unit.DoUnitPersistentUpgrade = function(owner: number, unitName: string)
	if (not Unit.DoesUnitExist(unitName)) then return end

	local progressionData = unitPersistentUpgradeLevels[owner]

	if (not progressionData) then
		unitPersistentUpgradeLevels[owner] = {}
		progressionData = unitPersistentUpgradeLevels[owner]
	end

	local nextLevel = (progressionData[unitName] or 1) + 1
	local nextLevelProgression = unitDataCache[unitName].Progression[nextLevel]
	if (not nextLevelProgression) then return end

	progressionData[unitName] = nextLevel
	UnitPersistentUpgradedEvent:Fire(owner, unitName, nextLevel)
end

--- Class

Unit.new = function(unitName: string, owner: number?)
	owner = owner or 0
	assert(Unit.DoesUnitExist(unitName), unitName .. " is not a valid Unit")

	local unitData = unitDataCache[unitName]
	local unitModel = UnitModels:FindFirstChild(unitName)
	local newUnitLevel = 1
	
	if (unitPersistentUpgradeLevels[owner]) then
		newUnitLevel = unitPersistentUpgradeLevels[owner][unitName] or 1
	end

	local attributes = {}
	local abilities = {}

	for level = 1, newUnitLevel do
		local unitProgression = unitData.Progression[level]

		if (unitProgression) then
			local levelAttributes = unitProgression.Attributes or {}
			local levelAbilities = unitProgression.Abilities or {}

			for attribute, value in pairs(levelAttributes) do
				attributes[attribute] = value
			end

			for ability in pairs(levelAbilities) do
				abilities[ability] = true
			end
		end
	end

	attributes.HP = attributes.MaxHP
	
	local newBaseModel = unitModel:Clone()
	local diedEvent = Instance.new("BindableEvent")
	local attributeChangedEvent = Instance.new("BindableEvent")
	local upgradedEvent = Instance.new("BindableEvent")
	
	local self = setmetatable({
		Id = HttpService:GenerateGUID(false),
		Name = unitName,
		Type = unitData.Type,
		Owner = owner,
		Level = newUnitLevel,
		Model = newBaseModel,
		
		Died = diedEvent.Event,
		AttributeChanged = attributeChangedEvent.Event,
		Upgraded = upgradedEvent.Event,
		
		__diedEvent = diedEvent,
		__attributeChangedEvent = attributeChangedEvent,
		__upgradedEvent = upgradedEvent,
		__baseAttributes = attributes,
		__attributeModifiers = {},
		__abilities = abilities,
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
	self.__upgradedEvent:Destroy()
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
		local multiplicativeModifiers = attributeModifiers[GameEnum.AttributeModifierType.Multiplicative]
		local additiveModifiers = attributeModifiers[GameEnum.AttributeModifierType.Additive]
		local setModifiers = attributeModifiers[GameEnum.AttributeModifierType.Set]
		
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
	if (oldValue == newValue) then return end

	self.__baseAttributes[attributeName] = newValue
	self.__attributeChangedEvent:Fire(attributeName, self:GetAttribute(attributeName))
end

Unit.TakeDamage = function(self, damage: number, ignoreDEF: boolean?)
	if (damage <= 0) then return end
	
	local hp = self:GetAttribute("HP")
	local def = ignoreDEF and 0 or self:GetAttribute("DEF")

	-- effective damage in whole numbers only
	local effectiveDamage = (damage * damage) / (damage + def)
	effectiveDamage = math.floor(effectiveDamage + 0.5)
	if (effectiveDamage <= 0) then return end

	self:SetAttribute("HP", hp - effectiveDamage)
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
			[GameEnum.AttributeModifierType.Multiplicative] = {},
			[GameEnum.AttributeModifierType.Additive] = {},
			[GameEnum.AttributeModifierType.Set] = {},
		}
		
		attributeModifiers = self.__attributeModifiers[attributeName]
	end
	
	local specificAttributeModifiers = attributeModifiers[modifierType]
	if (not specificAttributeModifiers) then return end
	if (specificAttributeModifiers[id]) then return end
	
	local oldAttributeValue = self:GetAttribute(attributeName)
	
	if ((type(oldAttributeValue) ~= "number") and (modifierType ~= GameEnum.AttributeModifierType.Set)) then
		return
	end
	
	specificAttributeModifiers[id] = modifier
	
	if ((modifierType == GameEnum.AttributeModifierType.Set) and (dictionaryCount(specificAttributeModifiers) > 1)) then
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
	if (self.Type == GameEnum.UnitType.FieldUnit) then return end -- Field Units cannot be upgraded once deployed

	local nextLevel = self.Level + 1
	local nextLevelProgression = unitDataCache[self.Name].Progression[nextLevel]
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

	self.Level = nextLevel
	self.__upgradedEvent:Fire(nextLevel)
	self.Model:SetAttribute("Level", nextLevel)
end

---

for _, abilityDataScript in pairs(AbilityData:GetChildren()) do
	abilitiesCache[abilityDataScript.Name] = require(abilityDataScript)
end

for _, unitDataScript in pairs(UnitData:GetChildren()) do
	local unitName = unitDataScript.Name

	if (unitDataScript:IsA("ModuleScript") and (not unitDataCache[unitName])) then
		unitDataCache[unitDataScript.Name] = require(unitDataScript)
	end
end

UnitPersistentUpgradedEvent.Event:Connect(function(owner: number, ...)
	local player = Players:GetPlayerByUserId(owner)
	if (not player) then return end

	UnitPersistentUpgradedRemoteEvent:FireClient(player, owner, ...)
end)

-- Players can only change the targeting on tower units for now
System.addFunction("SetAttribute", t.wrap(function(player: Player, unitId: string, attributeName: string, newValue: any)
	local unit = Unit.fromId(unitId)
	if (not unit) then return end
	if (unit.Owner ~= player.UserId) then return end
	if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return end
	if (attributeName ~= "UnitTargeting") then return end
	
	unit:SetAttribute(attributeName, newValue)
end, t.tuple(t.instanceOf("Player"), t.string, t.string, t.any)), true)

System.addFunction("GetAllUnitsPersistentUpgradeLevels", t.wrap(function(player: Player, owner: number): {[string]: number}?
	if (player.UserId ~= owner) then return end

	return Unit.GetAllUnitsPersistentUpgradeLevels(owner)
end, t.tuple(t.instanceOf("Player"), t.number)), true)

System.addFunction("GetUnitPersistentUpgradeLevel", t.wrap(function(player: Player, owner: number, unitName: string): number?
	if (player.UserId ~= owner) then return end

	return Unit.GetUnitPersistentUpgradeLevel(owner, unitName)
end, t.tuple(t.instanceOf("Player"), t.number, t.string)), true)

return Unit