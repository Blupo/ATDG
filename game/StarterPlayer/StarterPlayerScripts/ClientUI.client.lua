local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local ClientScripts = PlayerScripts:WaitForChild("ClientScripts")

local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")

---

local clientScripts = {
    [GameEnum.ServerType.Game] = {
        HotbarKeybinds = true,
        TowerUnitUI = true,
        UnitBillboards = true,
        MountGameUI = true,

        TEMP_NonCollider = true,
    },

    [GameEnum.ServerType.Lobby] = {
        
    },
}

local initClientScripts = function(serverType: string)
    local scripts = clientScripts[serverType]

    for scriptName in pairs(scripts) do
        ClientScripts:WaitForChild(scriptName).Disabled = false
    end
end

---

local serverType = ServerMaster.GetServerType()

if (not serverType) then
    ServerMaster.ServerInitialised:Connect(initClientScripts)
else
    initClientScripts(serverType)
end