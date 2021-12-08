local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local ClientScripts = PlayerScripts:WaitForChild("ClientScripts")
local EventProxy = require(ClientScripts:WaitForChild("EventProxy"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local Matchmaking = SystemCoordinator.waitForSystem("Matchmaking")

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local Notifications = require(PlayerModules:WaitForChild("Notifications"))

---

local cachedGameList = {}
local cachedMapList = {}
local localPlayerCurrentParty

---

Matchmaking.GameOpened = EventProxy(Matchmaking.GameOpened, function(gameId, gameData)
    cachedGameList[gameId] = gameData

    if ((gameData.Leader == LocalPlayer) or table.find(gameData.Players, LocalPlayer)) then
        localPlayerCurrentParty = gameId
    end
end)

Matchmaking.GameClosed = EventProxy(Matchmaking.GameClosed, function(gameId)
    if (localPlayerCurrentParty == gameId) then
        local gameData = cachedGameList[gameId]
        
        if (gameData.Leader ~= LocalPlayer) then
            Notifications.SendCoreNotification("Game Closed", gameData.Leader.Name .. "'s game was closed.", "Game")
        end

        localPlayerCurrentParty = nil
    end

    cachedGameList[gameId] = nil
end)

Matchmaking.GameStarting = EventProxy(Matchmaking.GameStarting, function(gameId)
    if (localPlayerCurrentParty == gameId) then
        local gameData = cachedGameList[gameId]
        
        if ((gameData.Leader == LocalPlayer) or table.find(gameData.Players, LocalPlayer)) then
            Notifications.SendCoreNotification("Game Starting", "Your game will be starting soon.", "Game")
        end

        if (table.find(gameData.Queue, LocalPlayer)) then
            localPlayerCurrentParty = nil
        end
    end

    cachedGameList[gameId] = nil
end)

Matchmaking.PlayerJoinedGame = EventProxy(Matchmaking.PlayerJoinedGame, function(gameId, player)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    table.insert(gameData.Players, player)

    if (player == LocalPlayer) then
        localPlayerCurrentParty = gameId
    end
end)

Matchmaking.PlayerLeftGame = EventProxy(Matchmaking.PlayerLeftGame, function(gameId, player, kicked)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    local playerList = gameData.Players
    local playerIndex = table.find(playerList, player)
    if (not playerIndex) then return end

    table.remove(playerList, playerIndex)

    if (player == LocalPlayer) then
        if (kicked) then
            Notifications.SendCoreNotification("Kicked", "You were kicked from " .. gameData.Leader.Name .. "'s party.", "Party")
        end

        localPlayerCurrentParty = nil
    end
end)

Matchmaking.PlayerJoinedGameQueue = EventProxy(Matchmaking.PlayerJoinedGameQueue, function(gameId, player)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    table.insert(gameData.Queue, player)

    if (player == LocalPlayer) then
        localPlayerCurrentParty = gameId
    end
end)

Matchmaking.PlayerLeftGameQueue = EventProxy(Matchmaking.PlayerLeftGameQueue, function(gameId, player, joined)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    local queue = gameData.Queue
    local playerIndex = table.find(queue, player)
    if (not playerIndex) then return end

    table.remove(queue, playerIndex)

    if (player == LocalPlayer) then
        Notifications.SendCoreNotification(
            "Request " .. (joined and "Accepted" or "Rejected"),
            string.format("Your request to join %s's party was %s.", gameData.Leader.Name, joined and "accepted" or "rejected"),
            "Party"
        )

        if (not joined) then
            localPlayerCurrentParty = nil
        end
    end
end)

---

local CacheProxy = {}

CacheProxy.GetGameData = function(gameId: string)
    local gameData = cachedGameList[gameId]

    return gameData and CopyTable(gameData) or nil
end

CacheProxy.GetGames = function()
    return CopyTable(cachedGameList)
end

CacheProxy.GetMaps = function()
    return CopyTable(cachedMapList)
end

---

cachedGameList = Matchmaking.GetGames()
cachedMapList = Matchmaking.GetMaps()

Matchmaking.TeleportNotification:Connect(function()
    Notifications.SendCoreNotification("Teleporting", "You are now being teleported to your game, please wait.", "Teleport")
end)

Matchmaking.GameInitFailureNotification:Connect(function()
    Notifications.SendCoreNotification("Game Error", "There was a problem initialising your game. The party leader can try starting the game again.", "Game")
end)

return setmetatable(CacheProxy, { __index = Matchmaking })