-- handles the placement flow

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

---

local GameModules = script.Parent
local Placement = require(GameModules:WaitForChild("Placement"))
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")
-- local RoadblockModels = ReplicatedStorage:WaitForChild("RoadblockModels")

local StartedEvent = Instance.new("BindableEvent")
local StoppedEvent = Instance.new("BindableEvent")

local CurrentCamera = Workspace.CurrentCamera

local PointerPart = Instance.new("Part")
PointerPart.CFrame = CFrame.new(0, math.huge, 0)
PointerPart.Size = Vector3.new(0, 0, 0)
PointerPart.Transparency = 0.5
PointerPart.CastShadow = false
PointerPart.CanCollide = false
PointerPart.CanTouch = false
PointerPart.Anchored = true
PointerPart.TopSurface = Enum.SurfaceType.Smooth
PointerPart.BottomSurface = Enum.SurfaceType.Smooth
PointerPart.LeftSurface = Enum.SurfaceType.Smooth
PointerPart.RightSurface = Enum.SurfaceType.Smooth

local RadiusPart = Instance.new("Part")
RadiusPart.CFrame = CFrame.new(0, math.huge, 0)
RadiusPart.Size = Vector3.new(0, 0, 0)
RadiusPart.Transparency = 0.5
RadiusPart.CastShadow = false
RadiusPart.CanCollide = false
RadiusPart.CanTouch = false
RadiusPart.Anchored = true
RadiusPart.Material = Enum.Material.ForceField
RadiusPart.Shape = Enum.PartType.Ball

---

local mouseMovementEvent
local rotateEvent
local activatedEvent

local objModel
local objRotation = 0

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = {}
raycastParams.IgnoreWater = true

---

local PlacementFlow = {}

PlacementFlow.Started = StartedEvent.Event
PlacementFlow.Stopped = StoppedEvent.Event

PlacementFlow.Start = function(objType: string, objName: string)
    if (objType == GameEnum.ObjectType.Unit) then
        if (not Unit.DoesUnitExist(objName)) then return end

        objModel = UnitModels:FindFirstChild(objName):Clone()
    else
        -- todo: roadblocks
        return
    end

    local PlacementArea = objModel:FindFirstChild("PlacementArea")

    objModel.PrimaryPart.Anchored = true
	objModel:SetPrimaryPartCFrame(CFrame.new(0, math.huge, 0))
    PointerPart.Size = Vector3.new(PlacementArea.Size.X, 0, PlacementArea.Size.Z)

    for _, obj in pairs(objModel:GetDescendants()) do
        if (obj:IsA("BasePart")) then
            obj.CanCollide = false
            obj.CanTouch = false
        end
    end

    mouseMovementEvent = UserInputService.InputChanged:Connect(function(input)
		if (input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
		if (not (objType and objName)) then return end

		local inputPosition = input.Position
		local ray = CurrentCamera:ScreenPointToRay(inputPosition.X, inputPosition.Y, 0)
		local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 5000, raycastParams)
		local raycastPosition
		
		if (raycastResult) then
			raycastPosition = raycastResult.Position
		else
			PointerPart.CFrame = CFrame.new(0, math.huge, 0)
			RadiusPart.CFrame = CFrame.new(0, math.huge, 0)
			objModel:SetPrimaryPartCFrame(CFrame.new(0, math.huge, 0))
			return
		end
		
		local primaryPart = objModel.PrimaryPart
		local boundingBoxCFrame, boundingBoxSize = objModel:GetBoundingBox()
		local primaryPartCenterOffset = primaryPart.Position - boundingBoxCFrame.Position
		local primaryPartHeightOffset = (boundingBoxSize.Y / 2) + primaryPartCenterOffset.Y
		
		local placementResult = Placement.CanPlace(objType, objName, raycastPosition, objRotation)
		
		objModel:SetPrimaryPartCFrame(CFrame.lookAt(raycastPosition, raycastPosition + raycastResult.Normal)
			:ToWorldSpace(CFrame.Angles(-math.pi / 2, objRotation, 0))
			:ToWorldSpace(CFrame.new(0, primaryPartHeightOffset, 0))
		)
		
		PointerPart.Color = placementResult.CanPlace and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		PointerPart.CFrame = CFrame.lookAt(raycastPosition, raycastPosition + raycastResult.Normal):ToWorldSpace(CFrame.Angles(-math.pi / 2, 0, 0))
		RadiusPart.CFrame = CFrame.new(raycastPosition)
	end)
	
	rotateEvent = UserInputService.InputBegan:Connect(function(input)
		if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end
		if (input.KeyCode ~= Enum.KeyCode.R) then return end
		if (not objModel) then return end
		
		objRotation = (objRotation + (math.pi / 2)) % (2 * math.pi)
		objModel:SetPrimaryPartCFrame(objModel:GetPrimaryPartCFrame():ToWorldSpace(CFrame.Angles(0, math.pi / 2, 0)))
	end)
	
	activatedEvent = UserInputService.InputBegan:Connect(function(input)
		if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
		if (not (objType and objName)) then return end
		
		local inputPosition = input.Position
		local ray = CurrentCamera:ScreenPointToRay(inputPosition.X, inputPosition.Y, 0)
		local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 5000, raycastParams)
		if (not raycastResult) then return end
		
		Placement.PlaceObject(objType, objName, raycastResult.Position, objRotation)
	end)

    StartedEvent:Fire()
end

PlacementFlow.Stop = function()
    objRotation = 0

    PointerPart.CFrame = CFrame.new(0, math.huge, 0)
	RadiusPart.CFrame = CFrame.new(0, math.huge, 0)
	objModel:SetPrimaryPartCFrame(CFrame.new(0, math.huge, 0))

	if (mouseMovementEvent) then
		mouseMovementEvent:Disconnect()
		mouseMovementEvent = nil
	end
	
	if (rotateEvent) then
		rotateEvent:Disconnect()
		rotateEvent = nil
	end
	
	if (activatedEvent) then
		activatedEvent:Disconnect()
		activatedEvent = nil
	end

    StoppedEvent:Fire()
end

---

PointerPart.Parent = CurrentCamera
RadiusPart.Parent = CurrentCamera

do
	local world = Workspace:FindFirstChild("World")

	if (world) then
		raycastParams.FilterDescendantsInstances = {world}
	end
end

Workspace.ChildAdded:Connect(function(child)
	if (child.Name ~= "World") then return end

	raycastParams.FilterDescendantsInstances = {child}
end)

Workspace.ChildRemoved:Connect(function(child)
	if (child.Name ~= "World") then return end

	raycastParams.FilterDescendantsInstances = {}
end)

return PlacementFlow