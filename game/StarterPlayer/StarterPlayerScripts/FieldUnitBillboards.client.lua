local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---

local PlayerScripts = script.Parent

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GameUI = PlayerScripts:WaitForChild("GameUI")
local Roact = require(GameUI:WaitForChild("Roact"))
local FieldUnitStatusBillboard = require(GameUI:WaitForChild("FieldUnitStatusBillboard"))

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

---

local unitBillboardTrees = {}

Unit.UnitAdded:Connect(function(unitId)
    local unit = Unit.fromId(unitId)
    if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return end

    local unitModel = unit.Model
    local templateUnitModel = UnitModels:FindFirstChild(unit.Name)
    
    -- todo: this is probably a hack, please update later
    while (#unitModel:GetDescendants() < #templateUnitModel:GetDescendants()) do
        RunService.Heartbeat:Wait()
    end

    local _, boundingBoxSize = unitModel:GetBoundingBox()

    unitBillboardTrees[unitId] = Roact.mount(Roact.createElement(FieldUnitStatusBillboard, {
        unitId = unitId,

        Adornee = unitModel.PrimaryPart,
        Size = UDim2.new(2.5, 0, 1, 0),
        StudsOffsetWorldSpace = Vector3.new(0, ((boundingBoxSize.Y + 1) / 2) + 0.5, 0)
    }), PlayerGui, unitId .. "_Billboard")
end)

Unit.UnitRemoving:Connect(function(unitId)
    local billboardTree = unitBillboardTrees[unitId]
    if (not billboardTree) then return end

    Roact.unmount(billboardTree)
    unitBillboardTrees[unitId] = nil
end)