local Game = require(script.Parent.GameModules.Game)
local GameEnum = require(game.ReplicatedStorage.Shared.GameEnum)

Game.LoadData("TestMap", "", GameEnum.GameMode.TowerDefense, GameEnum.Difficulty.Normal)

--wait(10)
Game.Start()