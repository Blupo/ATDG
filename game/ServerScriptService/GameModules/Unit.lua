local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local UnitData = ReplicatedStorage:FindFirstChild("UnitData")
local UnitModels = ReplicatedStorage:FindFirstChild("UnitModels")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local CopyTable = require(SharedModules:FindFirstChild("CopyTable"))
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local UnitAddedEvent = Instance.new("BindableEvent")
local UnitRemovingEvent = Instance.new("BindableEvent")
local UnitPersistentUpgradedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("Unit")
local UnitPersistentUpgradedRemoteEvent = System.addEvent("UnitPersistentUpgraded")

---

local units = {}
local unitPersistentUpgradeLevels = {}
local unitDataCache = {}

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

Unit.GetUnits = function(filterCallback: ((any) -> boolean)?)
	local unitList = {}

	for _, unit in pairs(units) do
		if ((not filterCallback) and true or filterCallback(unit)) then
			table.insert(unitList, unit)
		end
	end

	return unitList
end

Unit.GetUnitType = function(unitName: string): string?
	if (not Unit.DoesUnitExist(unitName)) then return end

	return unitDataCache[unitName].Type
end

Unit.GetUnitDisplayName = function(unitName: string): string?
	if (not Unit.DoesUnitExist(unitName)) then return end

	local unitData = unitDataCache[unitName]
	return unitData.DisplayName or unitName
end

Unit.GetTowerUnitSurfaceType = function(unitName: string): string?
	if (not Unit.DoesUnitExist(unitName)) then return end
	if (Unit.GetUnitType(unitName) ~= GameEnum.UnitType.TowerUnit) then return end

	return unitDataCache[unitName].SurfaceType
end

Unit.GetUnitMaxLevel = function(unitName: string): number?
	if (not Unit.DoesUnitExist(unitName)) then return end

	return #unitDataCache[unitName].Progression
end

Unit.GetUnitBaseAttributes = function(unitName: string, level: number): dictionary<string, any>?
	if (not Unit.DoesUnitExist(unitName)) then return end

	local unitData = unitDataCache[unitName]
	local immutableAttributes = unitData.ImmutableAttributes or {}
	local attributes = {}

	local maxLevel = Unit.GetUnitMaxLevel(unitName)
	level = (level <= maxLevel) and level or maxLevel

	for i = 1, level do
		local progressionData = unitData.Progression[i]
		local progressionDataAttributes = progressionData.Attributes or {}

		for attributeName, baseValue in pairs(progressionDataAttributes) do
			if (immutableAttributes[attributeName] == nil) then
				attributes[attributeName] = baseValue
			end
		end
	end

	for attributeName, baseValue in pairs(immutableAttributes) do
		attributes[attributeName] = baseValue
	end

	return attributes
end

