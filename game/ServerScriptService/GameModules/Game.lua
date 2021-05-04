-- todo: PhaseChanged should send more info (length and start time)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

---

local ChallengeData = ServerScriptService:FindFirstChild("ChallengeData")
local GameCommunicators = ReplicatedStorage:FindFirstChild("Communicators"):FindFirstChild("Game")
local MapData = ServerStorage:FindFirstChild("MapData")
local Paths = Workspace:FindFirstChild("Paths")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local TimeSyncService = require(SharedModules:FindFirstChild("Nevermore"))("TimeSyncService")
TimeSyncService:Init()

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Path = require(GameModules:FindFirstChild("Path"))
local RemoteUtils = require(GameModules:FindFirstChild("RemoteUtils"))
local StatusEffects = require(GameModules:FindFirstChild("StatusEffects"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local StartedEvent = Instance.new("BindableEvent")
local EndedEvent = Instance.new("BindableEvent")
local RoundStartedEvent = Instance.new("BindableEvent")
local RoundEndedEvent = Instance.new("BindableEvent")
local CentralTowerHealthChangedEvent = Instance.new("BindableEvent")
local CentralTowerDestroyedEvent = Instance.new("BindableEvent")
local PhaseChangedEvent = Instance.new("BindableEvent")

local HasStartedRemoteFunction = Instance.new("RemoteFunction")
local GetDerivedGameStateRemoteFunction = Instance.new("RemoteFunction")
local StartedRemoteEvent = Instance.new("RemoteEvent")
local EndedRemoteEvent = Instance.new("RemoteEvent")
local RoundStartedRemoteEvent = Instance.new("RemoteEvent")
local RoundEndedRemoteEvent = Instance.new("RemoteEvent")
local CentralTowerHealthChangedRemoteEvent = Instance.new("RemoteEvent")
local CentralTowerDestroyedRemoteEvent = Instance.new("RemoteEvent")
local PhaseChangedRemoteEvent = Instance.new("RemoteEvent")

local TEST_SkipToNextRoundRemoteFunction = Instance.new("RemoteFunction")
local TEST_ReviveRemoteFunction = Instance.new("RemoteFunction")

---

type array<T> = {[number]: T}
type dictionary<T, TT> = {[T]: TT}

type GameRound = {
	Length: number,
	SpawnSequence: dictionary<number, dictionary<string, dictionary<number, number>>>
}

type Challenge = {
	Rounds: array<GameRound>,
	PointsAllowance: {[number]: number},
	TicketRewards: {[number | string]: number},
	
	AttributeModifiers: {
		[number]: {
			[string]: {
				[string]: {
					Type: string,
					Modifier: (any) -> any,
				} | boolean
			} | boolean
		}
	},
	
	Abilities: {
		[number]: {
			[string]: {
				[string]: boolean
			} | boolean
		}
	},
	
	StatusEffects: {
		[number]: {
			[string]: {
				[string]: number | boolean
			} | boolean
		}
	}
}

type GameData = {
	Difficulty: string,
	CurrentChallenge: string?,
	CentralTowersHP: dictionary<number, number>,
	GameMode: string,
	GamePhase: string,
	CurrentRound: number,
	RevivesRemaining: number,
}

type DerivedGameState = {
	CurrentRound: number,
	TotalRounds: number,
	CurrentPhaseLength: number?,
	CurrentPhaseStartTime: number?,
	GamePhase: string,
	CentralTowersHP: dictionary<number, number>,
	Difficulty: string,
	CurrentChallenge: string?,
}

---

local PREPARATION_TIME = 10 -- temp: 60
local INTERMISSION_TIME = 10
local FINAL_INTERMISSION_TIME = 30

local MAX_REVIVES = {
	[GameEnums.GameMode.TowerDefense] = {
		[GameEnums.Difficulty.Easy] = 3,
		[GameEnums.Difficulty.Normal] = 2,
		[GameEnums.Difficulty.Hard] = 2,
	},
	
	[GameEnums.GameMode.Endless] = {
		[GameEnums.Difficulty.Easy] = 6,
		[GameEnums.Difficulty.Normal] = 6,
		[GameEnums.Difficulty.Hard] = 2,
	},
}

local TIMED_PHASES = {
	[GameEnums.GamePhase.FinalIntermission] = true,
	[GameEnums.GamePhase.Preparation] = true,
	[GameEnums.GamePhase.Intermission] = true,
	[GameEnums.GamePhase.Round] = true,
}

local syncedClock = TimeSyncService:GetSyncedClock()
local currentGameData: GameData
local challengeData: Challenge
local gamePhasePromise

local phaseStartTime
local phaseLength

local currentUnitAttributeModifiers = {}
local currentUnitStatusEffects = {}
local currentUnitAbilities = {}

local currentRoundUnits = {}
local currentRoundSpawnPromises = {}

local combine = function(...)
	local cumulativeTable = {}
	local tables = {...}
	
	for i = 1, #tables do
		for k, v in pairs(tables[i]) do
			cumulativeTable[k] = v
		end
 	end
	
	return cumulativeTable
end

local mergeUnitDataTable = function(from, to)
	for unitSpecifier, dataTable in pairs(from) do
		if (dataTable == false) then
			to[unitSpecifier] = nil
		else
			if (to[unitSpecifier]) then
				for key, value in pairs(dataTable) do
					to[unitSpecifier][key] = (value ~= false) and value or nil
				end
			else
				to[unitSpecifier] = dataTable
			end
		end
	end
end

local calculateUnitRoundData = function()
	if (not currentGameData) then return end
	
	table.clear(currentUnitAttributeModifiers)
	table.clear(currentUnitStatusEffects)
	table.clear(currentUnitAbilities)
	
	for i = 1, currentGameData.CurrentRound do
		local attributeModifiers = challengeData.AttributeModifiers[i] or {}
		local statusEffects = challengeData.StatusEffects[i] or {}
		local abilities = challengeData.Abilities[i] or {}
		
		mergeUnitDataTable(attributeModifiers, currentUnitAttributeModifiers)
		mergeUnitDataTable(statusEffects, currentUnitStatusEffects)
		mergeUnitDataTable(abilities, currentUnitAbilities)
	end
end

local getPointsAllowance = function()
	if (not currentGameData) then return end
	
	local currentRound = currentGameData.CurrentRound
	local pointsAllowance = challengeData.PointsAllowance[currentRound]
	
	while (not pointsAllowance) do
		if (currentRound == 1) then
			pointsAllowance = 0
			break
		end
		
		currentRound = currentRound - 1
		pointsAllowance = challengeData.PointsAllowance[currentRound]
	end
	
	return pointsAllowance
end

local advanceGamePhase
advanceGamePhase = function()
	if (not currentGameData) then return end
	
	local currentPhase = currentGameData.GamePhase
	
	if (currentPhase == GameEnums.GamePhase.NotStarted) then
		phaseStartTime = syncedClock:GetTime()
		phaseLength = PREPARATION_TIME
		
		gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
		currentGameData.GamePhase = GameEnums.GamePhase.Preparation
		
		PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
		StartedEvent:Fire()
	elseif ((currentPhase == GameEnums.GamePhase.Preparation) or (currentPhase == GameEnums.GamePhase.Intermission)) then		
		local currentRound = currentGameData.CurrentRound + 1
		currentGameData.CurrentRound = currentRound 
		calculateUnitRoundData()
		
		local difficulty = currentGameData.Difficulty		
		local pointsToAward = getPointsAllowance()
		local roundData = challengeData.Rounds[currentRound]
		
		-- award points
		
		-- spawn Field units
		table.clear(currentRoundUnits)
		table.clear(currentRoundSpawnPromises)
		
		for time, units in pairs(roundData.SpawnSequence) do
			for unitName, spawnData in pairs(units) do
				for pathNum, quantity in pairs(spawnData) do
					local newSpawnPromise = Promise.delay(time)
					table.insert(currentRoundSpawnPromises, newSpawnPromise)
					
					newSpawnPromise:andThen(function()
						for _ = 1, quantity do
							local newUnit = Unit.new(unitName)
							table.insert(currentRoundUnits, newUnit.Id)
							
							newUnit.Model.Parent = Workspace
							newUnit.Model.PrimaryPart:SetNetworkOwner(nil)
							
							if (difficulty == GameEnums.Difficulty.Easy) then
								newUnit:ApplyAttributeModifier("Difficulty", "HP", GameEnums.AttributeModifierType.Multiplicative, function(stat)
									return stat - (stat * (1/2))
								end)
								
								newUnit:ApplyAttributeModifier("Difficulty", "DEF", GameEnums.AttributeModifierType.Multiplicative, function(stat)
									return stat - (stat * (1/2))
								end)
								
								newUnit:ApplyAttributeModifier("Difficulty", "SPD", GameEnums.AttributeModifierType.Multiplicative, function(stat)
									return stat - (stat * (1/2))
								end)
							elseif (difficulty == GameEnums.Difficulty.Hard) then
								newUnit:ApplyAttributeModifier("Difficulty", "HP", GameEnums.AttributeModifierType.Multiplicative, function(stat)
									return stat * 2
								end)

								newUnit:ApplyAttributeModifier("Difficulty", "DEF", GameEnums.AttributeModifierType.Multiplicative, function(stat)
									return stat * 2
								end)

								newUnit:ApplyAttributeModifier("Difficulty", "SPD", GameEnums.AttributeModifierType.Multiplicative, function(stat)
									return stat * 2
								end)
							end
						
							local unitAttributeModifiers = combine(
								currentUnitAttributeModifiers[unitName] or {},
								currentUnitAttributeModifiers[newUnit.Type] or {}
							)
							
							local unitStatusEffects = combine(
								currentUnitStatusEffects[unitName] or {},
								currentUnitStatusEffects[newUnit.Type] or {}
							)
							
							local unitAbilities = combine(
								currentUnitAbilities[unitName] or {},
								currentUnitAbilities[newUnit.Type] or {}
							)
							
							for statName, modifierData in pairs(unitAttributeModifiers) do
								newUnit:ApplyAttributeModifier("ChallengeModifier", statName, modifierData.Type, modifierData.Modifier)
							end

							for effectName, duration in pairs(unitStatusEffects) do
								StatusEffects.ApplyEffect(effectName, duration)
							end

							for abilityName in pairs(unitAbilities) do
								newUnit:GiveAbility(abilityName)
							end
							
							Path.PursuePath(newUnit, pathNum)
						end
					end):finally(function()
						local index = table.find(currentRoundSpawnPromises, newSpawnPromise)
						if (not index) then return end
						
						table.remove(currentRoundSpawnPromises, index)
					end)
				end
			end
		end
		
		phaseStartTime = syncedClock:GetTime()
		phaseLength = roundData.Length
		
		gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
		currentGameData.GamePhase = GameEnums.GamePhase.Round
		
		RoundStartedEvent:Fire(currentRound)
		PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
	elseif (currentPhase == GameEnums.GamePhase.FinalIntermission) then
		-- reviving is handled by Game.Revive
		currentGameData.GamePhase = GameEnums.GamePhase.Ended

		PhaseChangedEvent:Fire(currentGameData.GamePhase)
		EndedEvent:Fire(false)
	elseif (currentPhase == GameEnums.GamePhase.Round) then
		local currentRound = currentGameData.CurrentRound
		local nextRoundData = challengeData.Rounds[currentRound + 1]
		RoundEndedEvent:Fire(currentRound)
		
		if (nextRoundData) then
			phaseStartTime = syncedClock:GetTime()
			phaseLength = INTERMISSION_TIME
			
			gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
			currentGameData.GamePhase = GameEnums.GamePhase.Intermission
			
			PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
		else
			currentGameData.GamePhase = GameEnums.GamePhase.Ended
			
			PhaseChangedEvent:Fire(currentGameData.GamePhase)
			EndedEvent:Fire(true)
		end
	end
end

local loadMap = function(mapData)
	local paths = mapData:FindFirstChild("Paths"):Clone()
	local world = mapData:FindFirstChild("World"):Clone()
	
	for _, pathType in pairs(paths:GetChildren()) do
		for _, path in pairs(pathType:GetChildren()) do
			for _, waypoint in pairs(path:GetChildren()) do
				waypoint.CanCollide = false
				waypoint.CanTouch = false
				waypoint.Transparency = 1
			end
		end

		pathType.Parent = Paths
	end

	world.Parent = Workspace
end

---

local Game = {}

Game.Started = StartedEvent.Event
Game.Ended = EndedEvent.Event
Game.RoundStarted = RoundStartedEvent.Event
Game.RoundEnded = RoundEndedEvent.Event
Game.CentralTowerDestroyed = CentralTowerDestroyedEvent.Event
Game.PhaseChanged = PhaseChangedEvent.Event

Game.LoadData = function(mapName: string, fieldUnitSetName: string, gameMode: string, difficulty: string?)
	if (currentGameData) then return end
	
	local mapData = MapData:FindFirstChild(mapName)
	if (not mapData) then return end
	
	local challengeDataScript = ChallengeData:FindFirstChild("NormalChallenges"):FindFirstChild("Test")
	if (not challengeDataScript) then return end
	
	local revives = MAX_REVIVES[gameMode]
	
	if (revives) then
		revives = revives[difficulty]
	else
		revives = 0
	end
	
	loadMap(mapData)
	challengeData = require(challengeDataScript)
	
	currentGameData = {
		Difficulty = difficulty,
		CentralTowersHP = { [0] = 100 },
		GameMode = GameEnums.GameMode.TowerDefense,
		GamePhase = GameEnums.GamePhase.NotStarted,
		CurrentRound = 0,
		RevivesRemaining = revives,
	}
end

Game.LoadDataFromChallenge = function(mapName: string, challengeName: string)
	if (currentGameData) then return end
	
	local mapData = MapData:FindFirstChild(mapName)
	if (not mapData) then return end
	
	local challengeDataScript = ChallengeData:FindFirstChild(challengeName)
	if (not challengeDataScript) then return end
	
	local newChallengeData = require(challengeDataScript)
	if (not newChallengeData.CompatibleMaps[mapName]) then return end
	
	loadMap(mapData)
	challengeData = newChallengeData
	
	currentGameData = {
		Difficulty = GameEnums.Difficulty.Normal,
		CurrentChallenge = challengeName,
		CentralTowersHP = { [0] = 100 },
		GameMode = GameEnums.GameMode.TowerDefense,
		GamePhase = GameEnums.GamePhase.NotStarted,
		CurrentRound = 0,
		RevivesRemaining = MAX_REVIVES[GameEnums.GameMode.TowerDefense][GameEnums.Difficulty.Normal],
	}
end

Game.HasStarted = function(): boolean
	if (not currentGameData) then return false end
	
	return (currentGameData.GamePhase ~= GameEnums.GamePhase.NotStarted)
end

Game.GetDerivedGameState = function(): DerivedGameState?
	if (not currentGameData) then return end
	
	local currentPhase = currentGameData.GamePhase
	local currentRound = currentGameData.CurrentRound
	
	return {
		GameMode = currentGameData.GameMode,
		CurrentRound = currentRound,
		TotalRounds = #challengeData.Rounds,
		CurrentPhaseLength = TIMED_PHASES[currentPhase] and phaseLength or nil,
		CurrentPhaseStartTime = TIMED_PHASES[currentPhase] and phaseStartTime or nil,
		GamePhase = currentGameData.GamePhase,
		CentralTowersHP = currentGameData.CentralTowersHP,
		Difficulty = currentGameData.Difficulty,
		CurrentChallenge = currentGameData.CurrentChallenge,
	}
end

Game.Start = function()
	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnums.GamePhase.NotStarted) then return end
	
	advanceGamePhase()
end

Game.Revive = function()
	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnums.GamePhase.FinalIntermission) then return end
	if (currentGameData.RevivesRemaining <= 0) then return end
	
	gamePhasePromise:cancel()
	
	phaseStartTime = syncedClock:GetTime()
	phaseLength = INTERMISSION_TIME
	gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
	
	currentGameData.RevivesRemaining = currentGameData.RevivesRemaining - 1
	currentGameData.CurrentRound = currentGameData.CurrentRound - 1
	currentGameData.CentralTowersHP[0] = 100
	currentGameData.GamePhase = GameEnums.GamePhase.Intermission
	
	PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
