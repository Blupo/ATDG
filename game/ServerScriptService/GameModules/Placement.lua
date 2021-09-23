local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

---

local UnitModels = ReplicatedStorage:FindFirstChild("UnitModels")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local MakeActionResult = require(SharedModules:FindFirstChild("MakeActionResult"))

local GameModules = script.Parent
local Unit = require(GameModules:FindFirstChild("Unit"))

---

local PLACEMENT_LIMITS = {
	["*"] = 30,
}

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = {}
raycastParams.IgnoreWater = true

local getXZPlaneCorners = function(cframe: CFrame, size: Vector3): {Vector2}
	local corners = {
		cframe:ToWorldSpace(CFrame.new(-size.X / 2, 0, -size.Z / 2)).Position,
		cframe:ToWorldSpace(CFrame.new( size.X / 2, 0, -size.Z / 2)).Position,
		cframe:ToWorldSpace(CFrame.new( size.X / 2, 0,  size.Z / 2)).Position,
		cframe:ToWorldSpace(CFrame.new(-size.X / 2, 0,  size.Z / 2)).Position,
	}

	return {
		Vector2.new(corners[1].X, corners[1].Z),
		Vector2.new(corners[2].X, corners[2].Z),
		Vector2.new(corners[3].X, corners[3].Z),
		Vector2.new(corners[4].X, corners[4].Z),
	}
end

local getHeightPoints = function(cframe: CFrame, size: Vector3): {number}
	return { cframe.Y + (size.Y / 2), cframe.Y - (size.Y / 2) }
end

local isEnclosed = function(part1CFrame: CFrame, part1Size: Vector3, part2CFrame: CFrame, part2Size: Vector3): boolean
	local part1Corners, part2Corners = getXZPlaneCorners(part1CFrame, part1Size), getXZPlaneCorners(part2CFrame, part2Size)

	local pointA, pointB, pointD = part2Corners[1], part2Corners[2], part2Corners[4]
	local vectorAB, vectorAD = pointB - pointA, pointD - pointA
	local abDotAB, adDotAD = vectorAB:Dot(vectorAB), vectorAD:Dot(vectorAD)

	for i = 1, #part1Corners do
		local pointP = part1Corners[i]
		local vectorPA = pointP - pointA

		local paDotAB = vectorPA:Dot(vectorAB)
		local paDotAD = vectorPA:Dot(vectorAD)

		if (
			(paDotAB <= 0) or
				(paDotAD <= 0) or
				(paDotAB >= abDotAB) or
				(paDotAD >= adDotAD)
			) then
			return false
		end
	end

	return true
end

local getAxis = function(corners1: {Vector2}, corners2: {Vector2}): {Vector2}
	return {
		(corners1[2] - corners1[1]).Unit,
		(corners1[4] - corners1[1]).Unit,
		(corners2[2] - corners2[1]).Unit,
		(corners2[4] - corners2[1]).Unit,
	}
end

local doesCollide = function(part1CFrame: CFrame, part1Size: Vector3, part2CFrame: CFrame, part2Size: Vector3): boolean
	local part1Corners, part2Corners = getXZPlaneCorners(part1CFrame, part1Size), getXZPlaneCorners(part2CFrame, part2Size)
	local axis = getAxis(part1Corners, part2Corners)

	for i = 1, #axis do
		local scalars1, scalars2 = {}, {}

		for k = 1, 4 do
			table.insert(scalars1, axis[i]:Dot(part1Corners[k]))
			table.insert(scalars2, axis[i]:Dot(part2Corners[k]))
		end

		local scalars1Min, scalars1Max = math.min(table.unpack(scalars1)), math.max(table.unpack(scalars1))
		local scalars2Min, scalars2Max = math.min(table.unpack(scalars2)), math.max(table.unpack(scalars2))

		if ((scalars1Min >= scalars2Max) or (scalars1Max <= scalars2Min)) then return false end
	end

	return true
end

---

local Placement = {}

Placement.CanPlace = function(owner: number, objType: string, objName: string, position: Vector3, rotation: number)
	-- TODO
	
	return MakeActionResult()
end

Placement.GetPlacementLimits = function()
	
end

Placement.PlaceObject = function(owner: number, objType: string, objName: string, position: Vector3, rotation: number)
	--[[
	local placementResult = Placement.CanPlace(owner, objType, objName, position, rotation)
	
	if (not placementResult.Success) then
		print(placementResult.FailureReason)
		return
	end
	
	local objModel

	if (objType == GameEnum.ObjectType.Unit) then
		local newUnit = Unit.new(objName, owner)
		
		objModel = newUnit.Model
	end
	
	local primaryPart = objModel.PrimaryPart
	local boundingBoxCFrame, boundingBoxSize = objModel:GetBoundingBox()
	local primaryPartCenterOffset = primaryPart.Position - boundingBoxCFrame.Position
	local primaryPartHeightOffset = (boundingBoxSize.Y / 2) + primaryPartCenterOffset.Y
	
	objModel:SetPrimaryPartCFrame(CFrame.new(position)
		:ToWorldSpace(CFrame.Angles(0, rotation + (math.pi / 2), 0) * CFrame.new(0, primaryPartHeightOffset, 0) )
	)
	
	objModel.Parent = Workspace
	--]]
end

---

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

return Placement