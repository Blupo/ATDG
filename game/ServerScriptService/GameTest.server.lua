-- todo: RemoteFunctions should have per-player debounce

local Game = require(script.Parent.GameModules.Game)
local GameEnums = require(game.ReplicatedStorage.Shared.GameEnums)

Game.LoadData("TestMap", "", GameEnums.GameMode.TowerDefense, GameEnums.Difficulty.Hard)

--wait(10)
Game.Start()