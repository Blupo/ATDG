-- handles the placement flow
-- todo: cancel event
-- todo: should all PlacementAreas show?

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

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local CurrentCamera = Workspace.CurrentCamera

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
local cancelEvent
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

		if (Unit.GetUnitType(objName) == GameEnum.UnitType.TowerUnit) then
			local baseAttributes = Unit.GetUnitBaseAttributes(objName, Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, objName))

			RadiusPart.Size = Vector3.new(baseAttributes.RANGE, baseAttributes.RANGE, baseAttributes.RANGE) * 2
		else
			RadiusPart.Size = Vector3.new(0, 0, 0)
		end

        objModel = UnitModels:FindFirstChild(objName):Clone()
    else
        return
    end

    mouseMovementEvent = UserInputService.InputChanged:Connect(function(input)
		if (input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end

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
			:ToWorldSpace(CFrame.Angles(-math.pi / 2, objRotation, 0) * CFrame.new(0, primaryPartHeightOffset, 0))
		)
		
		PointerPart.Color = placementResult.Success and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		PointerPart.CFrame = CFrame.lookAt(raycastPosition, raycastPosition + raycastResult.Normal):ToWorldSpace(CFrame.Angles(-math.pi / 2, 0, 0))
		RadiusPart.CFrame = CFrame.new(raycastPosition)
	end)
	
	-- todo: replace
	rotateEvent = UserInputService.InputBegan:Connect(function(input)
		if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end
		if (input.KeyCode ~= Enum.KeyCode.R) then return end
		
		objRotation = (objRotation + (math.pi / 2)) % (2 * math.pi)
		objModel:SetPrimaryPartCFrame(objModel:GetPrimaryPartCFrame():ToWorldSpace(CFrame.Angles(0, math.pi / 2, 0)))
	end)
	
	-- todo: replace
	cancelEvent = UserInputService.InputBegan:Connect(function(input)
		if (input.UserInputType ~= Enum.UserInputType.Keyboard) then return end
		if (input.KeyCode ~= Enum.KeyCode.Q) then return end

		PlacementFlow.Stop()
	end)

	activatedEvent = UserInputService.InputBegan:Connect(function(input)
		if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end
		
		local inputPosition = input.Position
		local ray = CurrentCamera:ScreenPointToRay(inputPosition.X, inputPosition.Y, 0)
		local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 5000, raycastParams)
		if (not raycastResult) then return end
		if (not Placement.CanPlace(objType, objName, raycastResult.Position, objRotation).Success) then return end

		local cacheObjRotation = objRotation -- PlacementFlow.Stop clears objRotation

		PlacementFlow.Stop()
		Shop.PurchaseObjectPlacement(LocalPlayer.UserId, objType, objName, raycastResult.Position, cacheObjRotation)
	end)

	local PlacementArea = objModel:FindFirstChild("PlacementArea")

    for _, obj in pairs(objModel:GetDescendants()) do
        if (obj:IsA("BasePart")) then
            obj.CanCollide = false
            obj.CanTouch = false
        end
    end

	PointerPart.Size = Vector3.new(PlacementArea.Size.X, 0, PlacementArea.Size.Z)
	objModel.PrimaryPart.Anchored = true
	objModel.Parent = CurrentCamera

    StartedEvent:Fire()
end

PlacementFlow.Stop = function()
	objModel:Destroy()
	objModel = nil
    objRotation = 0

    PointerPart.CFrame = CFrame.new(0, math.huge, 0)
	RadiusPart.CFrame = CFrame.new(0, math.huge, 0)

	if (mouseMovementEvent) then
		mouseMovementEvent:Disconnect()
		mouseMovementEvent = nil
	end
	
	if (rotateEvent) then
		rotateEvent:Disconnect()
		rotateEvent = nil
	end

	if (cancelEvent) then
		cancelEvent:Disconnect()
		cancelEvent = nil
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