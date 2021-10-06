local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local ClientScripts = PlayerScripts:WaitForChild("ClientScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local GameUI = GameUIModules:WaitForChild("GameUI")
local LobbyUI = GameUIModules:WaitForChild("LobbyUI")
local LoadingUI = require(GameUIModules:WaitForChild("LoadingUI"))
local Roact = require(GameUIModules:WaitForChild("Roact"))

local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")

---

local clientScripts = {
    [GameEnum.ServerType.Game] = {
        HotbarKeybinds = true,
        TowerUnitUI = true,
        UnitAnimator = true,
        UnitBillboards = true,

        CoreGuiDisabler = true,
        TEMP_NonCollider = true,
    },

    [GameEnum.ServerType.Lobby] = {
        
    },
}

local initClientScripts = function(serverType: string)
    local scripts = clientScripts[serverType]
    local clientUI

    local loadingUI = Roact.mount(Roact.createElement(LoadingUI, {
        enabled = true,
    }), PlayerGui, "LoadingGui")

    for scriptName in pairs(scripts) do
        ClientScripts:WaitForChild(scriptName).Disabled = false
    end

    if (serverType == GameEnum.ServerType.Lobby) then
        clientUI = require(LobbyUI)
    elseif (serverType == GameEnum.ServerType.Game) then
        clientUI = require(GameUI)
    end

    Roact.update(loadingUI, Roact.createElement(LoadingUI, {
        enabled = false
    }))

    Roact.mount(Roact.createElement(clientUI), PlayerGui, "ClientUI")

    task.delay(5, function()
        Roact.unmount(loadingUI)
        loadingUI = nil
    end)
end

---

local serverType = ServerMaster.GetServerType()

if (not serverType) then
    ServerMaster.ServerInitialised:Connect(initClientScripts)
else
    initClientScripts(serverType)
end

ServerMaster.GameInitFailureNotification:Connect(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Game Error",
        Text = "There was a problem initialising your game. You are being teleported back to the lobby.",
        Icon = "rbxassetid://6868396182",
    })
end)