local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

---

local GameDataStore = DataStoreService:GetDataStore("GameData", "InDev") -- todo

local GameModules = ServerScriptService:FindFirstChild("GameModules")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))

local ServerInitialisedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("ServerMaster")
local GameInitFailureNotificationRemoteEvent = System.addEvent("GameInitFailureNotification")


---

local serverType

local serverModules = {
    [GameEnum.ServerType.Game] = {
        Abilities = true,
        GameStats = true,
        Path = true,
        Placement = true,
        PlayerData = true,
        Shop = true,
        SpecialActions = true,
        StatusEffects = true,
        TowerUnit = true,
        Unit = true,
    },

    [GameEnum.ServerType.Lobby] = {
        Matchmaking = true,
        PlayerData = true,
        Shop = true,
    },
}

---

local ServerMaster = {
    ServerInitialised = ServerInitialisedEvent.Event,
}

ServerMaster.InitServer = function(initServerType: string)
    if (serverType) then return end

    if (initServerType == GameEnum.ServerType.Game) then
        local Game = require(GameModules:FindFirstChild("Game"))

        Promise.new(function(resolve, reject)
            local privateServerId = game.PrivateServerId

            if (privateServerId == "") then
                if (RunService:IsStudio()) then
                    warn("Studio Testing, using debug game info")

                    resolve({
                        MapName = "Skymaze",
                        GameMode = GameEnum.GameMode.TowerDefense,
                        Difficulty = GameEnum.Difficulty.Normal,
                    })
                    
                    return
                else
                    reject("PrivateServerId is missing")
                    return
                end
            end

            resolve(GameDataStore:RemoveAsync(privateServerId))
        end):andThen(function(gameplayData)
            Game.LoadData(gameplayData.MapName, gameplayData.GameMode, gameplayData.Difficulty)
            Game.Start()
        end, function(error)
            warn(tostring(error))
            GameInitFailureNotificationRemoteEvent:FireAllClients()

            Promise.delay(3):andThen(function()
                TeleportService:TeleportAsync(6421134421, Players:GetPlayers())
            end)
        end)
    end

    local modules = serverModules[initServerType]

    for module in pairs(modules) do
        require(GameModules:FindFirstChild(module))
    end

    serverType = initServerType
    ServerInitialisedEvent:Fire(serverType)
end

ServerMaster.GetServerType = function()
    return serverType
end

---

System.addEvent("ServerInitialised", ServerMaster.ServerInitialised)
System.addFunction("GetServerType", ServerMaster.GetServerType)

return ServerMaster