local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Button = require(GameUIModules:WaitForChild("Button"))
local Color = require(GameUIModules:WaitForChild("Color"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Matchmaking = require(GameModules:WaitForChild("Matchmaking"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local gameListElementColors = {
    Color3.fromRGB(255, 85, 127),
    Color3.fromRGB(255, 170, 127),
    Color3.fromRGB(0, 170, 127),
}

local getSortedGameList = function()
    local gameList = Matchmaking.GetGames()
    local gameListSorted = {}

    for gameId, gameData in pairs(gameList) do
        gameData.Id = gameId

        table.insert(gameListSorted, gameData)
    end

    table.sort(gameListSorted, function(a, b)
        return a.CreatedAt < b.CreatedAt
    end)

    return gameListSorted
end

local getPlayerGameId = function(gameList, player: Player): string?
    for i = 1, #gameList do
        local gameData = gameList[i]

        if (
            (gameData.Leader == player) or
            table.find(gameData.Players, player) or
            table.find(gameData.Queue, player)
        ) then
            return gameData.Id
        end
    end

    return nil
end

local getAccessTypeString = function(accessRules): string
    local approvalType = accessRules.ApprovalType

    if (approvalType == GameEnum.GameAccessApprovalType.AutomaticApproval) then
        return "Open to Everyone"
    elseif (approvalType == GameEnum.GameAccessApprovalType.ManualApproval) then
        return "Manual Approval"
    elseif (approvalType == GameEnum.GameAccessApprovalType.AutoRuleset) then
        -- TODO
        return "Friends Only"
    end
end

---

--[[
    props

        AnchorPoint?
        Position?
        LayoutOrder?
        Image?

        Header: string
        Text: string

        disabled: boolean?
        onActivated: ()
]]

local CreateGameButton = Roact.PureComponent:extend("CreateGameButton")

CreateGameButton.render = function(self)
    return Roact.createElement(Button, {
        AnchorPoint = self.props.AnchorPoint,
        Size = UDim2.new(1, 0, 0.5, -Style.Constants.MajorElementPadding / 2),
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,

        displayType = "Children",
        disabled = self.props.disabled,
        onActivated = self.props.onActivated,
    }, {
        BackgroundImage = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, -Style.Constants.MajorElementPadding, 1, -Style.Constants.MajorElementPadding),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Image = self.props.Image or "rbxasset://textures/ui/GuiImagePlaceholder.png",
            ScaleType = Enum.ScaleType.Crop,

            ImageColor3 = Color3.new(1, 1, 1)
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, -Style.Constants.MajorElementPadding, 1, -Style.Constants.MajorElementPadding),
                Position = UDim2.new(0.5, 0, 0.5, 0),
    
                Text = self.props.Header,
                TextSize = Style.Constants.SecondaryHeaderTextSize,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextStrokeTransparency = 0.5,
            }),

            Description = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, -Style.Constants.MajorElementPadding, 1, -Style.Constants.MajorElementPadding),
                Position = UDim2.new(0.5, 0, 0.5, 0),
    
                Text = self.props.Text,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                TextWrapped = true,
                TextStrokeTransparency = 0.5,
            }),
        })
    })
end

---

--[[
    props

        onCreateSimpleGame: ()
        onCreateFullGame: ()
]]

local GameListPage = Roact.PureComponent:extend("GameListPage")

GameListPage.init = function(self)
    self.gameListLength, self.updateGameListLength = Roact.createBinding(0)
    self.playerListLength, self.updatePlayerListLength = Roact.createBinding(0)

    self.updateGameList = function()
        self:setState({
            gameList = getSortedGameList()
        })
    end

    self:setState({
        gameList = {},
    })
end

GameListPage.didMount = function(self)
    self.gameOpened = Matchmaking.GameOpened:Connect(function(gameId, gameData)
        self.updateGameList()
        
        if ((gameData.Leader == LocalPlayer) or table.find(gameData, LocalPlayer)) then
            self:setState({
                currentParty = gameId
            })
        end
    end)

    self.gameClosed = Matchmaking.GameClosed:Connect(function(gameId)
        if (self.state.currentParty == gameId) then
            self:setState({
                currentParty = Roact.None
            })
        end
        
        self.updateGameList()
    end)

    self.gameStarting = Matchmaking.GameStarting:Connect(function(gameId)
        if (self.state.currentParty == gameId) then
            self:setState({
                currentParty = Roact.None
            })
        end
        
        self.updateGameList()
    end)

    self.playerJoinedGame = Matchmaking.PlayerJoinedGame:Connect(function(gameId, player)
        self.updateGameList()
        
        if (player == LocalPlayer) then
            self:setState({
                currentParty = gameId
            })
        end
    end)

    self.playerLeftGame = Matchmaking.PlayerLeftGame:Connect(function(_, player, _)
        if (player == LocalPlayer) then
            self:setState({
                currentParty = Roact.None
            })
        end
        
        self.updateGameList()
    end)

    self.playerJoinedGameQueue = Matchmaking.PlayerJoinedGameQueue:Connect(function(gameId, player)
        self.updateGameList()

        if (player == LocalPlayer) then
            self:setState({
                currentParty = gameId
            })
        end
    end)

    self.playerLeftGameQueue = Matchmaking.PlayerLeftGameQueue:Connect(function(_, player, joined)
        if ((player == LocalPlayer) and (not joined)) then
            self:setState({
                currentParty = Roact.None
            })
        end
        
        self.updateGameList()
    end)

    local gameList = getSortedGameList()
    local joinedGameId = getPlayerGameId(gameList, LocalPlayer)

    self:setState({
        gameList = gameList,
        currentParty = joinedGameId,
        playerListView = "PlayerList",
    })
