local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService(("ServerScriptService"))

---

local AbilityData = ServerScriptService:FindFirstChild("AbilityData")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Unit = require(GameModules:FindFirstChild("Unit"))

local AbilityGivenEvent = Instance.new("BindableEvent")
local AbilityRemovedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("Abilities")

---

local abilitiesCache = {}
local unitAbilities = {}
local unitUpgradedConnections = {}

---

local Abilities = {
	AbilityGiven = AbilityGivenEvent.Event,
	AbilityRemoved = AbilityRemovedEvent.Event,
}

Abilities.UnitHasAbility = function(unit, abilityName: string): boolean
    return unitAbilities[unit.Id][abilityName] and true or false
end

Abilities.GetUnitAbilities = function(unit, abilityType: string?): {string}
    local abilities = {}
	
	for ability in pairs(unitAbilities[unit.Id]) do
		if ((not abilityType) or (abilitiesCache[ability].AbilityType == abilityType)) then
			table.insert(abilities, ability)
		end
	end
	
	return abilities
end

Abilities.GiveUnitAbility = function(unit, abilityName: string)
    if (not abilitiesCache[abilityName]) then return end
	if (Abilities.UnitHasAbility(unit, abilityName)) then return end
	
	local abilityData = abilitiesCache[abilityName]
	if (not abilityData) then return end
	
	if (abilityData.UnitType) then
		if (unit.Type ~= abilityData.UnitType) then return end
	end
	
	unitAbilities[unit.Id][abilityName] = true
	AbilityGivenEvent:Fire(unit.Id, abilityName)
end

Abilities.RemoveUnitAbility = function(unit, abilityName: string)
    if (not Abilities.UnitHasAbility(unit, abilityName)) then return end

	unitAbilities[unit.Id][abilityName] = nil
	AbilityRemovedEvent:Fire(unit.Id, abilityName)
end

Abilities.ActivateAbilities = function(unit, abilityType: string, extraData: {[string]: any}?)
	if (abilityType == GameEnum.AbilityType.Manual) then return end

	for abilityName in pairs(unitAbilities[unit.Id]) do
		local abilityData = abilitiesCache[abilityName]

		if (abilityData.AbilityType == abilityType) then
			abilityData.Callback(unit, extraData)
		end
	end
end

Abilities.ActivateAbility = function(unit, abilityName: string, extraData: {[string]: any}?)
    if (not Abilities.UnitHasAbility(unit, abilityName)) then return end

	abilitiesCache[abilityName].Callback(unit, extraData)
end

---

for _, abilityDataScript in pairs(AbilityData:GetChildren()) do
	abilitiesCache[abilityDataScript.Name] = require(abilityDataScript)
end

Unit.UnitAdded:Connect(function(unitId)
	local unit = Unit.fromId(unitId)
	if (not unit) then return end

	unitAbilities[unitId] = Unit.GetUnitAbilities(unit.Name, unit.Level)

	unitUpgradedConnections[unitId] = unit.Upgraded:Connect(function(newLevel)
		unitAbilities[unitId] = Unit.GetUnitAbilities(unit.Name, newLevel)
	end)
end)

Unit.UnitRemoving:Connect(function(unitId)
	local unitUpgradedConnection = unitUpgradedConnections[unitId]

	if (unitUpgradedConnection) then
		unitUpgradedConnection:Disconnect()
	end

    unitAbilities[unitId] = nil
	unitUpgradedConnections[unitId] = nil
end)

System.addEvent("AbilityGiven", Abilities.AbilityGiven)
System.addEvent("AbilityRemoved", Abilities.AbilityRemoved)

System.addFunction("ActivateAbility", t.wrap(function(player: Player, unitId: string, abilityName: string, extraData: {[string]: any})
	local unit = Unit.fromId(unitId)
	if (not unit) then return end
	if (unit.Owner ~= player.UserId) then return end

	local abilityData = abilitiesCache[abilityName]
	if (abilityData.AbilityType ~= GameEnum.AbilityType.Manual) then return end -- Clients can only activate Manual abilities

	if (abilityData.UnitType) then
		if (abilityData.UnitType ~= unit.Type) then return end
	end

	Abilities.ActivateAbility(unit, abilityName, extraData)
end, t.tuple(t.instanceOf("Player"), t.string, t.string, t.map(t.string, t.any))), true)

return Abilities