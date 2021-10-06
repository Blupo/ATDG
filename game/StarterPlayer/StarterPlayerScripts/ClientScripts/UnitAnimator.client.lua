-- TODO: Implement other animation states (Climb, Fall, Idle)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

---

local LocalPlayer = Players.LocalPlayer

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local UnitAnimations = PlayerScripts:WaitForChild("UnitAnimations")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local TowerUnit = SystemCoordinator.waitForSystem("TowerUnit")

---

local ANIMATION_SPEED_FACTOR  = 8

local unitAnimationsCache = {}
local animationInstancesCache = {}

local fieldUnitSPDChangedConnections = {}
local fieldUnitAnimationStates = {}

---

for _, animationScript in pairs(UnitAnimations:GetChildren()) do
    local unitName = animationScript.Name

    if (animationScript:IsA("ModuleScript") and (not unitAnimationsCache[unitName])) then
        unitAnimationsCache[unitName] = require(animationScript)
    end
end

UnitAnimations.ChildAdded:Connect(function(animationScript)
    if (not animationScript:IsA("ModuleScript")) then return end

    local unitName = animationScript.Name
    if (unitAnimationsCache[unitName]) then return end

    unitAnimationsCache[unitName] = require(animationScript)
end)

TowerUnit.Fired:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    local unitModel = unit.Model
    if (not unitModel:IsDescendantOf(Workspace)) then return end

    local animations = unitAnimationsCache[unit.Name]
    if (not animations) then return end

    local onFiredAnimation = animations.OnFired
    if (not onFiredAnimation) then return end

    onFiredAnimation(unit)
end)

TowerUnit.Hit:Connect(function(thisUnitId: string, targetUnitId: string)
    local thisUnit = Unit.fromId(thisUnitId)
    local thisUnitModel = thisUnit.Model
    if (not thisUnitModel:IsDescendantOf(Workspace)) then return end

    local targetUnit = Unit.fromId(targetUnitId)
    if (not targetUnit) then return end -- in case the target unit gets destroyed

    local animations = unitAnimationsCache[thisUnit.Name]
    if (not animations) then return end

    local onHitAnimation = animations.OnHit
    if (not onHitAnimation) then return end

    onHitAnimation(thisUnit, targetUnit)
end)

Unit.UnitAdded:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    local unitType = unit.Type

    local animations = unitAnimationsCache[unit.Name]
    if (not animations) then return end

    if (unitType == GameEnum.UnitType.TowerUnit) then
        local onAddedCallback = animations.OnAdded
        if (not onAddedCallback) then return end

        onAddedCallback(unit)
    elseif (unitType == GameEnum.UnitType.FieldUnit) then
        local unitModel = unit.Model

        local newAnimationController = Instance.new("AnimationController")
        newAnimationController.Name = "AnimationController"

        local newAnimator = Instance.new("Animator")
        newAnimator.Name = "Animator"

        for _, animationId in pairs(animations) do
            if (not animationInstancesCache[animationId]) then
                local newAnimation = Instance.new("Animation")
                newAnimation.AnimationId = animationId

                animationInstancesCache[animationId] = newAnimation
            end
        end

        newAnimator.Parent = newAnimationController
        newAnimationController.Parent = unitModel
        if (not unitModel:IsDescendantOf(game)) then return end -- in case the unit gets destroyed

        fieldUnitSPDChangedConnections[unitId] = unit.AttributeChanged:Connect(function(attribute, newValue)
            if (attribute ~= "SPD") then return end
            
            local animationState = fieldUnitAnimationStates[unitId]
            if (not animationState) then return end

            local animationTrack = animationState.animationTrack

            if ((animationTrack.Speed == 0) and (newValue > 0)) then
                animationTrack:AdjustSpeed(newValue / ANIMATION_SPEED_FACTOR)
            elseif (animationTrack.Speed > 0) and (newValue == 0) then
                animationTrack:AdjustSpeed(0)
            end
        end)

        local spd = unit:GetAttribute("SPD")
        local animationTrack = newAnimationController:LoadAnimation(animationInstancesCache[animations.Running])
        
        while(animationTrack.Length <= 0) do
            RunService.Heartbeat:Wait()
        end

        animationTrack.Looped = true
        animationTrack:Play(0, 1, spd / ANIMATION_SPEED_FACTOR)

        fieldUnitAnimationStates[unitId] = {
            state = "Running",
            animationTrack = animationTrack
        }
    end
end)

Unit.UnitRemoving:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    local unitType = unit.Type

    local animations = unitAnimationsCache[unit.Name]
    if (not animations) then return end

    if (unitType == GameEnum.UnitType.TowerUnit) then
        local onRemovingCallback = animations.OnRemoving
        if (not onRemovingCallback) then return end

        onRemovingCallback(unit)
    elseif (unitType == GameEnum.UnitType.FieldUnit) then
        fieldUnitSPDChangedConnections[unitId]:Disconnect()
        fieldUnitSPDChangedConnections[unitId] = nil

        fieldUnitAnimationStates[unitId] = nil
    end
end)