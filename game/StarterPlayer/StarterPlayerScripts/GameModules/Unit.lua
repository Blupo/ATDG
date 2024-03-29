local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local UnitData = ReplicatedStorage:WaitForChild("UnitData")
local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local ClientScripts = PlayerScripts:WaitForChild("ClientScripts")
local EventProxy = require(ClientScripts:WaitForChild("EventProxy"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local UnitAddedEvent = Instance.new("BindableEvent")
local UnitRemovingEvent = Instance.new("BindableEvent")

local Unit = SystemCoordinator.waitForSystem("Unit")
local GetUnitPersistentUpgradeLevelRemoteFunction = Unit.GetUnitPersistentUpgradeLevel
local SetAttributeRemoteFunction = Unit.SetAttribute

local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")

---

local IGNORED_ATTRIBUTES = {
    Id = true,
    Name = true,
    Type = true,
    Owner = true,
}

local units = {}
local unitDataCache = {}
local localPlayerUnitPersistentUpgradeLevels = {}

---

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

Unit.GetUnits = function(filterCallback: (any) -> boolean)
    local unitList = {}

    for _, unit in pairs(units) do
        if ((not filterCallback) and true or filterCallback(unit)) then
            table.insert(unitList, unit)
        end
    end

    return unitList
end

Unit.DoesUnitExist = function(unitName: string): boolean
    local unitData = unitDataCache[unitName]
    if (not unitData) then return false end
    
    local unitModel = UnitModels:FindFirstChild(unitName)
    if (not unitModel) then return false end

    return true
end

Unit.GetUnitPersistentUpgradeLevel = function(owner: number, unitName: string): number?
    if (owner ~= LocalPlayer.UserId) then
        return GetUnitPersistentUpgradeLevelRemoteFunction(owner, unitName)
    end

    if (not Unit.DoesUnitExist(unitName)) then return end

    return localPlayerUnitPersistentUpgradeLevels[unitName] or 1
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

Unit.GetUnitBaseAbilities = function(unitName: string, level: number): {[string]: boolean}?
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

Unit.UnitPersistentUpgraded = EventProxy(Unit.UnitPersistentUpgraded, function(owner: number, unitName: string, newLevel: number)
    if (owner ~= LocalPlayer.UserId) then return end

    localPlayerUnitPersistentUpgradeLevels[unitName] = newLevel
end)

--- Class

Unit.GetAttribute = function(self, attributeName: string)
    if (IGNORED_ATTRIBUTES[attributeName] and (attributeName ~= "Level")) then return end

    return self.Model:GetAttribute(attributeName)
end

Unit.SetAttribute = function(self, attributeName: string, newValue: any)
    SetAttributeRemoteFunction(self.Id, attributeName, newValue)
end

local constructUnit = function(unitModel)
    local diedEvent = Instance.new("BindableEvent")
    local attributeChangedEvent = Instance.new("BindableEvent")
    local upgradedEvent = Instance.new("BindableEvent")

    local unitName = unitModel:GetAttribute("Name")
    local appearanceModel = UnitModels:FindFirstChild(unitName):Clone()
    local appearanceModelPrimaryPart = appearanceModel.PrimaryPart
    local unitModelBoundingPart = unitModel:WaitForChild("_BoundingPart")

    local appearanceModelOrientation = appearanceModel:GetBoundingBox()
    local unitModelOrientation = unitModel:GetBoundingBox()

    local offset = appearanceModelOrientation:ToObjectSpace(appearanceModelPrimaryPart.CFrame)
    appearanceModel:SetPrimaryPartCFrame(unitModelOrientation:ToWorldSpace(offset))

    local boundingPartWeld = Instance.new("WeldConstraint")
    boundingPartWeld.Name = "BoundingPartWeld"
    boundingPartWeld.Part0 = unitModelBoundingPart
    boundingPartWeld.Part1 = appearanceModelPrimaryPart
    boundingPartWeld.Parent = unitModelBoundingPart

    local appearanceModelChildren = appearanceModel:GetChildren()
    
    for i = 1, #appearanceModelChildren do
        local child = appearanceModelChildren[i]
        local descendants = child:GetDescendants()

        for j = 1, #descendants do
            local descendant = descendants[j]

            if (descendant:IsA("BasePart")) then
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.Massless = true
            end
        end

        if (child:IsA("BasePart")) then
            child.CanCollide = false
            child.CanTouch = false
            child.Massless = true
        end

        child.Parent = unitModel
    end

    unitModel.PrimaryPart = appearanceModelPrimaryPart
    
    local unit = setmetatable({
        Id = unitModel:GetAttribute("Id"),
        Name = unitName,
        DisplayName = unitModel:GetAttribute("DisplayName"),
        Type = unitModel:GetAttribute("Type"),
        Owner = unitModel:GetAttribute("Owner"),
        Level = unitModel:GetAttribute("Level"),
        Model = unitModel,
        
        Died = diedEvent.Event,
        AttributeChanged = attributeChangedEvent.Event,
        Upgraded = upgradedEvent.Event,
        
        __diedEvent = diedEvent,
        __attributeChangedEvent = attributeChangedEvent,
        __upgradedEvent = upgradedEvent,
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
        elseif (attributeName == "Level") then
            local newLevel = unitModel:GetAttribute(attributeName)

            unit.Level = newLevel
            unit.__upgradedEvent:Fire(newLevel)
            return
        end
        
        attributeChangedEvent:Fire(attributeName, unitModel:GetAttribute(attributeName))
    end)
    
    units[unit.Id] = unit
    UnitAddedEvent:Fire(unit.Id)
end

local destroyUnit = function(unit)
    UnitRemovingEvent:Fire(unit.Id)
    
    unit.__diedEvent:Destroy()
    unit.__attributeChangedEvent:Destroy()
    unit.__upgradedEvent:Destroy()
    
    -- defer so that subscriptions have a chance to obtain the Unit for cleanup
    task.defer(function()
        units[unit.Id] = nil
    end)
end

---

localPlayerUnitPersistentUpgradeLevels = Unit.GetAllUnitsPersistentUpgradeLevels(LocalPlayer.UserId)

do
    local unitModelDescendantCounts = Unit.GetUnitModelDescendantCounts()

    for unitName, numDescendants in pairs(unitModelDescendantCounts) do
        local unitModel = UnitModels:WaitForChild(unitName)

        while (#unitModel:GetDescendants() < numDescendants) do
            RunService.Heartbeat:Wait()
        end
    end
end

for _, unitDataScript in pairs(UnitData:GetChildren()) do
    local unitName = unitDataScript.Name

    if (unitDataScript:IsA("ModuleScript") and (not unitDataCache[unitName])) then
        unitDataCache[unitName] = require(unitDataScript)
    end
end

UnitData.ChildAdded:Connect(function(unitDataScript)
    if (not unitDataScript:IsA("ModuleScript")) then return end

    local unitName = unitDataScript.Name
    if (unitDataCache[unitName]) then return end

    unitDataCache[unitName] = require(unitDataScript)
end)

do
    local serverType = ServerMaster.GetServerType() or ServerMaster.ServerInitialised:Wait()

    if (serverType == GameEnum.ServerType.Game) then
        for _, unitModel in pairs(CollectionService:GetTagged(GameEnum.ObjectType.Unit)) do
            constructUnit(unitModel)
        end

        CollectionService:GetInstanceAddedSignal(GameEnum.ObjectType.Unit):Connect(constructUnit)

        CollectionService:GetInstanceRemovedSignal(GameEnum.ObjectType.Unit):Connect(function(unitModel)
            local unit = Unit.fromModel(unitModel)
            if (not unit) then return end
            
            destroyUnit(unit)
        end)
    end
end

return Unit