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

local SERVER_TYPE = GameEnum.ServerType.Game

---

ServerMaster.InitServer(SERVER_TYPE)

--- FOR GAME TESTING ONLY

if (SERVER_TYPE == GameEnum.ServerType.Game) then
    local Game = require(GameModules:FindFirstChild("Game"))

    Game.LoadData("TestMap", "", GameEnum.GameMode.TowerDefense, GameEnum.Difficulty.Normal)
    Game.Start()
end