end

GameListPage.willUnmount = function(self)
    self.gameOpened:Disconnect()
    self.gameClosed:Disconnect()
    self.gameStarting:Disconnect()
    self.playerJoinedGame:Disconnect()
    self.playerLeftGame:Disconnect()
    self.playerJoinedGameQueue:Disconnect()
    self.playerLeftGameQueue:Disconnect()
end

GameListPage.render = function(self)
    local gameList = self.state.gameList
    local playerListView = self.state.playerListView

    local currentParty = self.state.currentParty
    local currentGameData = currentParty and Matchmaking.GetGameData(currentParty) or nil
    local currentGamePlayerList = currentGameData and currentGameData.Players or nil
    local currentGameQueue = currentGameData and currentGameData.Queue or nil

    local isCurrentPartyLeader
    local partyRedButtonText
    local partySubheaderText

    local gameListElements = {}
    local playerListElements = {}

    -- game list
    for i = 1, #gameList do
        local gameData = gameList[i]
        local gameId = gameData.Id
        local gameplayData = gameData.GameplayData
        local playerList = gameData.Players
        local queue = gameData.Queue

        local joinButtonText

        if (currentParty == gameId) then
            if (table.find(playerList, LocalPlayer) or (gameData.Leader == LocalPlayer)) then
                joinButtonText = "Current Party"
            elseif (table.find(queue, LocalPlayer)) then
                joinButtonText = "In Queue"
            end
        else
            joinButtonText = string.format("Join (%d/%d)", #playerList + 1, 4)
        end

        local elementBackgroundColor
        local gameInfoTextColor

        if (currentParty) then
            -- TODO: fix the hole
            local colorIndex = i % #gameListElementColors

            elementBackgroundColor = (currentParty == gameId) and Style.Colors.SelectionColor or
                gameListElementColors[(colorIndex ~= 0) and colorIndex or #gameListElementColors]
        else
            local colorIndex = i % #gameListElementColors

            elementBackgroundColor = gameListElementColors[(colorIndex ~= 0) and colorIndex or #gameListElementColors]
        end

        gameInfoTextColor = Color.from("Color3", elementBackgroundColor):bestContrastingColor(
            Color.new(0, 0, 0),
            Color.new(1, 1, 1)
        ):to("Color3")

        gameListElements[gameId] = Roact.createElement("Frame", {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, 132),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = (currentParty == gameId) and 0 or i,

            BackgroundColor3 = elementBackgroundColor,
        }, {
            UICorner = Roact.createElement(StandardUICorner),
            UIPadding = Roact.createElement(StandardUIPadding),

            GameInfoContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                MapNameLabel = Roact.createElement(StandardTextLabel, {
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                    LayoutOrder = 0,
                    Text = gameplayData.MapName,
            
                    TextColor3 = gameInfoTextColor,
                }),
                
                LeaderNameLabel = Roact.createElement(StandardTextLabel, {
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                    LayoutOrder = 1,
                    Text = gameData.Leader.Name,
            
                    TextColor3 = gameInfoTextColor,
                }),

                DifficultyLabel = Roact.createElement(StandardTextLabel, {
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                    LayoutOrder = 2,
                    Text = gameplayData.Difficulty,
            
                    TextColor3 = gameInfoTextColor,
                }),

                AccessLabel = Roact.createElement(StandardTextLabel, {
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                    LayoutOrder = 3,
                    Text = getAccessTypeString(gameData.AccessRules),
            
                    TextColor3 = gameInfoTextColor,
                }),

                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.Constants.MinorElementPadding),
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                })
            }),

            JoinButton = Roact.createElement(Button, {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight),
                Position = UDim2.new(0.5, 0, 1, 0),

                Text = joinButtonText,
        
                BackgroundColor3 = (currentParty == gameId) and Style.Colors.SelectionColor or Style.Colors.StandardButtonColor,
                TextColor3 = (currentParty == gameId) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),

                displayType = "Text",
                disabled = (currentParty == gameId),

                onActivated = function()
                    if (currentParty == gameId) then return end

                    if (currentParty and ((currentGameData.Leader ~= LocalPlayer)))  then
                        Matchmaking.RemovePlayerFromGame(gameId, LocalPlayer)
                    end

                    Matchmaking.AddPlayerToGame(gameId, LocalPlayer)
                end,
            }),
        })
    end

    -- player list
    if (currentParty) then
        isCurrentPartyLeader = (currentGameData.Leader == LocalPlayer)

        if (currentGameData.Leader == LocalPlayer) then
            partySubheaderText = (playerListView == "PlayerList") and "Players" or "Queue"
            partyRedButtonText = "Close Game"
        elseif (table.find(currentGamePlayerList, LocalPlayer)) then
            partySubheaderText = "Players"
            partyRedButtonText = "Leave Game"
        elseif (table.find(currentGameQueue, LocalPlayer)) then
            partySubheaderText = "Queue"
            partyRedButtonText = "Leave Queue"
        end

        local players = {}

        if (playerListView == "PlayerList") then
            players[1] = currentGameData.Leader

            for i = 1, #currentGamePlayerList do
                table.insert(players, currentGamePlayerList[i])
            end
        elseif (playerListView == "Queue") then
            players = currentGameQueue
        end

        for i = 1, #players do
            local player = players[i]

            playerListElements[player.UserId] = Roact.createElement("Frame", {
                Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, 64),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                LayoutOrder = i,

                BackgroundColor3 = Style.Colors.StandardButtonColor,
            }, {
                UICorner = Roact.createElement(StandardUICorner),
                UIPadding = Roact.createElement(StandardUIPadding),

                AvatarImage = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 48, 0, 48),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Image = "rbxthumb://type=Avatar&id=" .. player.UserId .. "&w=100&h=100",
                }),

                PlayerInfoContainer = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(1, -(48 + Style.Constants.SpaciousElementPadding), 1, 0),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    PlayerName = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(0.5, 0),
                        Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                        Position = UDim2.new(0.5, 0, 0, 0),
                
                        Text = player.Name,
                        TextScaled = true,
                
                        TextColor3 = Color3.new(0, 0, 0),
                    }),

                    LeaderLabel = (player == currentGameData.Leader) and
                        Roact.createElement(StandardTextLabel, {
                            AnchorPoint = Vector2.new(0.5, 0),
                            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                            Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardTextSize + Style.Constants.MinorElementPadding),

                            Text = "Leader",
                            Font = Style.Constants.SecondaryFont,
                    
                            TextColor3 = Color3.new(0, 0, 0),
                        })
                    or nil,

                    RedButton = (isCurrentPartyLeader and ((playerListView == "Queue") or ((playerListView == "PlayerList") and (player ~= currentGameData.Leader)))) and 
                        Roact.createElement(Button, {
                            AnchorPoint = Vector2.new(1, 1),
                            Position = UDim2.new(1, 0, 1, 0),
                            Text = (playerListView == "Queue") and "Reject" or "Kick",

                            Size = UDim2.new(
                                (playerListView == "Queue") and
                                    UDim.new(0.5, -Style.Constants.SpaciousElementPadding / 2)
                                or UDim.new(1, 0),

                                UDim.new(0, Style.Constants.StandardButtonHeight)
                            ),

                            BackgroundColor3 = Style.Colors.DestructiveButtonColor,
                            TextColor3 = Color3.new(1, 1, 1),

                            displayType = "Text",
                            onActivated = function()
                                if (playerListView == "Queue") then
                                    Matchmaking.RejectGameJoinRequest(currentParty, player)
                                else
                                    Matchmaking.RemovePlayerFromGame(currentParty, player)
                                end
                            end
                        })
                    or nil,

                    ApproveButton = (isCurrentPartyLeader and (playerListView == "Queue")) and
                        Roact.createElement(Button, {
                            AnchorPoint = Vector2.new(0, 1),
                            Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.StandardButtonHeight),
                            Position = UDim2.new(0, 0, 1, 0),
                            Text = "Accept",

                            BackgroundColor3 = Style.Colors.ConfirmButtonColor,
                            TextColor3 = Color3.new(0, 0, 0),

                            displayType = "Text",
                            onActivated = function()
                                Matchmaking.ApproveGameJoinRequest(currentParty, player)
                            end
                        })
                    or nil,
                }),
            })
        end

        playerListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updatePlayerListLength(obj.AbsoluteContentSize.Y)
            end
        })
    end

    gameListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),

        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateGameListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createFragment({
        GamesList = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0.5, -Style.Constants.MajorElementPadding / 2, 1, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
                Position = UDim2.new(0.5, 0, 0, 0),
    
                Text = "Games",
                TextSize = Style.Constants.PrimaryHeaderTextSize,
            }),

            Games = Roact.createElement(StandardScrollingFrame, {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -(Style.Constants.PrimaryHeaderTextSize + Style.Constants.MajorElementPadding)),
                Position = UDim2.new(0.5, 0, 1, 0),
                
                CanvasSize = self.gameListLength:map(function(length)
                    return UDim2.new(0, 0, 0, length)
                end),
            }, gameListElements)
        }),

        CreateGameButtons = (not currentParty) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.5, -Style.Constants.MajorElementPadding / 2, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                Header = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
                    Position = UDim2.new(0.5, 0, 0, 0),
        
                    Text = "New Game",
                    TextSize = Style.Constants.PrimaryHeaderTextSize,
                }),

                Buttons = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 1, -(Style.Constants.PrimaryHeaderTextSize + Style.Constants.MajorElementPadding)),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    SimpleGameButton = Roact.createElement(CreateGameButton, {
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5, 0, 0, 0),

                        Header = "Simple",
                        Text = "For those who want a quick or easy-to-setup game",

                        onActivated = self.props.onCreateSimpleGame,
                    }),

                    FullGameButton = Roact.createElement(CreateGameButton, {
                        AnchorPoint = Vector2.new(0.5, 1),
                        Position = UDim2.new(0.5, 0, 1, 0),

                        Header = "Full",
                        Text = "Available in a future update",

                        disabled = true,
                        onActivated = self.props.onCreateFullGame,
                    })
                })
            })
        or nil,

        Party = (currentParty) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.5, -Style.Constants.MajorElementPadding / 2, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                Header = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
                    Position = UDim2.new(0.5, 0, 0, 0),
        
                    Text = "Party",
                    TextSize = Style.Constants.PrimaryHeaderTextSize,
                }),

                Subheader = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),
                    Position = UDim2.new(0.5, 0, 0, Style.Constants.PrimaryHeaderTextSize + Style.Constants.SpaciousElementPadding),
        
                    Text = partySubheaderText,
                    TextSize = Style.Constants.SecondaryHeaderTextSize,
                }),

                PlayerList = Roact.createElement(StandardScrollingFrame, {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new(0.5, 0, 1, -((Style.Constants.StandardButtonHeight * 2) + (Style.Constants.SpaciousElementPadding * 2))),

                    Size = UDim2.new(1, 0, 1, -(
                        Style.Constants.PrimaryHeaderTextSize +
                        Style.Constants.SecondaryHeaderTextSize +
                        (Style.Constants.StandardButtonHeight * 2) +
                        (Style.Constants.SpaciousElementPadding * 4)
                    )),

                    CanvasSize = self.playerListLength:map(function(length)
                        return UDim2.new(0, 0, 0, length)
                    end),
                }, playerListElements),

                Buttons = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, (Style.Constants.StandardButtonHeight * 2) + Style.Constants.SpaciousElementPadding),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                }, {
                    RedButton = Roact.createElement(Button, {
                        LayoutOrder = 0,
                        Text = partyRedButtonText,

                        BackgroundColor3 = Style.Colors.DestructiveButtonColor,
                        TextColor3 = Color3.new(1, 1, 1),

                        displayType = "Text",
                        onActivated = function()
                            if (isCurrentPartyLeader) then
                                Matchmaking.CloseGame(currentParty)
                            else
                                Matchmaking.RemovePlayerFromGame(currentParty, LocalPlayer)
                            end
                        end,
                    }),

                    StartGameButton = (isCurrentPartyLeader) and
                        Roact.createElement(Button, {
                            LayoutOrder = 1,
                            Text = "Start Game",

                            BackgroundColor3 = Style.Colors.DialogButtonColor,
                            TextColor3 = Color3.new(1, 1, 1),

                            displayType = "Text",
                            onActivated = function()
                                Matchmaking.StartGame(currentParty)
                            end,
                        })
                    or nil,

                    TogglePlayerListButton = (isCurrentPartyLeader) and
                        Roact.createElement(Button, {
                            LayoutOrder = 2,

                            Text = string.format(
                                (playerListView == "PlayerList") and "Queue (%d)" or "Players (%d)",
                                (playerListView == "PlayerList") and #currentGameQueue or (#currentGamePlayerList + 1)
                            ),

                            displayType = "Text",
                            onActivated = function()
                                self:setState({
                                    playerListView = (playerListView == "PlayerList") and "Queue" or "PlayerList"
                                })
                            end,
                        })
                    or nil,

                    UIGridLayout = Roact.createElement(StandardComponents.UIGridLayout, {
                        CellSize = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0.5, -Style.Constants.SpaciousElementPadding / 2),
                        VerticalAlignment = Enum.VerticalAlignment.Bottom,
                    })
                })
            })
        or nil,
    })
end

return GameListPage