Unit.GetUnitAbilities = function(unitName: string, level: number): {[string]: boolean}?
	if (not Unit.DoesUnitExist(unitName)) then return end

	local unitData = unitDataCache[unitName]
	local abilities = {}

	local maxLevel = Unit.GetUnitMaxLevel(unitName)
	level = (level <= maxLevel) and level or maxLevel

	for i = 1, level do
		local unitProgression = unitData.Progression[i]

		if (unitProgression) then
			local levelAbilities = unitProgression.Abilities or {}

			for ability, action in pairs(levelAbilities) do
				if (action == true) then
					abilities[ability] = true
				elseif (action == false) then
					abilities[ability] = nil
				end
			end
		end
	end

	return abilities
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
	local unitType = unitData.Type
	local unitModel = UnitModels:FindFirstChild(unitName)
	local newUnitLevel = 1
	
	if (unitPersistentUpgradeLevels[owner]) then
		newUnitLevel = unitPersistentUpgradeLevels[owner][unitName] or 1
	end

	local attributes = Unit.GetUnitBaseAttributes(unitName, newUnitLevel)

	if (unitType == GameEnum.UnitType.FieldUnit) then
		attributes.UnitTargeting = GameEnum.UnitTargeting.None
	elseif ((unitType == GameEnum.UnitType.TowerUnit) and (not attributes.UnitTargeting)) then
		attributes.UnitTargeting = GameEnum.UnitTargeting.First
	end

	attributes.HP = attributes.MaxHP
	
	local newBaseModel = unitModel:Clone()
	local attributeChangedEvent = Instance.new("BindableEvent")
	local upgradedEvent = Instance.new("BindableEvent")
	local damageTakenEvent = Instance.new("BindableEvent")
	local diedEvent = Instance.new("BindableEvent")
	
	local self = setmetatable({
		Id = HttpService:GenerateGUID(false),
		Name = unitName,
		DisplayName = unitData.DisplayName or unitName,
		Type = unitType,
		Owner = owner,
		Level = newUnitLevel,
		Model = newBaseModel,
		
		AttributeChanged = attributeChangedEvent.Event,
		Upgraded = upgradedEvent.Event,
		DamageTaken = damageTakenEvent.Event,
		Died = diedEvent.Event,
		
		__attributeChangedEvent = attributeChangedEvent,
		__upgradedEvent = upgradedEvent,
		__damageTakenEvent = damageTakenEvent,
		__diedEvent = diedEvent,

		__baseAttributes = attributes,
		__attributeModifiers = {},
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
	newBaseModel:SetAttribute("DisplayName", self.DisplayName)
	newBaseModel:SetAttribute("Type", self.Type)
	newBaseModel:SetAttribute("Owner", self.Owner)
	newBaseModel:SetAttribute("Level", self.Level)
	
	for key, value in pairs(self.__baseAttributes) do
		newBaseModel:SetAttribute(key, value)
	end
	
	self.AttributeChanged:Connect(function(attributeName: string, newValue: any)
		newBaseModel:SetAttribute(attributeName, newValue)
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
	
	self.__attributeChangedEvent:Destroy()
	self.__upgradedEvent:Destroy()
	self.__damageTakenEvent:Destroy()
	self.__diedEvent:Destroy()
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
	if ((attributeName == "HP") or (attributeName == "MaxHP")) then return end

	local unitData = unitDataCache[self.Name]
	local immutableAttributes = unitData.ImmutableAttributes

	if (immutableAttributes) then
		if (immutableAttributes[attributeName] ~= nil) then return end
	end

	local oldValue = self:GetAttribute(attributeName)
	if (type(oldValue) ~= type(newValue)) then return end
	if (oldValue == newValue) then return end

	self.__baseAttributes[attributeName] = newValue
	self.__attributeChangedEvent:Fire(attributeName, self:GetAttribute(attributeName))
end

Unit.TakeDamage = function(self, damage: number, damageSourceType: string?, damageSource: string | number | nil, ignoreDEF: boolean?)
	if (damage <= 0) then return end
	
	local hp = self:GetAttribute("HP")
	local def = ignoreDEF and 0 or self:GetAttribute("DEF")

	local effectiveDamage = (damage * damage) / (damage + def)
	if (effectiveDamage <= 0) then return end

	local newHP = hp - effectiveDamage
	newHP = (newHP >= 0) and newHP or 0

	self.__baseAttributes.HP = newHP
	self.__attributeChangedEvent:Fire("HP", newHP)
	self.__damageTakenEvent:Fire(effectiveDamage, damageSourceType or GameEnum.DamageSourceType.Almighty, damageSource)

	if (newHP <= 0) then
		self.__diedEvent:Fire()
		self:Destroy()
	end
end

Unit.ApplyAttributeModifier = function(self, id: string, attributeName: string, modifierType: string, modifier: (any) -> any)
	if ((attributeName == "HP") or (attributeName == "MaxHP")) then return end

	local unitData = unitDataCache[self.Name]
	local immutableAttributes = unitData.ImmutableAttributes

	if (immutableAttributes) then
		if (immutableAttributes[attributeName] ~= nil) then return end
	end
	
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

	self.Level = nextLevel
	self.__upgradedEvent:Fire(nextLevel)
	self.Model:SetAttribute("Level", nextLevel)
end

---

for _, unitDataScript in pairs(UnitData:GetChildren()) do
	local unitName = unitDataScript.Name

	if (unitDataScript:IsA("ModuleScript") and (not unitDataCache[unitName])) then
		unitDataCache[unitName] = require(unitDataScript)
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