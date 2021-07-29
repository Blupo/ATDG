local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

---

local ChallengeData = ServerScriptService:FindFirstChild("ChallengeData")
local MapData = ServerStorage:FindFirstChild("MapData")
local Paths = Workspace:FindFirstChild("Paths")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local TimeSyncService = require(SharedModules:FindFirstChild("Nevermore"))("TimeSyncService")
TimeSyncService:Init()

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Path = require(GameModules:FindFirstChild("Path"))
local PlayerData = require(GameModules:FindFirstChild("PlayerData"))
local StatusEffects = require(GameModules:FindFirstChild("StatusEffects"))
local Unit = require(GameModules:FindFirstChild("Unit"))

local StartedEvent = Instance.new("BindableEvent")
local EndedEvent = Instance.new("BindableEvent")
local RoundStartedEvent = Instance.new("BindableEvent")
local RoundEndedEvent = Instance.new("BindableEvent")
local CentralTowerHealthChangedEvent = Instance.new("BindableEvent")
local CentralTowerDestroyedEvent = Instance.new("BindableEvent")
local PhaseChangedEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("Game")
local StartedRemoteEvent = System.addEvent("Started")
local EndedRemoteEvent = System.addEvent("Ended")
local RoundStartedRemoteEvent = System.addEvent("RoundStarted")
local RoundEndedRemoteEvent = System.addEvent("RoundEnded")
local CentralTowerHealthChangedRemoteEvent = System.addEvent("CentralTowerHealthChanged")
local CentralTowerDestroyedRemoteEvent = System.addEvent("CentralTowerDestroyed")
local PhaseChangedRemoteEvent = System.addEvent("PhaseChanged") 

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
	CentralTowersHealth: dictionary<number, number>,
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
	CentralTowersHealth: dictionary<number, number>,
	Difficulty: string,
	CurrentChallenge: string?,
}

---

local PREPARATION_TIME = 10 -- temp: 60
local INTERMISSION_TIME = 10
local FINAL_INTERMISSION_TIME = 30

local MAX_REVIVES = {
	[GameEnum.GameMode.TowerDefense] = {
		[GameEnum.Difficulty.Easy] = 3,
		[GameEnum.Difficulty.Normal] = 2,
		[GameEnum.Difficulty.Hard] = 2,
	},
	
	[GameEnum.GameMode.Endless] = {
		[GameEnum.Difficulty.Easy] = 6,
		[GameEnum.Difficulty.Normal] = 6,
		[GameEnum.Difficulty.Hard] = 2,
	},
}

local TIMED_PHASES = {
	[GameEnum.GamePhase.FinalIntermission] = true,
	[GameEnum.GamePhase.Preparation] = true,
	[GameEnum.GamePhase.Intermission] = true,
	[GameEnum.GamePhase.Round] = true,
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
		if (currentRound <= 1) then
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
	
	if (currentPhase == GameEnum.GamePhase.NotStarted) then
		phaseStartTime = syncedClock:GetTime()
		phaseLength = PREPARATION_TIME

		gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
		currentGameData.GamePhase = GameEnum.GamePhase.Preparation

		PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
		StartedEvent:Fire()
	elseif ((currentPhase == GameEnum.GamePhase.Preparation) or (currentPhase == GameEnum.GamePhase.Intermission)) then		
		local currentRound = currentGameData.CurrentRound + 1
		currentGameData.CurrentRound = currentRound 
		calculateUnitRoundData()
		
		local difficulty = currentGameData.Difficulty		
		local pointsToAward = getPointsAllowance()
		local roundData = challengeData.Rounds[currentRound]
		
		-- award points
		PlayerData.DepositCurrencyToAllPlayers(GameEnum.CurrencyType.Points, pointsToAward)
		
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
							
							if (difficulty == GameEnum.Difficulty.Easy) then
								newUnit:ApplyAttributeModifier("Difficulty", "HP", GameEnum.AttributeModifierType.Multiplicative, function(stat)
									return stat - (stat * (1/2))
								end)
								
								newUnit:ApplyAttributeModifier("Difficulty", "DEF", GameEnum.AttributeModifierType.Multiplicative, function(stat)
									return stat - (stat * (1/2))
								end)
								
								newUnit:ApplyAttributeModifier("Difficulty", "SPD", GameEnum.AttributeModifierType.Multiplicative, function(stat)
									return stat - (stat * (1/2))
								end)
							elseif (difficulty == GameEnum.Difficulty.Hard) then
								newUnit:ApplyAttributeModifier("Difficulty", "HP", GameEnum.AttributeModifierType.Multiplicative, function(stat)
									return stat * 2
								end)

								newUnit:ApplyAttributeModifier("Difficulty", "DEF", GameEnum.AttributeModifierType.Multiplicative, function(stat)
									return stat * 2
								end)

								newUnit:ApplyAttributeModifier("Difficulty", "SPD", GameEnum.AttributeModifierType.Multiplicative, function(stat)
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
		currentGameData.GamePhase = GameEnum.GamePhase.Round
		
		RoundStartedEvent:Fire(currentRound)
		PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
	elseif (currentPhase == GameEnum.GamePhase.FinalIntermission) then
		-- reviving is handled by Game.Revive
		currentGameData.GamePhase = GameEnum.GamePhase.Ended

		PhaseChangedEvent:Fire(currentGameData.GamePhase)
		EndedEvent:Fire(false)
	elseif (currentPhase == GameEnum.GamePhase.Round) then
		local currentRound = currentGameData.CurrentRound
		local nextRoundData = challengeData.Rounds[currentRound + 1]
		RoundEndedEvent:Fire(currentRound)
		
		if (nextRoundData) then
			phaseStartTime = syncedClock:GetTime()
			phaseLength = INTERMISSION_TIME
			
			gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
			currentGameData.GamePhase = GameEnum.GamePhase.Intermission
			
			PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
		else
			currentGameData.GamePhase = GameEnum.GamePhase.Ended
			
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

local playerAdded = function(player)
	local userId = player.UserId

	PlayerData.WaitForPlayerProfile(userId):andThen(function()
		PlayerData.DepositCurrencyToPlayer(userId, GameEnum.CurrencyType.Points, challengeData.PointsAllowance[0])
	end)
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
		CentralTowersHealth = { [0] = 100 },
		GameMode = GameEnum.GameMode.TowerDefense,
		GamePhase = GameEnum.GamePhase.NotStarted,
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
		Difficulty = GameEnum.Difficulty.Normal,
		CurrentChallenge = challengeName,
		CentralTowersHealth = { [0] = 100 },
		GameMode = GameEnum.GameMode.TowerDefense,
		GamePhase = GameEnum.GamePhase.NotStarted,
		CurrentRound = 0,
		RevivesRemaining = MAX_REVIVES[GameEnum.GameMode.TowerDefense][GameEnum.Difficulty.Normal],
	}
end

Game.HasStarted = function(): boolean
	if (not currentGameData) then return false end
	
	return (currentGameData.GamePhase ~= GameEnum.GamePhase.NotStarted)
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
		CentralTowersHealth = currentGameData.CentralTowersHealth,
		Difficulty = currentGameData.Difficulty,
		CurrentChallenge = currentGameData.CurrentChallenge,
	}
