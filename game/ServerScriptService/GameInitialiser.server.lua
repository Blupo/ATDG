local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

---

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local ServerMaster = require(GameModules:FindFirstChild("ServerMaster"))

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local SharedGameData = require(SharedModules:WaitForChild("SharedGameData"))

local PlaceIds = SharedGameData.PlaceIds

---

local serverType
local placeId = game.PlaceId

local debugGameData = { -- SPECIFY TESTING MAP DATA HERE
    MapName = "Skymaze",
    GameMode = GameEnum.GameMode.TowerDefense,
    Difficulty = GameEnum.Difficulty.Normal,
    NumPlayers = 0,
}

if (placeId == PlaceIds.Lobby) then
    serverType = GameEnum.ServerType.Lobby
elseif (placeId == PlaceIds.Game) then
    serverType = GameEnum.ServerType.Game
elseif (placeId == 0) then
    serverType = GameEnum.ServerType.Game -- SPECIFY TESTING SERVER TYPE HERE

    warn("Studio Testing, server type is " .. serverType)
else
    error("Invalid PlaceId")
end

---

ServerMaster.InitServer(serverType, debugGameData)