-- todo: support touch

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

---

local CurrentCamera = Workspace.CurrentCamera

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local ObjectSelectionSurfaceGui = require(GameUIModules:WaitForChild("ObjectSelectionSurfaceGui"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))
local TowerUnitUpgrader = require(GameUIModules:WaitForChild("TowerUnitUpgrader"))

local RadiusPart = Instance.new("Part")
RadiusPart.Name = "TowerUnitUI.SelectedUnitRadiusPart"
RadiusPart.CFrame = CFrame.new(0, math.huge, 0)
RadiusPart.Size = Vector3.new(0, 0, 0)
RadiusPart.Transparency = -1
RadiusPart.CastShadow = false
RadiusPart.CanCollide = false
RadiusPart.CanTouch = false
--RadiusPart.CanQuery = false
RadiusPart.Anchored = true
RadiusPart.Material = Enum.Material.ForceField
RadiusPart.Shape = Enum.PartType.Ball
RadiusPart.Color = Style.Colors.RANGEAttributeIconColor

local SurfaceGuiPart = Instance.new("Part")
SurfaceGuiPart.Name = "TowerUnitUI.SelectedUnitSurfaceGuiPart"
SurfaceGuiPart.CFrame = CFrame.new(0, math.huge, 0)
SurfaceGuiPart.Size = Vector3.new(0, 0, 0)
SurfaceGuiPart.Transparency = 1
SurfaceGuiPart.CastShadow = false
SurfaceGuiPart.CanCollide = false
SurfaceGuiPart.CanTouch = false
--SurfaceGuiPart.CanQuery = false
SurfaceGuiPart.Anchored = true

---

local lastUnit
local surfaceGuiTree
local upgradeGuiTree
local unitUpgradedConnection

local raycastParamsFilter = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = {}

local reset = function()
    lastUnit = nil

    if (unitUpgradedConnection) then
        unitUpgradedConnection:Disconnect()
        unitUpgradedConnection = nil
    end

    if (upgradeGuiTree) then
        Roact.unmount(upgradeGuiTree)
        upgradeGuiTree = nil
    end

    RadiusPart.CFrame = CFrame.new(0, math.huge, 0)

    Roact.update(surfaceGuiTree, Roact.createElement(ObjectSelectionSurfaceGui, {
        Adornee = SurfaceGuiPart,
        enabled = false,
    }))
end

---

surfaceGuiTree = Roact.mount(Roact.createElement(ObjectSelectionSurfaceGui, {
    Adornee = SurfaceGuiPart,
    enabled = false,
}), PlayerGui, "TowerUnitUI.SelectedUnitSurfaceGui")

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    local isTouch = (input.UserInputType == Enum.UserInputType.Touch)

    if (gameProcessedEvent) then return end
    if ((input.UserInputType ~= Enum.UserInputType.MouseButton1) and (not isTouch)) then return end
    if (input.UserInputState ~= Enum.UserInputState.Begin) then return end

    local inputPosition = input.Position
    local ray = CurrentCamera:ScreenPointToRay(inputPosition.X, inputPosition.Y)
    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

    if (not raycastResult) then
        if (not isTouch) then
            reset()
        end

        return
    end

    local raycastPart = raycastResult.Instance

    if (not raycastPart:IsA("BasePart")) then
        if (not isTouch) then
            reset()
        end

        return
    end

    local unit

    for i = 1, #raycastParamsFilter do
        local unitModel = raycastParamsFilter[i]

        if (raycastPart:IsDescendantOf(unitModel)) then
            unit = Unit.fromModel(unitModel)
            break
        end
    end

    if (not unit) then
        if (not isTouch) then
            reset()
        end

        return
    end

    if (lastUnit == unit) then return end
    lastUnit = unit

    local unitRange = unit:GetAttribute("RANGE")
    local orientation, bounds = unit.Model:GetBoundingBox()
    local surfaceGuiPartSize = math.max(bounds.X, bounds.Z) + 1

    RadiusPart.Size = Vector3.new(unitRange, unitRange, unitRange) * 2
    SurfaceGuiPart.Size = Vector3.new(surfaceGuiPartSize, 0, surfaceGuiPartSize)
    RadiusPart.CFrame = orientation
    SurfaceGuiPart.CFrame = orientation:ToWorldSpace(CFrame.new(0, -(bounds.Y / 2), 0))

    unitUpgradedConnection = unit.Upgraded:Connect(function()
        local newRange = unit:GetAttribute("RANGE")

        RadiusPart.Size = Vector3.new(newRange, newRange, newRange) * 2
    end)

    if (upgradeGuiTree) then
        Roact.unmount(upgradeGuiTree)
        upgradeGuiTree = nil
    end

    Roact.update(surfaceGuiTree, Roact.createElement(ObjectSelectionSurfaceGui, {
        Adornee = SurfaceGuiPart,
        enabled = true,
    }))
    
    upgradeGuiTree = Roact.mount(Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
    }, {
        Upgrader = Roact.createElement(TowerUnitUpgrader, {
            unitId = unit.Id,
            onClose = reset,
        }),
    }), PlayerGui, "TowerUnitUI.UpgradeGui")
end)

Unit.UnitAdded:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return end
    if (unit.Owner ~= LocalPlayer.UserId) then return end

    table.insert(raycastParamsFilter, unit.Model)
    raycastParams.FilterDescendantsInstances = raycastParamsFilter
end)

Unit.UnitRemoving:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    local unitModel = unit.Model

    if (unit == lastUnit) then
        reset()
    end

    local unitModelIndex = table.find(raycastParamsFilter, unitModel)
    if (not unitModelIndex) then return end

    table.remove(raycastParamsFilter, unitModelIndex)
    raycastParams.FilterDescendantsInstances = raycastParamsFilter
end)

PlacementFlow.Started:Connect(function()
    if (lastUnit) then
        reset()
    end
end)

RadiusPart.Parent = CurrentCamera
SurfaceGuiPart.Parent = CurrentCamera