end

Game.Start = function()
	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnum.GamePhase.NotStarted) then return end
	
	advanceGamePhase()
end

Game.Revive = function()
	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnum.GamePhase.FinalIntermission) then return end
	if (currentGameData.RevivesRemaining <= 0) then return end
	
	gamePhasePromise:cancel()
	
	phaseStartTime = syncedClock:GetTime()
	phaseLength = INTERMISSION_TIME
	gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
	
	currentGameData.RevivesRemaining = currentGameData.RevivesRemaining - 1
	currentGameData.CurrentRound = currentGameData.CurrentRound - 1
	currentGameData.CentralTowersHealth[0] = 100
	currentGameData.GamePhase = GameEnum.GamePhase.Intermission
	
	CentralTowerHealthChangedEvent:Fire(0, 100)
	PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
end

Game.SkipToNextRound = function()
	-- todo: can only be called if all the enemies from previous rounds have been eliminated

	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnum.GamePhase.Round) then return end
	if (#currentRoundSpawnPromises > 0) then return end
	if (currentGameData.CurrentRound == #challengeData.Rounds) then return end
	
	gamePhasePromise:cancel()
	advanceGamePhase()
end

---

do
	local players = Players:GetPlayers()

	for i = 1, #players do
		playerAdded(players[i])
	end
end

Players.PlayerAdded:Connect(playerAdded)

Unit.UnitRemoving:Connect(function(unitId)
	if (not currentGameData) then return end
	if (currentGameData.GamePhase ~= GameEnum.GamePhase.Round) then return end
	
	local unit = Unit.fromId(unitId)
	if (unit.Owner ~= 0) then return end
	if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return end
	
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
	
	if (currentGameData.GameMode == GameEnum.GameMode.TowerDefense) then
		if (direction ~= GameEnum.PursuitDirection.Forward) then
			unit:Destroy()
			return
		end
		
		local newCentralTowerHP = currentGameData.CentralTowersHealth[0] - unit:GetAttribute("HP")
		newCentralTowerHP = (newCentralTowerHP >= 0) and newCentralTowerHP or 0
		currentGameData.CentralTowersHealth[0] = newCentralTowerHP
		CentralTowerHealthChangedEvent:Fire(0, newCentralTowerHP)
		
		if (newCentralTowerHP == 0) then
			CentralTowerDestroyedEvent:Fire(0)
			
			for i = #currentRoundSpawnPromises, 1, -1 do
				currentRoundSpawnPromises[i]:cancel()
			end

			local units = Unit.GetUnits(function(testUnit)
				return (testUnit.Owner == 0) and (testUnit.Type == GameEnum.UnitType.FieldUnit)
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
				
				currentGameData.GamePhase = GameEnum.GamePhase.FinalIntermission
				RoundEndedEvent:Fire(currentGameData.CurrentRound)
				PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
			else
				gamePhasePromise:cancel()
				
				currentGameData.GamePhase = GameEnum.GamePhase.Ended
				PhaseChangedEvent:Fire(currentGameData.GamePhase)
			end
		end
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

System.addFunction("HasStarted", Game.HasStarted)
System.addFunction("GetDerivedGameState", Game.GetDerivedGameState)
System.addFunction("TEST_Revive", Game.Revive) -- TEMP
System.addFunction("TEST_SkipToNextRound", Game.SkipToNextRound) -- TEMP

return Game