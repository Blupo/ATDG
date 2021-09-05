-- Initialises scripts based on what the server is supposed to do
-- todo: get game info from datastore to pass to Game

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

if (placeId == 6421134421) then
    serverType = GameEnum.ServerType.Lobby
elseif (placeId == 6432648941) then
    serverType = GameEnum.ServerType.Game
elseif (placeId == 0) then
    serverType = GameEnum.ServerType.Lobby
    warn("Studio Testing, server type is " .. serverType)
else
    error("Invalid PlaceId")
end

---

ServerMaster.InitServer(serverType)

-- temporary until we get DataStores set up

if (serverType == GameEnum.ServerType.Game) then
    local Game = require(GameModules:FindFirstChild("Game"))

    Game.LoadData("TestMap", "", GameEnum.GameMode.TowerDefense, GameEnum.Difficulty.Normal)
    Game.Start()
end