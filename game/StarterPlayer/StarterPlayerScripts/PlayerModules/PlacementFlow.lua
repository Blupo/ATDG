-- TODO: Disable CanQuery when it has been released

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

---

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local ControlInstructions = require(GameUIModules:WaitForChild("ControlInstructions"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))
local UnitPlacementTouchControls = require(GameUIModules:WaitForChild("UnitPlacementTouchControls"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local Placement = require(SharedModules:WaitForChild("Placement"))

local CurrentCamera = Workspace.CurrentCamera
local World = Workspace:WaitForChild("World")

local StartedEvent = Instance.new("BindableEvent")
local StoppedEvent = Instance.new("BindableEvent")

local PointerPart = Instance.new("Part")
PointerPart.Name = "PlacementFlow.PointerPart"
PointerPart.CFrame = CFrame.new(0, math.huge, 0)
PointerPart.Size = Vector3.new(0, 0, 0)
PointerPart.Transparency = 0.5
PointerPart.CastShadow = false
PointerPart.CanCollide = false
PointerPart.CanTouch = false
PointerPart.Anchored = true
PointerPart.Material = Enum.Material.SmoothPlastic

local RadiusPart = Instance.new("Part")
RadiusPart.Name = "PlacementFlow.RadiusPart"
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

---

local MOVE_MODEL_ACTION_KEY = "PlacementFlow.MovePlacementModel"
local ROTATE_MODEL_ACTION_KEY = "PlacementFlow.RotatePlacementModel"
local CANCEL_ACTION_KEY = "PlacementFlow.Cancel"
local PLACE_ACTION_KEY = "PlacementFlow.Place"

local userInputTypeUITypeMap = {
    [Enum.UserInputType.MouseButton1] = "MouseAndKeyboard",
    [Enum.UserInputType.MouseButton2] = "MouseAndKeyboard",
    [Enum.UserInputType.MouseButton3] = "MouseAndKeyboard",
    [Enum.UserInputType.MouseWheel] = "MouseAndKeyboard",
    [Enum.UserInputType.MouseMovement] = "MouseAndKeyboard",
    [Enum.UserInputType.Keyboard] = "MouseAndKeyboard",

    [Enum.UserInputType.Gamepad1] = "Gamepad",
    [Enum.UserInputType.Touch] = "Touch",
}

local uiTypeControls = {
    MouseAndKeyboard = {
        [Enum.UserInputType.MouseButton1] = {
            LayoutOrder = 0,
            Instructions = "Place"
        },

        [Enum.KeyCode.Q] = {
            LayoutOrder = 1,
            Instructions = "Cancel"
        },

        [Enum.KeyCode.R] = {
            LayoutOrder = 2,
            Instructions = "Rotate"
        },
    },

    Gamepad = {
        [Enum.KeyCode.ButtonY] = {
            LayoutOrder = 0,
            Instructions = "Place"
        },

        [Enum.KeyCode.ButtonB] = {
            LayoutOrder = 1,
            Instructions = "Cancel"
        },

        [Enum.KeyCode.ButtonL1] = {
            LayoutOrder = 2,
            Instructions = "Rotate Left"
        },

        [Enum.KeyCode.ButtonR1] = {
            LayoutOrder = 3,
            Instructions = "Rotate Right"
        },
    },
}

local placementsArray = {}
local placementsMap = {}
local unitModelInfoCache = {}

local currentObjName
local currentObjModel
local currentObjSurfaceType
local placementUITree
local placementActive = false

local lastMousePosition
local lastRaycastOrigin
local lastRaycastDirection
local lastUIType
local rotation = 0

local overlapParamsFilter = {World}
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
overlapParams.FilterDescendantsInstances = overlapParamsFilter

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = {World}

local mountControlGui
local placeObject

local surfacePartAdded = function(surfacePart, doNotRefreshImmediately)
    local newPlacement = Placement.new(surfacePart)

    placementsMap[surfacePart] = newPlacement
    table.insert(placementsArray, newPlacement)

    if (not doNotRefreshImmediately) then
        Placement.Merge(placementsArray)
    end
end

local surfacePartRemoved = function(surfacePart)
    local surfacePartIndex = table.find(placementsArray, surfacePart)
    if (not surfacePartIndex) then return end

    placementsMap[surfacePart] = nil
    table.remove(placementsArray, surfacePartIndex)
    Placement.Merge(placementsArray)
end

local updateModel = function(mousePosition: Vector2 | Vector3, ignoreGuiInset: boolean?)
    if (not currentObjModel) then return end

    local ray = ignoreGuiInset and
        CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y, 0)
    or CurrentCamera:ScreenPointToRay(mousePosition.X, mousePosition.Y, 0)

    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

    lastRaycastOrigin = ray.Origin
    lastRaycastDirection = ray.Direction

    if (raycastResult) then
        local raycastPart = raycastResult.Instance
        local placement = placementsMap[raycastPart]
        if (not placement) then return end
        
        local currentObjModelInfo = unitModelInfoCache[currentObjName]
        local raycastPosition = raycastResult.Position
        local modelCFrame = placement:GetPlacementCFrame(currentObjModelInfo.Bounds, raycastPosition, rotation)

        currentObjModel:SetPrimaryPartCFrame(modelCFrame:ToWorldSpace(currentObjModelInfo.PrimaryPartCenterOffset))
        PointerPart.CFrame = modelCFrame
        RadiusPart.CFrame = modelCFrame

        local touching = Workspace:GetPartsInPart(PointerPart, overlapParams)
        local correctTag = CollectionService:HasTag(raycastPart, currentObjSurfaceType)

        local isClear = (#touching < 1) and correctTag
        PointerPart.Color = isClear and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    end
end

local updateModelRotationFromInput = function(_, inputState: Enum.UserInputState, input: InputObject)
    if (not placementActive) then return end
    if (inputState ~= Enum.UserInputState.Begin) then return end
    
    local sign
    local keyCode = input.KeyCode
    
    if ((keyCode == Enum.KeyCode.R) or (keyCode == Enum.KeyCode.ButtonR1)) then
        sign = 1
    elseif (keyCode == Enum.KeyCode.ButtonL1) then
        sign = -1
    else
        return
    end

    rotation = rotation + (sign * (math.pi / 2))
    updateModel(lastMousePosition)
end

-- We need to return Pass so that it doesn't interfere with player/camera bindings
local updateModelFromInput = function(_, inputState: Enum.UserInputState, input: InputObject): Enum.ContextActionResult?
    if (not placementActive) then return end

    local inputType = input.UserInputType
    local inputPosition = input.Position

    if (inputType == Enum.UserInputType.MouseMovement) then
        if (inputState ~= Enum.UserInputState.Change) then return Enum.ContextActionResult.Pass end
    elseif (inputType == Enum.UserInputType.Touch) then
        if (inputState ~= Enum.UserInputState.Begin) then return Enum.ContextActionResult.Pass end
    elseif (inputType == Enum.UserInputType.Gamepad1) then
        if (inputState ~= Enum.UserInputState.Change) then return Enum.ContextActionResult.Pass end

        inputPosition = UserInputService:GetMouseLocation()
    else
        return Enum.ContextActionResult.Pass
    end

    lastMousePosition = inputPosition
    updateModel(inputPosition, inputType == Enum.UserInputType.Gamepad1)

    return Enum.ContextActionResult.Pass
end

---

local PlacementFlow = {}

PlacementFlow.Started = StartedEvent.Event
PlacementFlow.Stopped = StoppedEvent.Event

PlacementFlow.IsActive = function()
    return placementActive
end

PlacementFlow.Stop = function()
    if (not placementActive) then return end

    ContextActionService:UnbindAction(MOVE_MODEL_ACTION_KEY)
    ContextActionService:UnbindAction(ROTATE_MODEL_ACTION_KEY)
    ContextActionService:UnbindAction(CANCEL_ACTION_KEY)
    ContextActionService:UnbindAction(PLACE_ACTION_KEY)

    local towerUnits = Unit.GetUnits(function(unit)
        return (unit.Type == GameEnum.UnitType.TowerUnit)
    end)

    for i = 1, #towerUnits do
        local unitModel = towerUnits[i].Model
        local boundingPart = unitModel:FindFirstChild("_BoundingPart")
        boundingPart.Transparency = 1
    end
    
    currentObjModel:SetPrimaryPartCFrame(CFrame.new(0, math.huge, 0))
    PointerPart.CFrame = CFrame.new(0, math.huge, 0)
    RadiusPart.CFrame = CFrame.new(0, math.huge, 0)
    
    if (placementUITree) then
        Roact.unmount(placementUITree)
    end

    currentObjName = nil
    currentObjModel = nil
    currentObjSurfaceType = nil
    lastMousePosition = nil
    lastRaycastOrigin = nil
    lastRaycastDirection = nil
    lastUIType = nil
    placementUITree = nil

    placementActive = false
    StoppedEvent:Fire()
end

PlacementFlow.Start = function(unitName: string)
    if (placementActive) then return end
    if (not Unit.DoesUnitExist(unitName)) then return end
    if (Unit.GetUnitType(unitName) ~= GameEnum.UnitType.TowerUnit) then return end

    local unitModelInfo = unitModelInfoCache[unitName]
    local unitModelBounds = unitModelInfo.Bounds

    currentObjName = unitName
    currentObjModel = unitModelInfo.Model
    currentObjSurfaceType = Unit.GetTowerUnitSurfaceType(unitName)
    lastMousePosition = UserInputService:GetMouseLocation()
    lastUIType = userInputTypeUITypeMap[UserInputService:GetLastInputType()] or "MouseAndKeyboard"
    rotation = 0

    local unitAttributes = Unit.GetUnitBaseAttributes(unitName, Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, unitName))
    local towerUnits = Unit.GetUnits(function(unit)
        return (unit.Type == GameEnum.UnitType.TowerUnit)
    end)

    for i = 1, #towerUnits do
        local unitModel = towerUnits[i].Model
        local boundingPart = unitModel:FindFirstChild("_BoundingPart")
        boundingPart.Color = BrickColor.new("Bright red").Color
        boundingPart.Transparency = 0.75
    end
    
    RadiusPart.Size = Vector3.new(unitAttributes.RANGE, unitAttributes.RANGE, unitAttributes.RANGE) * 2
    PointerPart.Size = unitModelBounds

    ContextActionService:BindActionAtPriority(
        MOVE_MODEL_ACTION_KEY,
        updateModelFromInput,
        false,
        Enum.ContextActionPriority.High.Value,
        Enum.UserInputType.MouseMovement,
        Enum.UserInputType.Touch,
        Enum.KeyCode.Thumbstick1,
        Enum.KeyCode.Thumbstick2
    )

    ContextActionService:BindAction(
        ROTATE_MODEL_ACTION_KEY,
        updateModelRotationFromInput,
        false,
        Enum.KeyCode.R,
        Enum.KeyCode.ButtonL1,
        Enum.KeyCode.ButtonR1
    )

    ContextActionService:BindAction(CANCEL_ACTION_KEY, function(_, inputState: Enum.UserInputState, _)
        if (inputState ~= Enum.UserInputState.Begin) then return end

        PlacementFlow.Stop()
    end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)

    ContextActionService:BindAction(PLACE_ACTION_KEY, function(_, inputState: Enum.UserInputState, _)
        if (inputState ~= Enum.UserInputState.Begin) then return end

        placeObject()
    end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonY)

    mountControlGui(lastUIType)
    updateModel(lastMousePosition)
    placementActive = true
    StartedEvent:Fire()
end

---

mountControlGui = function(uiType)
    if (uiType ~= "Touch") then
        placementUITree = Roact.mount(Roact.createElement(ControlInstructions, {
            controls = uiTypeControls[uiType]
        }), PlayerGui, "PlacementFlow.ControlGui")
    else
        local currentObjModelBounds = unitModelInfoCache[currentObjName].Bounds

        placementUITree = Roact.mount(Roact.createElement(UnitPlacementTouchControls, {
            Adornee = currentObjModel,
            StudsOffsetWorldSpace = Vector3.new(0, (currentObjModelBounds.Y / 2) + 1.5, 0),

            onCancel = PlacementFlow.Stop,
            onPlace = placeObject,

            onRotateLeft = function()
                rotation = rotation - (math.pi / 2)
                updateModel(lastMousePosition)
            end,

            onRotateRight = function()
                rotation = rotation + (math.pi / 2)
                updateModel(lastMousePosition)
            end,
        }), PlayerGui, "PlacementFlow.ControlGui")
    end
end

placeObject = function()
    if (not placementActive) then return end

    local cacheObjName, cacheRaycastOrigin, cacheRaycastDirection, cacheRotation = currentObjName, lastRaycastOrigin, lastRaycastDirection, rotation
    
    PlacementFlow.Stop()

    local unitPrice = Shop.GetObjectPlacementPrice(GameEnum.ObjectType.Unit, cacheObjName)
    local playerPoints = PlayerData.GetPlayerCurrencyBalance(LocalPlayer.UserId, GameEnum.CurrencyType.Points)
    if (unitPrice > playerPoints) then return end

    Shop.PurchaseObjectPlacement(LocalPlayer.UserId, GameEnum.ObjectType.Unit, cacheObjName, cacheRaycastOrigin, cacheRaycastDirection, cacheRotation)
end

do
    local terrainParts = CollectionService:GetTagged(GameEnum.SurfaceType.Terrain)
    local elevatedTerrainParts = CollectionService:GetTagged(GameEnum.SurfaceType.ElevatedTerrain)
    local pathParts = CollectionService:GetTagged(GameEnum.SurfaceType.Path)

    for i = 1, #terrainParts do
        surfacePartAdded(terrainParts[i], true)
    end

    for i = 1, #elevatedTerrainParts do
        surfacePartAdded(elevatedTerrainParts[i], true)
    end

    for i = 1, #pathParts do
        surfacePartAdded(pathParts[i], true)
    end

    Placement.Merge(placementsArray)
end

do
    local unitModels = UnitModels:GetChildren()

    for i = 1, #unitModels do
        local unitModel = unitModels[i]
        local unitName = unitModel.Name

        if (Unit.DoesUnitExist(unitName) and (Unit.GetUnitType(unitName) == GameEnum.UnitType.TowerUnit)) then
            local unitModelClone = unitModel:Clone()
            local unitModelCloneDescendants = unitModelClone:GetDescendants()

            for j = 1, #unitModelCloneDescendants do
                local descendant = unitModelCloneDescendants[j]

                if (descendant:IsA("BasePart")) then
                    descendant.CastShadow = false
                    PhysicsService:SetPartCollisionGroup(descendant, GameEnum.CollisionGroup.Units)
                end
            end

            unitModelClone.DescendantAdded:Connect(function(descendant)
                if (descendant:IsA("BasePart")) then
                    descendant.CastShadow = false
                    PhysicsService:SetPartCollisionGroup(descendant, GameEnum.CollisionGroup.Units)
                end
            end)

            local unitModelCloneOrientation, unitModelCloneBounds = unitModelClone:GetBoundingBox()
            local unitModelClonePrimaryPart = unitModelClone.PrimaryPart
            local unitModelClonePrimaryPartCFrame = unitModelClonePrimaryPart.CFrame

            unitModelClone:SetPrimaryPartCFrame(CFrame.new(0, math.huge, 0))
            unitModelClonePrimaryPart.Anchored = true
            unitModelClone.Parent = CurrentCamera

            unitModelInfoCache[unitName] = {
                Model = unitModelClone,
                Bounds = unitModelCloneBounds,
                PrimaryPartCenterOffset = unitModelCloneOrientation:ToObjectSpace(unitModelClonePrimaryPartCFrame)
            }
        end
    end
end

UserInputService.LastInputTypeChanged:Connect(function(lastInputType: Enum.UserInputType)
    if (not placementActive) then return end

    local uiType = userInputTypeUITypeMap[lastInputType]
    if (not uiType) then return end
    if (uiType == lastUIType) then return end

    if (((uiType ~= "Touch") and (lastUIType == "Touch")) or ((uiType == "Touch") and (lastUIType ~= "Touch"))) then
        Roact.unmount(placementUITree)

        mountControlGui(uiType)
    else
        Roact.update(placementUITree, Roact.createElement(ControlInstructions, {
            controls = uiTypeControls[uiType]
        }))
    end

    lastUIType = uiType
end)

Unit.UnitAdded:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return end

    local unitModel = unit.Model
    local boundingPart = unitModel:WaitForChild("_BoundingPart")

    table.insert(overlapParamsFilter, boundingPart)
    overlapParams.FilterDescendantsInstances = overlapParamsFilter

    if (placementActive) then
        boundingPart.Color = BrickColor.new("Bright red").Color
        boundingPart.Transparency = 0.75
    end
end)

