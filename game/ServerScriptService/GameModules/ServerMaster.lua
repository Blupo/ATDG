-- todo: Game needs to take priority, since some modules depend on it

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local GameModules = ServerScriptService:FindFirstChild("GameModules")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))

local ServerInitialisedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("ServerMaster")
local ServerInitialisedRemoteEvent = System.addEvent("ServerInitialised")

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
        PlayerData = true,
        Shop = true,
    },
}

---

local ServerMaster = {}
ServerMaster.ServerInitialised  = ServerInitialisedEvent.Event

ServerMaster.InitServer = function(initServerType: string)
    if (serverType) then return end

    if (initServerType == GameEnum.ServerType.Game) then
        require(GameModules:FindFirstChild("Game"))
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

ServerInitialisedEvent.Event:Connect(function(...)
    ServerInitialisedRemoteEvent:FireAllClients(...)
end)

System.addFunction("GetServerType", ServerMaster.GetServerType)

return ServerMaster