local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local ServerMaster = require(GameModules:FindFirstChild("ServerMaster"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

local serverType
local placeId = game.PlaceId

local debugGameData = {
    MapName = "AnimationTest",
    GameMode = GameEnum.GameMode.TowerDefense,
    Difficulty = GameEnum.Difficulty.Normal,
    NumPlayers = 0,
}

if (placeId == 6421134421) then
    serverType = GameEnum.ServerType.Lobby
elseif (placeId == 6432648941) then
    serverType = GameEnum.ServerType.Game
elseif (placeId == 0) then
    serverType = GameEnum.ServerType.Game
    warn("Studio Testing, server type is " .. serverType)
else
    error("Invalid PlaceId")
end

---

ServerMaster.InitServer(serverType, debugGameData)