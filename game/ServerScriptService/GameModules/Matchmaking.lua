local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

---

local MapData = ServerStorage:FindFirstChild("MapData")

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))
local Promise = require(SharedModules:FindFirstChild("Promise"))
local SystemCoordinator = require(SharedModules:FindFirstChild("SystemCoordinator"))
local t = require(SharedModules:FindFirstChild("t"))

local GameOpenedEvent = Instance.new("BindableEvent")
local GameClosedEvent = Instance.new("BindableEvent")
local GameStartingEvent = Instance.new("BindableEvent")
local PlayerJoinedGameEvent = Instance.new("BindableEvent")
local PlayerLeftGameEvent = Instance.new("BindableEvent")
local PlayerJoinedGameQueueEvent = Instance.new("BindableEvent")
local PlayerLeftGameQueueEvent = Instance.new("BindableEvent")

local System = SystemCoordinator.newSystem("Matchmaking")
local TeleportNotifcationRemoteEvent = System.addEvent("TeleportNotification")
local GameInitFailureNotificationRemoteEvent = System.addEvent("GameInitFailureNotification")

---

type array<T> = {[number]: T}
type dictionary<T, TT> = {[T]: TT}

type GameplayData = {
    MapName: string,
    GameMode: string,
    Difficulty: string,
}

type AccessRule = {
    RuleType: string,
    RuleArguments: dictionary<string, any>?
}

type AccessRules = {
    ApprovalType: string,
    Ruleset: array<AccessRule>,
}

type GameData = {
    CreatedAt: number,

    Leader: Player,
    Players: array<Players>,
    Queue: array<Players>,

    GameplayData: GameplayData,
    GameplayModifiers: {},
    AccessRules: AccessRules
}

---

local TEMP_MAX_PLAYERS = 4 -- todo: max players should depend on gamemode

local GameDataStore = DataStoreService:GetDataStore("GameData", "InDev") -- todo

local games = {}
local startingGames = {}

local mapList = {}

