-- TODO

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

---

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Placement = require(GameModules:WaitForChild("Placement"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local Placement = require(SharedModules:WaitForChild("Placement"))

local CurrentCamera = Workspace.CurrentCamera
local World = Workspace:WaitForChild("World")

local StartedEvent = Instance.new("BindableEvent")
local StoppedEvent = Instance.new("BindableEvent")

local PointerPart = Instance.new("Part")
PointerPart.CFrame = CFrame.new(0, math.huge, 0)
PointerPart.Size = Vector3.new(0, 0, 0)
PointerPart.Transparency = 0.5
PointerPart.CastShadow = false
PointerPart.CanCollide = false
PointerPart.CanTouch = false
PointerPart.Anchored = true
PointerPart.Material = Enum.Material.SmoothPlastic
PointerPart.TopSurface = Enum.SurfaceType.Smooth
PointerPart.BottomSurface = Enum.SurfaceType.Smooth
PointerPart.LeftSurface = Enum.SurfaceType.Smooth
PointerPart.RightSurface = Enum.SurfaceType.Smooth

local RadiusPart = Instance.new("Part")
RadiusPart.CFrame = CFrame.new(0, math.huge, 0)
RadiusPart.Size = Vector3.new(0, 0, 0)
RadiusPart.Transparency = -1
RadiusPart.CastShadow = false
RadiusPart.CanCollide = false
RadiusPart.CanTouch = false
RadiusPart.Anchored = true
RadiusPart.Material = Enum.Material.ForceField
RadiusPart.Shape = Enum.PartType.Ball
RadiusPart.Color = Style.Colors.RANGEAttributeIconColor

---

local MOVE_MODEL_ACTION_KEY = "PlacementFlow.MovePlacementModel"
local ROTATE_MODEL_ACTION_KEY = "PlacementFlow.RotatePlacementModel"

local placementsArray = {}
local placementsMap = {}

local unitModelsCache = {}
local unitPlacementBoundsIndicatorPartsCache = {}

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
overlapParams.FilterDescendantsInstances = {World}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = {World}

---

local PlacementFlow = {}

PlacementFlow.Started = StartedEvent.Event
PlacementFlow.Stopped = StoppedEvent.Event

PlacementFlow.Start = function(objType: string, objName: string)

end

PlacementFlow.Stop = function()
    ContextActionService:UnbindAction(MOVE_MODEL_ACTION_KEY)
    ContextActionService:UnbindAction(ROTATE_MODEL_ACTION_KEY)
end

---

Unit.UnitAdded:Connect(function(unitId: string)

end)

Unit.UnitRemoving:Connect(function(unitId: string)

end)

PointerPart.Parent = CurrentCamera
RadiusPart.Parent = CurrentCamera

return PlacementFlow