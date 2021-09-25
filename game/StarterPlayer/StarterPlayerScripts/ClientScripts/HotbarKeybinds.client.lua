-- todo: need a way to know which hotbar is being used when multiple hotbars are added

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))

---

local KEYS = { "One", "Two", "Three", "Four", "Five" }

local hotbar = PlayerData.GetPlayerHotbar(LocalPlayer.UserId, GameEnum.UnitType.TowerUnit)

local bindHotbarKeys = function()
    for i = 1, #KEYS do
        ContextActionService:BindAction("Hotbar " .. i, function(_, inputState)
            if (inputState ~= Enum.UserInputState.Begin) then return end

            PlacementFlow.Start(hotbar[i])
        end, false, Enum.KeyCode[KEYS[i]])
    end
end

local unbindHotbarKeys = function()
    for i = 1, #KEYS do
        ContextActionService:UnbindAction("Hotbar " .. i)
    end
end

---

PlacementFlow.Started:Connect(unbindHotbarKeys)
PlacementFlow.Stopped:Connect(bindHotbarKeys)

bindHotbarKeys()