Unit.UnitRemoving:Connect(function(unitId: string)
    local unit = Unit.fromId(unitId)
    local unitModel = unit.Model
    local boundingPart = unitModel:FindFirstChild("_BoundingPart")

    local boundingPartIndex = table.find(overlapParamsFilter, boundingPart)
    if (not boundingPartIndex) then return end

    table.remove(overlapParamsFilter, boundingPartIndex)
    overlapParams.FilterDescendantsInstances = overlapParamsFilter
end)

CollectionService:GetInstanceAddedSignal(GameEnum.SurfaceType.Terrain):Connect(surfacePartAdded)
CollectionService:GetInstanceAddedSignal(GameEnum.SurfaceType.ElevatedTerrain):Connect(surfacePartAdded)
CollectionService:GetInstanceRemovedSignal(GameEnum.SurfaceType.Terrain):Connect(surfacePartRemoved)
CollectionService:GetInstanceRemovedSignal(GameEnum.SurfaceType.ElevatedTerrain):Connect(surfacePartRemoved)
CollectionService:GetInstanceRemovedSignal(GameEnum.SurfaceType.Path):Connect(surfacePartRemoved)
CollectionService:GetInstanceRemovedSignal(GameEnum.SurfaceType.Path):Connect(surfacePartRemoved)

PointerPart.Parent = CurrentCamera
RadiusPart.Parent = CurrentCamera

return PlacementFlow