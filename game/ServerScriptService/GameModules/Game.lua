local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

---

local ChallengeData = ServerScriptService:FindFirstChild("ChallengeData")
local MapData = ServerStorage:FindFirstChild("MapData")

local Paths = Instance.new("Folder")
Paths.Name = "Paths"
Paths.Parent = Workspace

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local TimeSyncService = require(SharedModules:FindFirstChild("Nevermore"))("TimeSyncService")
TimeSyncService:Init()

local GameModules = ServerScriptService:FindFirstChild("GameModules")
local Abilities = require(GameModules:FindFirstChild("Abilities"))
local LoadEnvironment = require(GameModules:FindFirstChild("LoadEnvironment"))
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
    Completed: boolean,
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
    PlayTime: nubmer?,
    Completed: boolean,
}

---

local PREPARATION_TIME = 30
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

local gameStartTime
local phaseStartTime
local phaseLength

local currentUnitAttributeModifiers = {}
local currentUnitStatusEffects = {}
local currentUnitAbilities = {}

local currentRoundUnits = {}
local currentRoundSpawnPromises = {}

local unitDamageTakenConnections = {}
local unitDiedConnections = {}
local pointPayoutAccumulators = {}

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

local addPointsToPlayerAccumulator = function(playerId: number, points: number)
    local payoutAccumulator = pointPayoutAccumulators[playerId]

    if (not payoutAccumulator) then
        pointPayoutAccumulators[playerId] = {
            Total = 0,
            Payout = 0,
        }

        payoutAccumulator = pointPayoutAccumulators[playerId]
    end

    local newTotal = payoutAccumulator.Total + points
    local difference = newTotal - payoutAccumulator.Payout

    if (difference >= 1) then
        local wholeDifference = math.floor(difference + 0.5)

        PlayerData.DepositCurrencyToPlayer(playerId, GameEnum.CurrencyType.Points, wholeDifference)
        payoutAccumulator.Payout = payoutAccumulator.Payout + wholeDifference
    end
    
    payoutAccumulator.Total = newTotal
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

local getTicketReward = function(): number?
    if (not currentGameData) then return end

    local ticketRewards = challengeData.TicketRewards
    local currentRound = currentGameData.CurrentRound
    local gameCompleted = currentGameData.Completed

    if (gameCompleted) then
        return ticketRewards.Completion
    else
        local reward = ticketRewards[currentRound]

        while (not reward) do
            if (currentRound <= 1) then
                reward = 0
                break
            end

            currentRound = currentRound - 1
            reward = ticketRewards[currentRound]
        end

        return reward
    end
end

local getPointsAllowance = function()
    if (not currentGameData) then return end
    
    local pointsAllowance = challengeData.PointsAllowance
    local currentRound = currentGameData.CurrentRound
    local points = pointsAllowance[currentRound]
    
    while (not points) do
        if (currentRound <= 0) then
            points = 0
            break
        end
        
        currentRound = currentRound - 1
        points = pointsAllowance[currentRound]
    end
    
    return points
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
        local roundData = challengeData.Rounds[currentRound]

        -- trigger RoundStart abilities
        do
            local units = Unit.GetUnits()

            for i = 1, #units do
                local unit = units[i]
                
                Abilities.ActivateAbilities(unit, GameEnum.AbilityType.RoundStart)
            end
        end
        
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
                                StatusEffects.ApplyEffect(newUnit.Id, effectName, duration)
                            end

                            for abilityName in pairs(unitAbilities) do
                                Abilities.GiveAbility(newUnit.Id, abilityName)
                            end
                            
                            newUnit.Model.Parent = Workspace
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

        PlayerData.DepositCurrencyToAllPlayers(GameEnum.CurrencyType.Tickets, getTicketReward())

        PhaseChangedEvent:Fire(currentGameData.GamePhase)
        EndedEvent:Fire(currentGameData.Completed)
    elseif (currentPhase == GameEnum.GamePhase.Round) then
        local currentRound = currentGameData.CurrentRound
        local nextRoundData = challengeData.Rounds[currentRound + 1]
        RoundEndedEvent:Fire(currentRound)
        
        if (nextRoundData) then
            phaseStartTime = syncedClock:GetTime()
            phaseLength = INTERMISSION_TIME

            local difficulty = currentGameData.Difficulty        
            local pointsToAward = getPointsAllowance()
            
            -- award points
            if (difficulty == GameEnum.Difficulty.Hard) then
                pointsToAward = pointsToAward / 2

                local wholePoints = math.floor(pointsToAward)
                local difference = pointsToAward - wholePoints

                -- add the difference into the accumulators
                if (difference > 0) then
                    local players = Players:GetPlayers()

                    for i = 1, #players do
                        addPointsToPlayerAccumulator(players[i].UserId, difference)
                    end
                end

                pointsToAward = wholePoints
            end

            PlayerData.DepositCurrencyToAllPlayers(GameEnum.CurrencyType.Points, pointsToAward)
            
            -- todo: trigger RoundEnded abilities

            gamePhasePromise = Promise.delay(phaseLength):andThen(advanceGamePhase)
            currentGameData.GamePhase = GameEnum.GamePhase.Intermission
            
            PhaseChangedEvent:Fire(currentGameData.GamePhase, phaseStartTime, phaseLength)
        else
            currentGameData.GamePhase = GameEnum.GamePhase.Ended
            currentGameData.Completed = true

            PlayerData.DepositCurrencyToAllPlayers(GameEnum.CurrencyType.Tickets, getTicketReward())
            
            PhaseChangedEvent:Fire(currentGameData.GamePhase)
            EndedEvent:Fire(currentGameData.Completed)
        end
    end
end

