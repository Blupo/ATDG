local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

---

local Lobbies = ServerStorage:FindFirstChild("Lobbies")

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local LoadEnvironment = require(GameModules:FindFirstChild("LoadEnvironment"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SharedGameData = require(SharedModules:FindFirstChild("SharedGameData"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))

local ServerInitialisedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("ServerMaster")
local GameInitFailureNotificationRemoteEvent = System.addEvent("GameInitFailureNotification")

local GameDataStore = DataStoreService:GetDataStore("GameData", SharedGameData.Scope)

---

local serverType

local serverModules = {
    [GameEnum.ServerType.Game] = {
        Abilities = true,
        GameStats = true,
        Path = true,
        Placement = true,
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
        SpecialActions = true,
    },
}

local onUnitAdded = function(unitModel)
    local descendants = unitModel:GetDescendants()

    for i = 1, #descendants do
        local descendant = descendants[i]

        if (descendant:IsA("BasePart")) then
            PhysicsService:SetPartCollisionGroup(descendant, GameEnum.CollisionGroup.Units)
        end
    end
end

local onCharacterDescendantAdded = function(descendant)
    if (descendant:IsA("BasePart")) then
        PhysicsService:SetPartCollisionGroup(descendant, GameEnum.CollisionGroup.Players)
    end
end

local onPlayerCharacterAdded = function(character)
    character.DescendantAdded:Connect(onCharacterDescendantAdded)

    local descendants = character:GetDescendants()

    for i = 1, #descendants do
        onCharacterDescendantAdded(descendants[i])
    end
end

local onPlayerAdded = function(player)
    player.CharacterAdded:Connect(onPlayerCharacterAdded)

    if (player.Character) then
        onPlayerCharacterAdded(player.Character)
    end
end

local onNoUnitCollisionPartAdded = function(part: BasePart)
    PhysicsService:SetPartCollisionGroup(part, GameEnum.CollisionGroup.NoUnitCollisions)
end

---

local ServerMaster = {
    ServerInitialised = ServerInitialisedEvent.Event,
}

ServerMaster.InitServer = function(initServerType: string, debugGameData)
    if (serverType) then return end
    serverType = initServerType

    if (serverType == GameEnum.ServerType.Game) then
        local Game = require(GameModules:FindFirstChild("Game"))
        local PlayerData = require(GameModules:FindFirstChild("PlayerData"))

        Promise.new(function(resolve, reject)
            local privateServerId = game.PrivateServerId

            if (privateServerId == "") then
                if (RunService:IsStudio()) then
                    warn("Studio Testing, using debug game info")
                    resolve(debugGameData)
                    return
                else
                    reject("PrivateServerId is missing")
                    return
                end
            end

            resolve(GameDataStore:RemoveAsync(privateServerId))
        end):andThen(function(gameplayData)
            Game.LoadData(gameplayData.MapName, gameplayData.GameMode, gameplayData.Difficulty)

            Promise.new(function(resolve, _, onCancel)
                local flag = true

                onCancel(function()
                    flag = false
                end)

                while ((#Players:GetPlayers() < gameplayData.NumPlayers) and flag) do
                    RunService.Heartbeat:Wait()
                end

                if (flag) then
                    resolve()
                end
            end):timeout(10):finally(function()
                Promise.new(function(resolve, _, onCancel)
                    local flag = true
                    local players = Players:GetPlayers()

                    onCancel(function()
                        flag = false
                    end)

                    for i = 1, #players do
                        if (not flag) then break end

                        PlayerData.WaitForPlayerProfile(players[i].UserId):await()
                    end

                    if (flag) then
                        resolve()
                    end
                end):timeout(20):finally(function()
                    Game.Start()
                end)
            end)
        end, function(error)
            warn(tostring(error))
            GameInitFailureNotificationRemoteEvent:FireAllClients()

            Promise.delay(3):andThen(function()
                TeleportService:TeleportAsync(6421134421, Players:GetPlayers())
            end)
        end)
    elseif (serverType == GameEnum.ServerType.Lobby) then
        LoadEnvironment(Lobbies:FindFirstChild(SharedGameData.Scope))
    end

    local modules = serverModules[serverType]

    for module in pairs(modules) do
        require(GameModules:FindFirstChild(module))
    end
    
    ServerInitialisedEvent:Fire(serverType)
end

ServerMaster.GetServerType = function()
    return serverType
end

---

PhysicsService:CreateCollisionGroup(GameEnum.CollisionGroup.Units)
PhysicsService:CreateCollisionGroup(GameEnum.CollisionGroup.Players)
PhysicsService:CreateCollisionGroup(GameEnum.CollisionGroup.NoUnitCollisions)

PhysicsService:CollisionGroupSetCollidable(GameEnum.CollisionGroup.Units, GameEnum.CollisionGroup.Units, false)
PhysicsService:CollisionGroupSetCollidable(GameEnum.CollisionGroup.Players, GameEnum.CollisionGroup.Players, false)
PhysicsService:CollisionGroupSetCollidable(GameEnum.CollisionGroup.Units, GameEnum.CollisionGroup.Players, false)
PhysicsService:CollisionGroupSetCollidable(GameEnum.CollisionGroup.NoUnitCollisions, GameEnum.CollisionGroup.Units, false)

do
    local players = Players:GetPlayers()
    local units = CollectionService:GetTagged(GameEnum.ObjectType.Unit)
    local noUnitCollisionParts = CollectionService:GetTagged(GameEnum.CollisionGroup.NoUnitCollisions)

    for i = 1, #players do
        onPlayerAdded(players[i])
    end

    for i = 1, #units do
        onUnitAdded(units[i])
    end

    for i = 1, #noUnitCollisionParts do
        onNoUnitCollisionPartAdded(noUnitCollisionParts[i])
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
CollectionService:GetInstanceAddedSignal(GameEnum.ObjectType.Unit):Connect(onUnitAdded)
CollectionService:GetInstanceAddedSignal(GameEnum.CollisionGroup.NoUnitCollisions):Connect(onNoUnitCollisionPartAdded)

System.addEvent("ServerInitialised", ServerMaster.ServerInitialised)
System.addFunction("GetServerType", ServerMaster.GetServerType)

return ServerMaster