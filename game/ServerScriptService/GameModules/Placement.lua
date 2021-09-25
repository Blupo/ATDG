local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

---

local UnitModels = ReplicatedStorage:FindFirstChild("UnitModels")
local World = Workspace:WaitForChild("World")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local PlacementModule = require(SharedModules:FindFirstChild("Placement"))

local GameModules = script.Parent
local Unit = require(GameModules:FindFirstChild("Unit"))

---

local PLACEMENT_LIMITS = {
	["*"] = 30,
}

local placementsArray = {}
local placementsMap = {}

local overlapParamsFilter = {World}
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
overlapParams.FilterDescendantsInstances = overlapParamsFilter

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = {World}

local surfacePartAdded = function(surfacePart, doNotRefreshImmediately)
    local newPlacement = PlacementModule.new(surfacePart)

    placementsMap[surfacePart] = newPlacement
    table.insert(placementsArray, newPlacement)

    if (not doNotRefreshImmediately) then
        PlacementModule.Merge(placementsArray)
    end
end

local surfacePartRemoved = function(surfacePart)
    local surfacePartIndex = table.find(placementsArray, surfacePart)
    if (not surfacePartIndex) then return end

    placementsMap[surfacePart] = nil
    table.remove(placementsArray, surfacePartIndex)
    PlacementModule.Merge(placementsArray)
end

---

local Placement = {}

Placement.CanPlace = function(owner: number, objType: string, objName: string, rayOrigin: Vector3, rayDirection: Vector3, rotation: number)
	-- TODO: Check limits

	rayDirection = rayDirection.Unit

	if (objType ~= GameEnum.ObjectType.Unit) then return end
	if (not Unit.DoesUnitExist(objName)) then return end
	if (Unit.GetUnitType(objName) ~= GameEnum.UnitType.TowerUnit) then return end

	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection * 1000, raycastParams)
	if (not raycastResult) then return end
	
	local unitSurfaceType = Unit.GetTowerUnitSurfaceType(objName)
	local raycastPart = raycastResult.Instance
	if (not CollectionService:HasTag(raycastPart, unitSurfaceType)) then return end

	local placement = placementsMap[raycastPart]
	if (not placement) then return end

	local objModel = UnitModels:FindFirstChild(objName)
	local _, objModelBounds = objModel:GetBoundingBox()
	local modelCFrame = placement:GetPlacementCFrame(objModel, raycastResult.Position, rotation)

	local collisionPart = Instance.new("Part")
	collisionPart.CFrame = modelCFrame
	collisionPart.Size = objModelBounds
	collisionPart.Transparency = 1
	collisionPart.CastShadow = false
	collisionPart.CanCollide = false
	collisionPart.CanTouch = false
	collisionPart.Anchored = true
	collisionPart.Parent = Workspace

	local touching = Workspace:GetPartsInPart(collisionPart, overlapParams)
	collisionPart:Destroy()

	if (#touching > 0) then return end
	return modelCFrame
end

Placement.GetPlacementLimits = function()
	
end

Placement.PlaceObject = function(owner: number, objType: string, objName: string, rayOrigin: Vector3, rayDirection: Vector3, rotation: number)
	local modelCFrame = Placement.CanPlace(owner, objType, objName, rayOrigin, rayDirection, rotation)
	if (not modelCFrame) then return end

	local newUnit = Unit.new(objName, owner)
	local newUnitModel = newUnit.Model
	local boundingPart = newUnitModel:FindFirstChild("_BoundingPart")
	
	boundingPart.Anchored = true
	boundingPart.CFrame = modelCFrame
	newUnitModel.Parent = Workspace
end

---

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

    PlacementModule.Merge(placementsArray)
end

Unit.UnitAdded:Connect(function(unitId: string)
	local unit = Unit.fromId(unitId)
	if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return end

	local unitModel = unit.Model
	local boundingPart = unitModel:FindFirstChild("_BoundingPart")

	table.insert(overlapParamsFilter, boundingPart)
	overlapParams.FilterDescendantsInstances = overlapParamsFilter
end)

Unit.UnitRemoving:Connect(function(unitId: string)
	local unit = Unit.fromId(unitId)
	if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return end

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

return Placement