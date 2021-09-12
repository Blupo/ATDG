local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

---

local LocalPlayer = Players.LocalPlayer

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local Matchmaking = SystemCoordinator.waitForSystem("Matchmaking")

---

local cachedGameList = {}
local cachedMapList = {}
local localPlayerCurrentParty

local notifyIcons = {
    Party = "rbxassetid://7440497724",
    Game = "rbxassetid://6868396182",
    Teleport = "rbxassetid://6869244717",
}

local sendNotification = function(title, text, notifyType)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = notifyIcons[notifyType],
    })
end

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

Matchmaking.GameOpened:Connect(function(gameId, gameData)
    cachedGameList[gameId] = gameData

    if ((gameData.Leader == LocalPlayer) or table.find(gameData.Players, LocalPlayer)) then
        localPlayerCurrentParty = gameId
    end
end)

Matchmaking.GameClosed:Connect(function(gameId)
    if (localPlayerCurrentParty == gameId) then
        local gameData = cachedGameList[gameId]
        
        if (gameData.Leader ~= LocalPlayer) then
            sendNotification("Game Closed", gameData.Leader.Name .. "'s game was closed.", "Game")
        end

        localPlayerCurrentParty = nil
    end

    cachedGameList[gameId] = nil
end)

Matchmaking.GameStarting:Connect(function(gameId)
    if (localPlayerCurrentParty == gameId) then
        local gameData = cachedGameList[gameId]
        
        if ((gameData.Leader == LocalPlayer) or table.find(gameData.Players, LocalPlayer)) then
            sendNotification("Game Starting", "Your game will be starting soon.", "Game")
        end

        if (table.find(gameData.Queue, LocalPlayer)) then
            localPlayerCurrentParty = nil
        end
    end

    cachedGameList[gameId] = nil
end)

Matchmaking.PlayerJoinedGame:Connect(function(gameId, player)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    table.insert(gameData.Players, player)

    if (player == LocalPlayer) then
        localPlayerCurrentParty = gameId
    end
end)

Matchmaking.PlayerLeftGame:Connect(function(gameId, player, kicked)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    local playerList = gameData.Players
    local playerIndex = table.find(playerList, player)
    if (not playerIndex) then return end

    table.remove(playerList, playerIndex)

    if (player == LocalPlayer) then
        if (kicked) then
            sendNotification("Kicked", "You were kicked from " .. gameData.Leader.Name .. "'s party.", "Party")
        end

        localPlayerCurrentParty = nil
    end
end)

Matchmaking.PlayerJoinedGameQueue:Connect(function(gameId, player)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    table.insert(gameData.Queue, player)

    if (player == LocalPlayer) then
        localPlayerCurrentParty = gameId
    end
end)

Matchmaking.PlayerLeftGameQueue:Connect(function(gameId, player, joined)
    local gameData = cachedGameList[gameId]
    if (not gameData) then return end

    local queue = gameData.Queue
    local playerIndex = table.find(queue, player)
    if (not playerIndex) then return end

    table.remove(queue, playerIndex)

    if (player == LocalPlayer) then
        sendNotification(
            "Request " .. (joined and "Accepted" or "Rejected"),
            string.format("Your request to join %s's party was %s.", gameData.Leader.Name, joined and "accepted" or "rejected"),
            "Party"
        )

        if (not joined) then
            localPlayerCurrentParty = nil
        end
    end
end)

Matchmaking.TeleportNotification:Connect(function()
    sendNotification("Teleporting", "You are now being teleported to your game, please wait.", "Teleport")
end)

Matchmaking.GameInitFailureNotification:Connect(function()
    sendNotification("Game Error", "There was a problem initialising your game. The party leader can try starting the game again.", "Game")
end)

return setmetatable(CacheProxy, { __index = Matchmaking })