-- todo: support touch

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

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
local TowerUnitUpgrader = require(GameUI:WaitForChild("TowerUnitUpgrader"))

local CurrentCamera = Workspace.CurrentCamera

---

local CLICK_TIME = 0.5

local lastUnitId
local lastMouseDownTime = 0

local towerUnitModels = {}
local guiTree

local dismountUpgradeGui = function()
    if (not guiTree) then return end

    Roact.unmount(guiTree)
    guiTree = nil
end

local mountUpgradeGui = function(x, y)
    local ray = CurrentCamera:ViewportPointToRay(x, y)
    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 500)

    if (not raycastResult) then
        lastUnitId = nil
        dismountUpgradeGui()
        return
    end

    local raycastPart = raycastResult.Instance

    if (not raycastPart:IsA("BasePart")) then
        lastUnitId = nil
        dismountUpgradeGui()
        return
    end

    local unitId

    for id, model in pairs(towerUnitModels) do
        if (raycastPart:IsDescendantOf(model)) then
            unitId = id
            break
        end
    end

    if (not unitId) then
        lastUnitId = nil
        dismountUpgradeGui()
        return
    end

    if (lastUnitId == unitId) then return end
    lastUnitId = unitId

    dismountUpgradeGui()
    guiTree = Roact.mount(Roact.createElement(TowerUnitUpgrader, {
        unitId = unitId,
    }), PlayerGui, unitId .. "_Billboard")
end

---

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if (gameProcessedEvent) then return end
    if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end

    lastMouseDownTime = os.clock()
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if (gameProcessedEvent) then return end
    if (input.UserInputType ~= Enum.UserInputType.MouseButton1) then return end

    local now = os.clock()
    if ((now - lastMouseDownTime) > CLICK_TIME) then return end
    
    local inputPosition = input.Position
    mountUpgradeGui(inputPosition.X, inputPosition.Y)
end)

Unit.UnitAdded:Connect(function(unitId)
    local unit = Unit.fromId(unitId)
    if (unit.Type ~= GameEnum.UnitType.TowerUnit) then return end
    if (unit.Owner ~= LocalPlayer.UserId) then return end

    towerUnitModels[unitId] = unit.Model
end)

Unit.UnitRemoving:Connect(function(unitId)
    if (unitId == lastUnitId) then
        dismountUpgradeGui()
        lastUnitId = nil
    end

    towerUnitModels[unitId] = nil
end)