end

Game.SkipToNextRound = function()
	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnums.GamePhase.Round) then return end
	if (#currentRoundSpawnPromises > 0) then return end
	if (currentGameData.CurrentRound == #challengeData.Rounds) then return end
	
	gamePhasePromise:cancel()
	advanceGamePhase()
end

---

Unit.UnitRemoving:Connect(function(unitId)
	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnums.GamePhase.Round) then return end
	
	local unit = Unit.fromId(unitId)
	if (unit.Owner ~= 0) then return end
	if (unit.Type ~= GameEnums.UnitType.FieldUnit) then return end
	
	local index = table.find(currentRoundUnits, unitId)
	if (not index) then return end

	table.remove(currentRoundUnits, index)
	
	if ((#currentRoundUnits <= 0) and (#currentRoundSpawnPromises <= 0)) then
		gamePhasePromise:cancel()
		advanceGamePhase()
	end	
end)

Path.PursuitEnded:Connect(function(unitId, destinationReached, direction)
	if (not currentGameData) then return end
	if (not destinationReached) then return end
	
	local unit = Unit.fromId(unitId)
	if (not unit) then return end
	
	if (currentGameData.GameMode == GameEnums.GameMode.TowerDefense) then
		if (direction ~= GameEnums.PursuitDirection.Forward) then
			unit:Destroy()
			return
		end
		
		local newCentralTowerHP = currentGameData.CentralTowersHP[0] - unit:GetAttribute("HP")
		newCentralTowerHP = (newCentralTowerHP >= 0) and newCentralTowerHP or 0
		currentGameData.CentralTowersHP[0] = newCentralTowerHP
		CentralTowerHealthChangedEvent:Fire(0, newCentralTowerHP)
		
		if (newCentralTowerHP == 0) then
			CentralTowerDestroyedEvent:Fire(0)
			
			for i = #currentRoundSpawnPromises, 1, -1 do
				currentRoundSpawnPromises[i]:cancel()
			end

			local units = Unit.GetUnits(function(testUnit)
				return (testUnit.Owner == 0) and (testUnit.Type == GameEnums.UnitType.FieldUnit)
			end)

			for i = 1, #units do
				units[i]:Destroy()
			end

			table.clear(currentRoundUnits)	
			table.clear(currentRoundSpawnPromises)
			
			if (currentGameData.RevivesRemaining > 0) then
				gamePhasePromise:cancel()
				
				phaseStartTime = syncedClock:GetTime()
				phaseLength = FINAL_INTERMISSION_TIME
				gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
				
				currentGameData.GamePhase = GameEnums.GamePhase.FinalIntermission
				RoundEndedEvent:Fire(currentGameData.CurrentRound)
				PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
			else
				gamePhasePromise:cancel()
				
				currentGameData.GamePhase = GameEnums.GamePhase.Ended
				PhaseChangedEvent:Fire(currentGameData.GamePhase)
			end
		end
	else
		-- todo
	end
	
	unit:Destroy()
end)

StartedEvent.Event:Connect(function()
	StartedRemoteEvent:FireAllClients()
end)

EndedEvent.Event:Connect(function(completed)
	EndedRemoteEvent:FireAllClients(completed)
end)

RoundStartedEvent.Event:Connect(function(...)
	RoundStartedRemoteEvent:FireAllClients(...)
end)

RoundEndedEvent.Event:Connect(function(...)
	RoundEndedRemoteEvent:FireAllClients(...)
end)

CentralTowerHealthChangedEvent.Event:Connect(function(...)
	CentralTowerHealthChangedRemoteEvent:FireAllClients(...)
end)

CentralTowerDestroyedEvent.Event:Connect(function(...)
	CentralTowerDestroyedRemoteEvent:FireAllClients(...)
end)

PhaseChangedEvent.Event:Connect(function(...)
	PhaseChangedRemoteEvent:FireAllClients(...)
end)

HasStartedRemoteFunction.OnServerInvoke = Game.HasStarted
GetDerivedGameStateRemoteFunction.OnServerInvoke = Game.GetDerivedGameState
TEST_ReviveRemoteFunction.OnServerInvoke = Game.Revive
TEST_SkipToNextRoundRemoteFunction.OnServerInvoke = Game.SkipToNextRound

StartedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)
EndedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)
RoundStartedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)
RoundEndedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)
CentralTowerHealthChangedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)
CentralTowerDestroyedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)
PhaseChangedRemoteEvent.OnServerEvent:Connect(RemoteUtils.NoOp)

