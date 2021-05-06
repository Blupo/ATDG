local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local GameCommunicators = ReplicatedStorage:WaitForChild("Communicators"):WaitForChild("Game")

local Util = script.Parent.Parent:WaitForChild("Util")
local RemoteFunctionWrapper = require(Util:WaitForChild("RemoteFunctionWrapper"))

local HasStarted = GameCommunicators:WaitForChild("HasStarted")
local GetDerivedGameState = GameCommunicators:WaitForChild("GetDerivedGameState")
local Started = GameCommunicators:WaitForChild("Started")
local Ended = GameCommunicators:WaitForChild("Ended")
local RoundStarted = GameCommunicators:WaitForChild("RoundStarted")
local RoundEnded = GameCommunicators:WaitForChild("RoundEnded")
local PhaseChanged = GameCommunicators:WaitForChild("PhaseChanged")
local CentralTowerHealthChanged = GameCommunicators:WaitForChild("CentralTowerHealthChanged")
local CentralTowerDestroyed = GameCommunicators:WaitForChild("CentralTowerDestroyed")

---

local gameStarted = false

---

local Game = {
	GetDerivedGameState = RemoteFunctionWrapper(GetDerivedGameState),
	
	Started = Started.OnClientEvent,
	Ended = Ended.OnClientEvent,
	RoundStarted = RoundStarted.OnClientEvent,
	RoundEnded = RoundEnded.OnClientEvent,
	PhaseChanged = PhaseChanged.OnClientEvent,
	CentralTowerHealthChanged = CentralTowerHealthChanged.OnClientEvent,
	CentralTowerDestroyed = CentralTowerDestroyed.OnClientEvent,
}

Game.HasStarted = function(): boolean
	if (gameStarted) then return true end
	
	gameStarted = HasStarted:InvokeServer()
	return gameStarted
end

---

return Game