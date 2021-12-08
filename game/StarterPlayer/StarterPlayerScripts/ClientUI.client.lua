local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local ClientScripts = PlayerScripts:WaitForChild("ClientScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local GameServerUI = GameUIModules:WaitForChild("GameServerUI")
local LobbyServerUI = GameUIModules:WaitForChild("LobbyServerUI")
local LoadingUI = require(GameUIModules:WaitForChild("LoadingUI"))
local Roact = require(GameUIModules:WaitForChild("Roact"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local Notifications = require(PlayerModules:WaitForChild("Notifications"))

local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")

---

local clientScripts = {
    [GameEnum.ServerType.Game] = {
        TowerUnitUI = true,
        UnitAnimator = true,
        UnitBillboards = true,

        CoreGuiDisabler = true,
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
        clientUI = require(LobbyServerUI)
    elseif (serverType == GameEnum.ServerType.Game) then
        clientUI = require(GameServerUI)
    end

    Roact.update(loadingUI, Roact.createElement(LoadingUI, {
        enabled = false
    }))

    Roact.mount(Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    }, {
        Roact.createElement(clientUI)
    }), PlayerGui, "ClientUI")

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
    Notifications.SendCoreNotification(
        "Game Error",
        "There was a problem initialising your game. You are being teleported back to the lobby.",
        "Game"
    )
end)