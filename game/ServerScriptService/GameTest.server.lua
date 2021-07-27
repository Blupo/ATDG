local Game = require(script.Parent.GameModules.Game)
local GameEnums = require(game.ReplicatedStorage.Shared.GameEnums)

Game.LoadData("TestMap", "", GameEnums.GameMode.TowerDefense, GameEnums.Difficulty.Normal)

--wait(10)
Game.Start()