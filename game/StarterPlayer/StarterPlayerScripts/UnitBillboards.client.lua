local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
--local UserInputService = game:GetService("UserInputService")
--local Workspace = game:GetService("Workspace")

---

local PlayerScripts = script.Parent

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GameUI = PlayerScripts:WaitForChild("GameUI")
local Roact = require(GameUI:WaitForChild("Roact"))
local FieldUnitBillboard = require(GameUI:WaitForChild("FieldUnitBillboard"))

--local CurrentCamera = Workspace.CurrentCamera
local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

---

--[[
    This version is for having the billboard display for all Units
]]

local unitBillboardTrees = {}

Unit.UnitAdded:Connect(function(unitId)
    local unit = Unit.fromId(unitId)
    if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return end

    local unitModel = unit.Model
    local templateUnitModel = UnitModels:FindFirstChild(unit.Name)
    
    -- todo: this is probably a hack, pls update later
    while (#unitModel:GetDescendants() < #templateUnitModel:GetDescendants()) do
        RunService.Heartbeat:Wait()
    end

    local _, boundingBoxSize = unitModel:GetBoundingBox()

    unitBillboardTrees[unitId] = Roact.mount(Roact.createElement(FieldUnitBillboard, {
        unitId = unitId,

        Adornee = unitModel.PrimaryPart,
        Size = UDim2.new(2.5, 0, 1, 0),
        StudsOffsetWorldSpace = Vector3.new(0, boundingBoxSize.Y, 0)
    }), PlayerGui, unitId .. "_Billboard")
end)

Unit.UnitRemoving:Connect(function(unitId)
    local billboardTree = unitBillboardTrees[unitId]
    if (not billboardTree) then return end

    Roact.unmount(billboardTree)
    unitBillboardTrees[unitId] = nil
end)

--[[
    This version is for hovering over Field Units
]]

--[[
local MOUSE_POLL_TIME = 1/15

local fieldUnitModels = {}

local lastUnitId
local billboardGuiTree

local wait = function(t)
    local elapsed = 0

    while (elapsed < t) do
        elapsed = elapsed + RunService.Heartbeat:Wait()
    end

    return elapsed
end


local dismountBillboardGui = function()
    if (not billboardGuiTree) then return end

    Roact.unmount(billboardGuiTree)
    billboardGuiTree = nil
end

local mountBillboardGui = function(x, y)
    local ray = CurrentCamera:ViewportPointToRay(x, y)
    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 500)

    if (not raycastResult) then
        lastUnitId = nil
        dismountBillboardGui()
        return
    end

    local raycastPart = raycastResult.Instance

    if (not raycastPart:IsA("BasePart")) then
        lastUnitId = nil
        dismountBillboardGui()
        return
    end

    local id
    local model

    for unitId, unitModel in pairs(fieldUnitModels) do
        if (raycastPart:IsDescendantOf(unitModel)) then
            id = unitId
            model = unitModel
            break
        end
    end

    if (not id) then
        lastUnitId = nil
        dismountBillboardGui()
        return
    end

    if (id == lastUnitId) then return end
    lastUnitId = id
    dismountBillboardGui()

    local _, boundingBoxSize = model:GetBoundingBox()
    
    billboardGuiTree = Roact.mount(Roact.createElement(FieldUnitBillboard, {
        unitId = id,

        Adornee = model.PrimaryPart,
        Size = UDim2.new(5, 0, 2, 0),
        StudsOffsetWorldSpace = Vector3.new(0, boundingBoxSize.Y, 0)
    }), PlayerGui, "FieldUnitBillboard")
end

---

Unit.UnitAdded:Connect(function(unitId)
    local unit = Unit.fromId(unitId)
    if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return end

    fieldUnitModels[unitId] = unit.Model
end)

Unit.UnitRemoving:Connect(function(unitId)
    fieldUnitModels[unitId] = nil
end)

while true do
    local mousePosition = UserInputService:GetMouseLocation()
    mountBillboardGui(mousePosition.X, mousePosition.Y)
    
    wait(MOUSE_POLL_TIME)
end
--]]