local accessRuleData = {
    [GameEnum.GameAccessRuleType.ApproveFriends] = {
        ExtraArguments = {
            GameLeader = "GameLeader"
        },

        Callback = function(player: Player, ruleArguments: dictionary<string, any>): string?
            local gameLeader = ruleArguments.GameLeader
            if (not gameLeader) then return GameEnum.GameAccessRuleProcessingResult.CouldNotProcess end

            local success, isFriendsWithLeader = pcall(function()
                return gameLeader:IsFriendsWith(player)
            end)

            if (success) then
                return GameEnum.GameAccessRuleProcessingResult[isFriendsWithLeader and "Approve" or "Continue"]
            else
                return GameEnum.GameAccessRuleProcessingResult.CouldNotProcess
            end
        end
    },

    [GameEnum.GameAccessRuleType.Reject] = {
        Callback = function(_, _): string?
            return GameEnum.GameAccessRuleProcessingResult.Reject
        end
    },

    --[[
    -- example with player levels (which this game doesn't have)

    [GameEnum.GameAccessRuleType.LevelRange] = {
        -- VerifyArguments is used to verify the rule arguments supplied by players when creating games
        VerifyArguments = {
            MinLevel = t.optional(t.number),
            MaxLevel = t.optional(t.number),
        },

        -- ExtraArguments is used for the module to pass additional arguments to the processing callback
        ExtraArguments = {},

        Callback = function(player: Player, ruleArguments: dictionary<string, any>): string?
            local minLevel, maxLevel = ruleArgument.MinLevel, ruleArguments.MaxLevel
            if (not (minLevel and maxLevel)) then return GameEnum.GameAccessRuleProcessingResult.CouldNotProcess end

            local playerLevel = PlayerData.GetPlayerLevel(player.UserId)
            if (not playerLevel) then return GameEnum.GameAccessRuleProcessingResult.CouldNotProcess end

            if (minLevel and (playerLevel < minLevel)) then
                return -- Continue
            end

            if (maxLevel and (playerLevel > maxLevel)) then
                return -- Continue
            end

            return -- Approve
        end
    },
    ]]
}

local gameplayDataType = t.interface({
    MapName = t.string,
    GameMode = t.string,
    Difficulty = t.string,
})

local accessRuleDataType = t.interface({
    RuleType = t.string,
    RuleArguments = t.optional(t.map(t.string, t.any))
})

local accessRulesDataType = t.interface({
    ApprovalType = t.string,
    Ruleset = t.array(accessRuleDataType)
})

local getPlayerGameId = function(player: Player): string?
    for gameId, gameData in pairs(games) do
        if (
            (gameData.Leader == player) or
            table.find(gameData.Players, player) or
            table.find(gameData.Queue, player)
        ) then
            return gameId
        end
    end

    return nil
end

local getPlayerStartingGameId = function(player: Player): string?
    for gameId, gameData in pairs(startingGames) do
        if (
            (gameData.Leader == player) or
            table.find(gameData.Players, player)
        ) then
            return gameId
        end
    end

    return nil
end

local processJoinRequest = function(gameData, player: Player): string
    -- Note: The order of access rules is important
    
    local accessRules: array<AccessRules> = gameData.AccessRules.Ruleset

    for i = 1, #accessRules do
        local rule: AccessRule = accessRules[i]
        local ruleType: string = rule.RuleType
        local ruleArguments = rule.RuleArguments 

        local ruleData = accessRuleData[ruleType]
        local extraArguments = ruleData.ExtraArguments
        local combinedRuleArguments: dictionary<string, any> = {}

        if (ruleArguments) then
            for argument, value in pairs(ruleArguments) do
                combinedRuleArguments[argument] = value
            end
        end

        if (extraArguments) then
            for argument, variable in pairs(extraArguments) do
                if (variable == "GameLeader") then
                    combinedRuleArguments[argument] = gameData.Leader
                end
            end
        end

        local callbackResult = ruleData.Callback(player, combinedRuleArguments) or GameEnum.GameAccessRuleProcessingResult.Continue
        if (callbackResult ~= GameEnum.GameAccessRuleProcessingResult.Continue) then return callbackResult end
    end

    return GameEnum.GameAccessRuleProcessingResult.AddToQueue
end

local checkGameplayData = function(gameplayData: GameplayData): boolean
    if (not table.find(mapList, gameplayData.MapName)) then return false end
    
    local checkDifficultySuccess = pcall(function()
        return GameEnum.Difficulty[gameplayData.Difficulty]
    end)

    local checkGameModeSuccess = pcall(function()
        return GameEnum.GameMode[gameplayData.GameMode]
    end)

    return (checkDifficultySuccess and checkGameModeSuccess)
end

local checkAccessRules = function(accessRules: AccessRules): boolean
    local accessRuleCounts = {}

    local checkApprovalTypeSuccess = pcall(function()
        return GameEnum.GameAccessApprovalType[accessRules.ApprovalType]
    end)

    if (not checkApprovalTypeSuccess) then return false end

    local ruleset = accessRules.Ruleset

    for i = 1, #ruleset do
        local rule = ruleset[i]
        local ruleType = rule.RuleType
        local ruleArguments = rule.RuleArguments

        local checkRuleTypeSuccess = pcall(function()
            return GameEnum.GameAccessRuleType[ruleType]
        end)

        if (not checkRuleTypeSuccess) then return false end

        accessRuleCounts[ruleType] = (accessRuleCounts[ruleType] or 0) + 1
        if (accessRuleCounts[ruleType] > 1) then return false end

        local ruleData = accessRuleData[ruleType]
        local verifyArguments = ruleData.VerifyArguments

        if (ruleArguments and verifyArguments) then
            for arg, value in pairs(ruleArguments) do
                local typeCheckSuccess = verifyArguments[arg](value)
                if (not typeCheckSuccess) then return end
            end
        end
    end

    return true
end

---

local Matchmaking = {
    GameOpened = GameOpenedEvent.Event,
    GameClosed = GameClosedEvent.Event,
    GameStarting = GameStartingEvent.Event,
    PlayerJoinedGame = PlayerJoinedGameEvent.Event,
    PlayerLeftGame = PlayerLeftGameEvent.Event,
    PlayerJoinedGameQueue = PlayerJoinedGameQueueEvent.Event,
    PlayerLeftGameQueue = PlayerLeftGameQueueEvent.Event,
}

Matchmaking.OpenGame = function(leader: Player, gameplayData, gameplayModifiers, accessRules): string?
    if (getPlayerGameId(leader) or getPlayerStartingGameId(leader)) then return end
    if (not (checkGameplayData(gameplayData) and checkAccessRules(accessRules))) then return end

    local gameId = HttpService:GenerateGUID(false)

    local gameData: GameData = {
        CreatedAt = os.clock(), -- this is NOT to be used as a timestamp, and is only for sorting games in the game list

        Leader = leader,
        Players = {},
        Queue = {},

        GameplayData = gameplayData,
        GameplayModifiers = {}, -- todo: implement gameplay modifiers
        AccessRules = accessRules
    }

    games[gameId] = gameData
    GameOpenedEvent:Fire(gameId, gameData)
end

Matchmaking.CloseGame = function(gameId: string)
    local gameData = games[gameId]
    if (not gameData) then return end

    games[gameId] = nil
    GameClosedEvent:Fire(gameId)
end

Matchmaking.AddPlayerToGame = function(gameId: string, player: Player): ActionResult
    local gameData = games[gameId]
    if (not gameData) then return end -- GameDoesNotExist

    if (getPlayerGameId(player) or getPlayerStartingGameId(player)) then return end -- PlayerIsAlreadyInAGame

    local numPlayers = #gameData.Players + 1
    if (numPlayers >= TEMP_MAX_PLAYERS) then return end -- GameIsFull

    -- todo: should players be able to join a queue even when the party is full?

    local accessRules = gameData.AccessRules
    local approvalType = accessRules.ApprovalType

    if (approvalType == GameEnum.GameAccessApprovalType.AutomaticApproval) then
        -- todo: what happens when the player list becomes full?

        table.insert(gameData.Players, player)
        PlayerJoinedGameEvent:Fire(gameId, player)
    elseif (approvalType == GameEnum.GameAccessApprovalType.ManualApproval) then
        table.insert(gameData.Queue, player)
        PlayerJoinedGameQueueEvent:Fire(gameId, player)
    elseif (approvalType == GameEnum.GameAccessApprovalType.AutoRuleset) then
        local requestResult = processJoinRequest(gameData, player)

        if (requestResult == GameEnum.GameAccessRuleProcessingResult.Approve) then
            -- todo: what happens when the player list becomes full?
            
            table.insert(gameData.Players, player)
            PlayerJoinedGameEvent:Fire(gameId, player)

            return -- JoinedGame
        elseif (requestResult == GameEnum.GameAccessRuleProcessingResult.Reject) then
            return -- JoinRequestRejected
        elseif (requestResult == GameEnum.GameAccessRuleProcessingResult.CouldNotProcess) then
            return -- CouldNotProcessJoinRequest
        elseif (requestResult == GameEnum.GameAccessRuleProcessingResult.AddToQueue) then
            table.insert(gameData.Queue, player)
            PlayerJoinedGameQueueEvent:Fire(gameId, player)

            return -- JoinedGameQueue
        end
    end
end

Matchmaking.RemovePlayerFromGame = function(gameId: string, player: Player, kicked: boolean): ActionResult
    local gameData = games[gameId]
    if (not gameId) then return end -- GameDoesNotExist
    
    local joinedGameId = getPlayerGameId(player)
    if (joinedGameId ~= gameId) then return end -- PlayerIsNotInGame

    local playerList = gameData.Players
    local queue = gameData.Queue

    local playerListIndex = table.find(playerList, player)
    local queueIndex = table.find(queue, player)

    if (playerListIndex) then
        table.remove(playerList, playerListIndex)
        PlayerLeftGameEvent:Fire(gameId, player, kicked)

        return -- LeftGame
    elseif (queueIndex) then
        table.remove(playerList, queueIndex)
        PlayerLeftGameQueueEvent:Fire(gameId, player, false)

        return -- LeftGameQueue
    end
end

Matchmaking.ApproveGameJoinRequest = function(gameId: string, player: Player) -- todo: return type
    local gameData = games[gameId]
    if (not gameId) then return false end -- GameDoesNotExist

    local joinedGameId = getPlayerGameId(player)
    if (joinedGameId ~= gameId) then return false end -- PlayerIsNotInGame

    local numPlayers = #gameData.Players + 1
    if (numPlayers >= TEMP_MAX_PLAYERS) then return false end -- GameIsFull

    local queue = gameData.Queue
    local queueIndex = table.find(queue, player)
    if (not queueIndex) then return false end -- PlayerIsNotInGameQueue

    table.remove(queue, queueIndex)
    PlayerLeftGameQueueEvent:Fire(gameId, player, true)

    table.insert(gameData.Players, player)
    PlayerJoinedGameEvent:Fire(gameId, player)

    return true
end

Matchmaking.RejectGameJoinRequest = function(gameId: string, player: Player)
    local gameData = games[gameId]
    if (not gameId) then return false end -- GameDoesNotExist

    local joinedGameId = getPlayerGameId(player)
    if (joinedGameId ~= gameId) then return false end -- PlayerIsNotInGame

    local queue = gameData.Queue
    local queueIndex = table.find(queue, player)
    if (not queueIndex) then return false end -- PlayerIsNotInGameQueue

    table.remove(queue, queueIndex)
    PlayerLeftGameQueueEvent:Fire(gameId, player, false)

    return true
end

Matchmaking.StartGame = function(gameId: string)
    local gameData = games[gameId]
    if (not gameData) then return end

    local playerList = gameData.Players
    local players = {}

    table.insert(players, gameData.Leader)

    for i = 1, #playerList do
        table.insert(players, playerList[i])
    end

    startingGames[gameId] = gameData
    games[gameId] = nil
    GameStartingEvent:Fire(gameId)

    Promise.new(function(resolve)
        local serverAccessCode, privateServerId = TeleportService:ReserveServer(6432648941)
        GameDataStore:SetAsync(privateServerId, gameData.GameplayData)

        resolve(serverAccessCode)
    end):andThen(function(serverAccessCode)
        Promise.delay(20):andThen(function()
            if (startingGames[gameId]) then
                startingGames[gameId] = nil
            end
        end)

        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ReservedServerAccessCode = serverAccessCode

        Matchmaking.DispatchTeleportNotification(gameId)
        TeleportService:TeleportAsync(6432648941, players, teleportOptions)
    end, function(error)
        warn(tostring(error))

        games[gameId] = gameData
        startingGames[gameId] = nil

        GameOpenedEvent:Fire(gameId, gameData)
        Matchmaking.DispatchInitFailureNotification(gameId)
    end)
end

Matchmaking.DispatchTeleportNotification = function(gameId: string)
    local gameData = startingGames[gameId]
    if (not gameData) then return end

    local playerList = gameData.Players

    TeleportNotifcationRemoteEvent:FireClient(gameData.Leader)

    for i = 1, #playerList do
        TeleportNotifcationRemoteEvent:FireClient(playerList[i])
    end
end

Matchmaking.DispatchInitFailureNotification = function(gameId: string)
    local gameData = games[gameId]
    if (not gameData) then return end

    local playerList = gameData.Players

    GameInitFailureNotificationRemoteEvent:FireClient(gameData.Leader)

    for i = 1, #playerList do
        GameInitFailureNotificationRemoteEvent:FireClient(playerList[i])
    end
end

Matchmaking.GetGameData = function(gameId: string): GameData?
    return CopyTable(games[gameId])
end

Matchmaking.GetGames = function(): dictionary<string, GameData>
    return CopyTable(games)
end

Matchmaking.GetMaps = function(): array<string>
    return CopyTable(mapList)
end

---

do
    local maps = MapData:GetChildren()

    for i = 1, #maps do
        table.insert(mapList, maps[i].Name)
    end
end

Players.PlayerRemoving:Connect(function(player)
    local joinedGameId = getPlayerGameId(player)
    local joinedStartingGameId = getPlayerStartingGameId(player)

    if (joinedGameId) then
        local gameData = games[joinedGameId]
        if (not gameData) then return end

        if (gameData.Leader == player) then
            Matchmaking.CloseGame(joinedGameId)
        else
            Matchmaking.RemovePlayerFromGame(joinedGameId, player, false)
        end
    elseif (joinedStartingGameId) then
        local gameData = startingGames[joinedStartingGameId]

        if (gameData.Leader == player) then
            gameData.Leader = nil
        else
            local playerList = gameData.Players
            local playerIndex = table.find(playerList, player)

            table.remove(playerList, playerIndex)
        end

        if ((not gameData.Leader) and (#gameData.Players < 1)) then
            startingGames[joinedStartingGameId] = nil
        end
    end
end)

System.addEvent("GameOpened", Matchmaking.GameOpened)
System.addEvent("GameClosed", Matchmaking.GameClosed)
System.addEvent("GameStarting", Matchmaking.GameStarting)
System.addEvent("PlayerJoinedGame", Matchmaking.PlayerJoinedGame)
System.addEvent("PlayerLeftGame", Matchmaking.PlayerLeftGame)
System.addEvent("PlayerJoinedGameQueue", Matchmaking.PlayerJoinedGameQueue)
System.addEvent("PlayerLeftGameQueue", Matchmaking.PlayerLeftGameQueue)

System.addFunction("OpenGame", t.wrap(function(callingPlayer: Player, player: Player, gameplayData, gameplayModifiers, accessRules)
    if (player ~= callingPlayer) then return end

    return Matchmaking.OpenGame(player, gameplayData, gameplayModifiers, accessRules)
end, t.tuple(t.instanceOf("Player"), t.instanceOf("Player"), gameplayDataType, t.table, accessRulesDataType)), true)

System.addFunction("CloseGame", t.wrap(function(callingPlayer: Player, gameId: string)
    local gameData = games[gameId]
    if (not gameData) then return end
    if (gameData.Leader ~= callingPlayer) then return end

    return Matchmaking.CloseGame(gameId)
end, t.tuple(t.instanceOf("Player"), t.string)), true)

System.addFunction("StartGame", t.wrap(function(callingPlayer: Player, gameId: string)
    local gameData = games[gameId]
    if (not gameData) then return end
    if (gameData.Leader ~= callingPlayer) then return end

    Matchmaking.StartGame(gameId)
end, t.tuple(t.instanceOf("Player"), t.string)))

System.addFunction("AddPlayerToGame", t.wrap(function(callingPlayer: Player, gameId: string, player: Player)
    if (player ~= callingPlayer) then return end

    return Matchmaking.AddPlayerToGame(gameId, player)
end, t.tuple(t.instanceOf("Player"), t.string, t.instanceOf("Player"))), true)

System.addFunction("RemovePlayerFromGame", t.wrap(function(callingPlayer: Player, gameId: string, player: Player)
    if (player ~= callingPlayer) then
        local gameData = games[gameId]
        if (not gameData) then return end -- todo: should return ActionResult

        local queue = gameData.Queue
        local queueIndex = table.find(queue, player)

        if ((gameData.Leader == callingPlayer) and (not queueIndex)) then
            -- party leaders cannot use RemovePlayerFromGame to remove players from the queue
            return Matchmaking.RemovePlayerFromGame(gameId, player, true)
        else
            return -- todo: should return ActionResult
        end
    else
        return Matchmaking.RemovePlayerFromGame(gameId, player, false)
    end
end, t.tuple(t.instanceOf("Player"), t.string, t.instanceOf("Player"))), true)

System.addFunction("ApproveGameJoinRequest", t.wrap(function(callingPlayer: Player, gameId: string, player: Player)
    local gameData = games[gameId]
    if (not gameData) then return end
    if (gameData.Leader ~= callingPlayer) then return end

    return Matchmaking.ApproveGameJoinRequest(gameId, player)
end, t.tuple(t.instanceOf("Player"), t.string, t.instanceOf("Player"))), true)

System.addFunction("RejectGameJoinRequest", t.wrap(function(callingPlayer: Player, gameId: string, player: Player)
    local gameData = games[gameId]
    if (not gameData) then return end
    if (gameData.Leader ~= callingPlayer) then return end

    return Matchmaking.RejectGameJoinRequest(gameId, player)
end, t.tuple(t.instanceOf("Player"), t.string, t.instanceOf("Player"))), true)

System.addFunction("GetGames", Matchmaking.GetGames, true)
System.addFunction("GetMaps", Matchmaking.GetMaps, true)

return Matchmaking