local loadMap = function(mapData)
    local paths = mapData:FindFirstChild("Paths")
    
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

    LoadEnvironment(mapData)
end

local playerAdded = function(player)
    local userId = player.UserId

    while (not challengeData) do
        RunService.Heartbeat:Wait()
    end

    PlayerData.WaitForPlayerProfile(userId):andThen(function()
        PlayerData.DepositCurrencyToPlayer(userId, GameEnum.CurrencyType.Points, challengeData.PointsAllowance[0])
    end)
end

---

local Game = {
    Started = StartedEvent.Event,
    Ended = EndedEvent.Event,
    RoundStarted = RoundStartedEvent.Event,
    RoundEnded = RoundEndedEvent.Event,
    CentralTowerHealthChanged = CentralTowerHealthChangedEvent.Event,
    CentralTowerDestroyed = CentralTowerDestroyedEvent.Event,
    PhaseChanged = PhaseChangedEvent.Event,
    GetTicketReward = getTicketReward,
}

Game.LoadData = function(mapName: string, gameMode: string, difficulty: string?)
    if (currentGameData) then return end
    
    local mapData = MapData:FindFirstChild(mapName)
    if (not mapData) then return end
    
    local challengeDataScript = ChallengeData:FindFirstChild(mapName) or ChallengeData:FindFirstChild("DEV_Test") -- change Test to Default
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
        Completed = false,
    }
end

Game.LoadDataFromChallenge = function(mapName: string, challengeName: string)
    if (currentGameData) then return end
    
    local mapData = MapData:FindFirstChild(mapName)
    if (not mapData) then return end
    
    local challengeDataScript = ChallengeData:FindFirstChild(challengeName)
    if (not challengeDataScript) then return end
    
    local newChallengeData = require(challengeDataScript)
--    if (not newChallengeData.CompatibleMaps[mapName]) then return end
    
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
        Completed = false,
    }
end

Game.IsRunning = function(): boolean
    if (not currentGameData) then return false end

    return (currentGameData.GamePhase ~= GameEnum.GamePhase.NotStarted) and (currentGameData.GamePhase ~= GameEnum.GamePhase.Ended)
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
        PlayTime = gameStartTime and (os.time() - gameStartTime) or nil,
        Completed = currentGameData.Completed,
    }
end

Game.Start = function()
    if (not currentGameData) then return end
    if (currentGameData.GamePhase ~= GameEnum.GamePhase.NotStarted) then return end
    
    gameStartTime = os.time()
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
    if (not currentGameData) then return end
    if (currentGameData.GamePhase ~= GameEnum.GamePhase.Round) then return end
    if (#currentRoundSpawnPromises > 0) then return end -- Cannot skip if there are still Units to spawn
    if (currentGameData.CurrentRound == #challengeData.Rounds) then return end -- Cannot skip the final round

    local gameFieldUnits = Unit.GetUnits(function(unit)
        return ((unit.Type == GameEnum.UnitType.FieldUnit) and (unit.Owner == 0))
    end)

    for i = 1, #gameFieldUnits do
        -- Cannot skip if there are Units from previous rounds
        if (not table.find(currentRoundUnits, gameFieldUnits[i].Id)) then return end
    end
    
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

Players.PlayerRemoving:Connect(function(player)
    pointPayoutAccumulators[player.UserId] = nil
end)

Unit.UnitAdded:Connect(function(unitId)
    if (not Game.IsRunning()) then return end

    local unit = Unit.fromId(unitId)
    if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return end

    unitDiedConnections[unitId] = unit.Died:Connect(function()
        unitDiedConnections[unitId]:Disconnect()
        unitDiedConnections[unitId] = nil
        
        PlayerData.DepositCurrencyToAllPlayers(GameEnum.CurrencyType.Points, math.floor(1.25 * unit:GetAttribute("MaxHP")))
    end)

    unitDamageTakenConnections[unitId] = unit.DamageTaken:Connect(function(damage, damageSourceType, damageSource)
        if (damageSourceType ~= GameEnum.DamageSourceType.Unit) then return end

        local attackerUnit = Unit.fromId(damageSource)
        if (not attackerUnit) then return end

        local playerId = attackerUnit.Owner
        if (not Players:GetPlayerByUserId(playerId)) then return end

        addPointsToPlayerAccumulator(playerId, damage)
    end)
end)

Unit.UnitRemoving:Connect(function(unitId)
    if (unitDamageTakenConnections[unitId]) then
        unitDamageTakenConnections[unitId]:Disconnect()
        unitDamageTakenConnections[unitId] = nil
    end

    if (not Game.IsRunning()) then return end
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

            local units = Unit.GetUnits(function(testUnit)
                return (testUnit.Owner == 0) and (testUnit.Type == GameEnum.UnitType.FieldUnit)
            end)

            for i = 1, #units do
                units[i]:Destroy()
            end
        end
    end
    
    unit:Destroy()
end)

System.addEvent("Started", Game.Started)
System.addEvent("Ended", Game.Ended)
System.addEvent("RoundStarted", Game.RoundStarted)
System.addEvent("RoundEnded", Game.RoundEnded)
System.addEvent("CentralTowerHealthChanged", Game.CentralTowerHealthChanged)
System.addEvent("CentralTowerDestroyed", Game.CentralTowerDestroyed)
System.addEvent("PhaseChanged", Game.PhaseChanged) 

System.addFunction("IsRunning", Game.IsRunning)
System.addFunction("GetDerivedGameState", Game.GetDerivedGameState)
System.addFunction("GetTicketReward", Game.GetTicketReward)
System.addFunction("TEST_Revive", Game.Revive) -- TEMP
System.addFunction("TEST_SkipToNextRound", Game.SkipToNextRound) -- TEMP

return Game