HasStartedRemoteFunction.Name = "HasStarted"
GetDerivedGameStateRemoteFunction.Name = "GetDerivedGameState"
StartedRemoteEvent.Name = "Started"
EndedRemoteEvent.Name = "Ended"
RoundStartedRemoteEvent.Name = "RoundStarted"
RoundEndedRemoteEvent.Name = "RoundEnded"
CentralTowerHealthChangedRemoteEvent.Name = "CentralTowerHealthChanged"
CentralTowerDestroyedRemoteEvent.Name = "CentralTowerDestroyed"
PhaseChangedRemoteEvent.Name = "PhaseChanged"
TEST_ReviveRemoteFunction.Name = "TEST_ReviveRemoteFunction"
TEST_SkipToNextRoundRemoteFunction.Name = "TEST_SkipToNextRoundRemoteFunction"

HasStartedRemoteFunction.Parent = GameCommunicators
GetDerivedGameStateRemoteFunction.Parent = GameCommunicators
StartedRemoteEvent.Parent = GameCommunicators
EndedRemoteEvent.Parent = GameCommunicators
RoundStartedRemoteEvent.Parent = GameCommunicators
RoundEndedRemoteEvent.Parent = GameCommunicators
CentralTowerHealthChangedRemoteEvent.Parent = GameCommunicators
CentralTowerDestroyedRemoteEvent.Parent = GameCommunicators
PhaseChangedRemoteEvent.Parent = GameCommunicators
TEST_ReviveRemoteFunction.Parent = GameCommunicators
TEST_SkipToNextRoundRemoteFunction.Parent = GameCommunicators

return Game