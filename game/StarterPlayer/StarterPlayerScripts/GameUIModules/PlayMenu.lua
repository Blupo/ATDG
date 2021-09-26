local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Matchmaking = require(GameModules:WaitForChild("Matchmaking"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Padding = require(GameUIModules:WaitForChild("Padding"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

local PlayMenuMainPage = Roact.PureComponent:extend("PlayMenuMainPage")
local SimpleGameCreationPage = Roact.PureComponent:extend("GameCreationPage")

---

local difficultyDescriptions = {
    [GameEnum.Difficulty.Easy] = "Enemy Units are easier to deal with.",
    [GameEnum.Difficulty.Normal] = "",
    [GameEnum.Difficulty.Hard] = "Enemy Units are more difficult to deal with, and less Points are given at the start of each round.",
}

local difficultyLayoutOrders = {
    [GameEnum.Difficulty.Easy] = 0,
    [GameEnum.Difficulty.Normal] = 1,
    [GameEnum.Difficulty.Hard] = 2,
}

local accessKeys = { "OpenAccess", "ClosedAccess", "FriendsOnly" }

local accessButtonTexts = {
    OpenAccess = "Open Access",
    ClosedAccess = "Closed Access",
    FriendsOnly = "Friends Only",
}

local pages = {
    {
        name = "MainMenu",
        element = PlayMenuMainPage,
    },

    {
        name = "SimpleGameCreation",
        element = SimpleGameCreationPage,
    }
}

local getAccessTypeString = function(accessRules): string
    local approvalType = accessRules.ApprovalType

    if (approvalType == GameEnum.GameAccessApprovalType.AutomaticApproval) then
        return "Open to Everyone"
    elseif (approvalType == GameEnum.GameAccessApprovalType.ManualApproval) then
        return "Manual Approval"
    elseif (approvalType == GameEnum.GameAccessApprovalType.AutoRuleset) then
        -- todo
        return "Friends Only"
    end
end

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

---


PlayMenuMainPage.init = function(self)
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

PlayMenuMainPage.didMount = function(self)
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

PlayMenuMainPage.willUnmount = function(self)
    self.gameOpened:Disconnect()
    self.gameClosed:Disconnect()
    self.gameStarting:Disconnect()
    self.playerJoinedGame:Disconnect()
    self.playerLeftGame:Disconnect()
    self.playerJoinedGameQueue:Disconnect()
    self.playerLeftGameQueue:Disconnect()
end

PlayMenuMainPage.render = function(self)
    local gameList = self.state.gameList
    local playerListView = self.state.playerListView

    local currentParty = self.state.currentParty
    local currentGameData = currentParty and Matchmaking.GetGameData(currentParty) or nil
    local currentGamePlayerList = currentGameData and currentGameData.Players or nil
    local currentGameQueue = currentGameData and currentGameData.Queue or nil

    local isCurrentPartyLeader
    local partyCloseButtonText
    local subHeaderText

    local gameListElements = {}
    local playerListElements = {}

    if (currentParty) then
        isCurrentPartyLeader = (currentGameData.Leader == LocalPlayer)

        if (currentGameData.Leader == LocalPlayer) then
            subHeaderText = (playerListView == "PlayerList") and "Players" or "Queue"
            partyCloseButtonText = "Close Game"
        elseif (table.find(currentGamePlayerList, LocalPlayer)) then
            subHeaderText = "Players"
            partyCloseButtonText = "Leave Game"
        elseif (table.find(currentGameQueue, LocalPlayer)) then
            subHeaderText = "Queue"
            partyCloseButtonText = "Leave Queue"
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
                Size = UDim2.new(1, 0, 0, 64),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                LayoutOrder = i,

                BackgroundColor3 = Color3.fromRGB(240, 240, 240),
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
                }),

                AvatarImage = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 64, 0, 64),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Image = "rbxthumb://type=Avatar&id=" .. player.UserId .. "&w=100&h=100",
                    ImageColor3 = Color3.new(1, 1, 1)
                }),

                PlayerInfoContainer = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(1, -80, 1, -16),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    PlayerName = Roact.createElement("TextLabel", {
                        AnchorPoint = Vector2.new(0.5, 0),
                        Size = UDim2.new(1, 0, 0, 16),
                        Position = UDim2.new(0.5, 0, 0, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                
                        Text = player.Name,
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextScaled = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                
                        TextColor3 = Color3.new(0, 0, 0),
                    }),

                    LeaderLabel = (player == currentGameData.Leader) and
                        Roact.createElement("TextLabel", {
                            AnchorPoint = Vector2.new(0.5, 0),
                            Size = UDim2.new(1, 0, 0, 16),
                            Position = UDim2.new(0.5, 0, 0, 20),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                    
                            Text = "Leader",
                            Font = Enum.Font.Gotham,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,
                    
                            TextColor3 = Color3.new(0, 0, 0),
                        })
                    or nil,

                    KickButton = (isCurrentPartyLeader and (player ~= currentGameData.Leader) and (playerListView == "PlayerList")) and
                        Roact.createElement("TextButton", {
                            AnchorPoint = Vector2.new(0.5, 1),
                            Size = UDim2.new(1, 0, 0, 24),
                            Position = UDim2.new(0.5, 0, 1, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            LayoutOrder = 0,
                
                            Text = "Kick",
                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                    
                            BackgroundColor3 = Color3.new(1, 0, 0),
                            TextColor3 = Color3.new(1, 1, 1),
                
                            [Roact.Event.Activated] = function()
                                Matchmaking.RemovePlayerFromGame(currentParty, player)
                            end
                        }, {
                            UICorner = Roact.createElement("UICorner", {
                                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                            }),
                        })
                    or nil,

                    ApproveButton = (isCurrentPartyLeader and (playerListView == "Queue")) and
                        Roact.createElement("TextButton", {
                            AnchorPoint = Vector2.new(0, 1),
                            Size = UDim2.new(0.5, -4, 0, 24),
                            Position = UDim2.new(0, 0, 1, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            LayoutOrder = 0,
                
                            Text = "Accept",
                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                    
                            BackgroundColor3 = Color3.new(0, 1, 0),
                            TextColor3 = Color3.new(0, 0, 0),
                
                            [Roact.Event.Activated] = function()
                                Matchmaking.ApproveGameJoinRequest(currentParty, player)
                            end
                        }, {
                            UICorner = Roact.createElement("UICorner", {
                                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                            }),
                        })
                    or nil,

                    RejectButton = (isCurrentPartyLeader and (playerListView == "Queue")) and
                        Roact.createElement("TextButton", {
                            AnchorPoint = Vector2.new(1, 1),
                            Size = UDim2.new(0.5, -4, 0, 24),
                            Position = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            LayoutOrder = 0,
                
                            Text = "Reject",
                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                    
                            BackgroundColor3 = Color3.new(1, 0, 0),
                            TextColor3 = Color3.new(1, 1, 1),
                
                            [Roact.Event.Activated] = function()
                                Matchmaking.RejectGameJoinRequest(currentParty, player)
                            end
                        }, {
                            UICorner = Roact.createElement("UICorner", {
                                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                            }),
                        })
                    or nil,
                }),
            })
        end

        playerListElements.UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, 4),
    
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updatePlayerListLength(obj.AbsoluteContentSize.Y)
            end
        })
    end

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

        gameListElements[gameId] = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 116),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = (currentParty == gameId) and 0 or i,
        }, {
            GameInfoContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, -16, 1, -40),
                Position = UDim2.new(0.5, 0, 0, 8),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, {
                LeaderNameLabel = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
            
                    Text = gameData.Leader.Name,
                    Font = Enum.Font.Gotham,
                    TextSize = 16,
                    TextStrokeTransparency = 0.75,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
            
                    TextColor3 = Color3.new(1, 1, 1),
                    TextStrokeColor3 = Color3.new(0, 0, 0)
                }),

                MapNameLabel = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 0,
            
                    Text = gameplayData.MapName,
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextStrokeTransparency = 0.75,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
            
                    TextColor3 = Color3.new(1, 1, 1),
                    TextStrokeColor3 = Color3.new(0, 0, 0)
                }),

                DifficultyLabel = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,
            
                    Text = gameplayData.Difficulty,
                    Font = Enum.Font.Gotham,
                    TextSize = 16,
                    TextStrokeTransparency = 0.75,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
            
                    TextColor3 = Color3.new(1, 1, 1),
                    TextStrokeColor3 = Color3.new(0, 0, 0)
                }),

                AccessLabel = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 3,
            
                    Text = getAccessTypeString(gameData.AccessRules),
                    Font = Enum.Font.Gotham,
                    TextSize = 16,
                    TextStrokeTransparency = 0.75,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
            
                    TextColor3 = Color3.new(1, 1, 1),
                    TextStrokeColor3 = Color3.new(0, 0, 0)
                }),

                UIListLayout = Roact.createElement("UIListLayout", {
                    Padding = UDim.new(0, 4),
            
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                })
            }),

            JoinButton = Roact.createElement("TextButton", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 0, 24),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                Text = joinButtonText,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                BackgroundColor3 = (currentParty == gameId) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(230, 230, 230),
                TextColor3 = (currentParty == gameId) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),

                [Roact.Event.Activated] = function()
                    if (currentParty == gameId) then return end

                    if (currentParty and ((currentGameData.Leader ~= LocalPlayer)))  then
                        Matchmaking.RemovePlayerFromGame(gameId, LocalPlayer)
                    end

                    Matchmaking.AddPlayerToGame(gameId, LocalPlayer)
                end
            }),

            MapImage = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 1, -24),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
                ScaleType = Enum.ScaleType.Crop,

                ImageColor3 = Color3.new(1, 1, 1)
            }, {
                UIGradient = Roact.createElement("UIGradient", {
                    Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.5, 0.5, 0.5)),
                    Rotation = 90,
                })
            })
        })
    end

    gameListElements.UIListLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),

        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateGameListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.new(1, 1, 1)
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
        }),

        Padding = Roact.createElement(Padding, { Style.Constants.MajorElementPadding }),

        JoinGameContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0.5, -8, 1, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Header = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
        
                Text = "Join a Game",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                TextColor3 = Color3.new(0, 0, 0)
            }),

            GameList = Roact.createElement("ScrollingFrame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -40),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,

                CanvasSize = self.gameListLength:map(function(length)
                    return UDim2.new(0, 0, 0, length)
                end),

                VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
                ScrollBarThickness = 6,

                ScrollBarImageColor3 = Color3.new(0, 0, 0)
            }, gameListElements)
        }),

        CreateGameContainer = (not currentParty) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.5, -8, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                Header = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = "Create a Game",
                    Font = Style.Constants.MainFont,
                    TextSize = 32,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                Buttons = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 1, -40),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    SimpleGameButton = Roact.createElement("TextButton", {
                        AnchorPoint = Vector2.new(0.5, 0),
                        Size = UDim2.new(1, 0, 0.5, -8),
                        Position = UDim2.new(0.5, 0, 0, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,

                        [Roact.Event.Activated] = function()
                            self.props.updateSelectedPage("SimpleGameCreation")
                        end,
                    }, {
                        Header = Roact.createElement("TextLabel", {
                            AnchorPoint = Vector2.new(0.5, 0),
                            Size = UDim2.new(1, -16, 0, 32),
                            Position = UDim2.new(0.5, 0, 0, 8),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,

                            Text = "Simple",
                            Font = Style.Constants.MainFont,
                            TextSize = 32,
                            TextStrokeTransparency = 0.75,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,

                            TextColor3 = Color3.new(1, 1, 1),
                            TextStrokeColor3 = Color3.new(0, 0, 0)
                        }),

                        DescriptorText = Roact.createElement("TextLabel", {
                            AnchorPoint = Vector2.new(0.5, 1),
                            Size = UDim2.new(1, -16, 0, 64),
                            Position = UDim2.new(0.5, 0, 1, -8),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,

                            Text = "For those who want a quick or easy-to-setup game",
                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextStrokeTransparency = 0.75,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Bottom,

                            TextColor3 = Color3.new(1, 1, 1),
                            TextStrokeColor3 = Color3.new(0, 0, 0)
                        }),

                        MapImage = Roact.createElement("ImageLabel", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(1, 0, 1, 0),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,

                            Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
                            ScaleType = Enum.ScaleType.Crop,

                            ImageColor3 = Color3.new(1, 1, 1)
                        }, {
                            UIGradient = Roact.createElement("UIGradient", {
                                Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.5, 0.5, 0.5)),
                                Rotation = 90,
                            })
                        })
                    }),

                    FullGameButton = Roact.createElement("TextButton", {
                        AnchorPoint = Vector2.new(0.5, 1),
                        Size = UDim2.new(1, 0, 0.5, -8),
                        Position = UDim2.new(0.5, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, {
                        Header = Roact.createElement("TextLabel", {
                            AnchorPoint = Vector2.new(0.5, 0),
                            Size = UDim2.new(1, -16, 0, 32),
                            Position = UDim2.new(0.5, 0, 0, 8),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,

                            Text = "Full",
                            Font = Style.Constants.MainFont,
                            TextSize = 32,
                            TextStrokeTransparency = 0.75,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Center,

                            TextColor3 = Color3.new(1, 1, 1),
                            TextStrokeColor3 = Color3.new(0, 0, 0)
                        }),

                        DescriptorText = Roact.createElement("TextLabel", {
                            AnchorPoint = Vector2.new(0.5, 1),
                            Size = UDim2.new(1, -16, 0, 64),
                            Position = UDim2.new(0.5, 0, 1, -8),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,

                            Text = "Coming in a future update...",
                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextStrokeTransparency = 0.75,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextYAlignment = Enum.TextYAlignment.Bottom,

                            TextColor3 = Color3.new(1, 1, 1),
                            TextStrokeColor3 = Color3.new(0, 0, 0)
                        }),

                        MapImage = Roact.createElement("ImageLabel", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(1, 0, 1, 0),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,

                            Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
                            ScaleType = Enum.ScaleType.Crop,

                            ImageColor3 = Color3.new(1, 1, 1)
                        }, {
                            UIGradient = Roact.createElement("UIGradient", {
                                Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.5, 0.5, 0.5)),
                                Rotation = 90,
                            })
                        })
                    }),
                })
            })
        or nil,

        PartyContainer = (currentParty) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.5, -8, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                Header = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = "Party",
                    Font = Style.Constants.MainFont,
                    TextSize = 32,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                SubHeader = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0.5, 0, 0, 40),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = subHeaderText, 
                    Font = Style.Constants.MainFont,
                    TextSize = 24,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                PlayerList = Roact.createElement("ScrollingFrame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 1, -136),
                    Position = UDim2.new(0.5, 0, 0, 72),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,

                    CanvasSize = self.playerListLength:map(function(length)
                        return UDim2.new(0, 0, 0, length)
                    end),

                    VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
                    ScrollBarThickness = 6,

                    ScrollBarImageColor3 = Color3.new(0, 0, 0)
                }, playerListElements),

                Buttons = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, 56),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    UIGridLayout = Roact.createElement("UIGridLayout", {
                        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
                        CellSize = UDim2.new(0.5, -Style.Constants.MinorElementPadding / 2, 0.5, -Style.Constants.MinorElementPadding / 2),
                
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        StartCorner = Enum.StartCorner.TopLeft,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Bottom,
                    }),

                    CloseButton = Roact.createElement("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(0, 80, 0, 24),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        LayoutOrder = 0,
            
                        Text = partyCloseButtonText,
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                
                        BackgroundColor3 = Color3.new(1, 0, 0),
                        TextColor3 = Color3.new(1, 1, 1),
            
                        [Roact.Event.Activated] = function()
                            if (isCurrentPartyLeader) then
                                Matchmaking.CloseGame(currentParty)
                            else
                                Matchmaking.RemovePlayerFromGame(currentParty, LocalPlayer)
                            end
                        end
                    }, {
                        UICorner = Roact.createElement("UICorner", {
                            CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                        }),
                    }),

                    StartButton = (isCurrentPartyLeader) and
                        Roact.createElement("TextButton", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Size = UDim2.new(0, 80, 0, 24),
                            Position = UDim2.new(1, 0, 0.5, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            LayoutOrder = 1,
                
                            Text = "Start Game",
                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                    
                            BackgroundColor3 = Color3.fromRGB(0, 170, 255),
                            TextColor3 = Color3.new(1, 1, 1),
                
                            [Roact.Event.Activated] = function()
                                Matchmaking.StartGame(currentParty)
                            end
                        }, {
                            UICorner = Roact.createElement("UICorner", {
                                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                            }),
                        })
                    or nil,

                    TogglePlayerListViewButton =  (isCurrentPartyLeader) and
                        Roact.createElement("TextButton", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Size = UDim2.new(0, 80, 0, 24),
                            Position = UDim2.new(1, 0, 0.5, 0),
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            LayoutOrder = 2,
                
                            Text = string.format(
                                (playerListView == "PlayerList") and "Queue (%d)" or "Players (%d)",
                                (playerListView == "PlayerList") and #currentGameQueue or (#currentGamePlayerList + 1)
                            ),

                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                    
                            BackgroundColor3 = Color3.fromRGB(230, 230, 230),
                            TextColor3 = Color3.new(0, 0, 0),
                
                            [Roact.Event.Activated] = function()
                                self:setState({
                                    playerListView = (playerListView == "PlayerList") and "Queue" or "PlayerList"
                                })
                            end
                        }, {
                            UICorner = Roact.createElement("UICorner", {
                                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                            }),
                        })
                    or nil,
                })
            })
        or nil
    })
end

---

SimpleGameCreationPage.init = function(self)
    self.mapListLength, self.updateMapListLength = Roact.createBinding(0)
    self.hoveredDifficulty, self.updateHoveredDifficulty = Roact.createBinding(nil)

    self:setState({
        mapList = {}
    })
end

SimpleGameCreationPage.didMount = function(self)
    self:setState({
        mapList = Matchmaking.GetMaps()
    })
end

SimpleGameCreationPage.render = function(self)
    local mapList = self.state.mapList
    local selectedMap = self.state.selectedMap
    local selectedDifficulty = self.state.selectedDifficulty
    local selectedAccess = self.state.selectedAccess

    local mapListElements = {}
    local difficultyListElements = {}
    local accessListElements = {}

    mapListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MajorElementPadding, 0, Style.Constants.MajorElementPadding),
        CellSize = UDim2.new(0.5, -Style.Constants.MinorElementPadding, 0, 100),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.Name,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateMapListLength(obj.AbsoluteContentSize.Y)
        end
    })

    difficultyListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
        CellSize = UDim2.new(0.5, -Style.Constants.MinorElementPadding / 2, 0, 32),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    accessListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
        CellSize = UDim2.new(0.5, -Style.Constants.MinorElementPadding / 2, 0, 32),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    for i = 1, #mapList do
        local mapName = mapList[i]

        mapListElements[mapName] = Roact.createElement("TextButton", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = "",
            TextTransparency = 1,

            [Roact.Event.Activated] = function()
                self:setState({
                    selectedMap = mapName,
                })
            end,
        }, {
            MapImage = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
                ScaleType = Enum.ScaleType.Crop,

                ImageColor3 = Color3.new(1, 1, 1)
            }, {
                UIGradient = Roact.createElement("UIGradient", {
                    Color = ColorSequence.new(
                        Color3.new(1, 1, 1),
                        (selectedMap == mapName) and Color3.fromRGB(0, 170, 255) or Color3.new(0.5, 0.5, 0.5)
                    ),

                    Rotation = 90,
                })
            }),

            MapName = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, -16, 0, 16),
                Position = UDim2.new(0.5, 0, 1, -8),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = mapName,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextStrokeTransparency = 0.75,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(1, 1, 1),
                TextStrokeColor3 = Color3.new(0, 0, 0)
            })
        })
    end

    for difficulty in pairs(GameEnum.Difficulty) do
        difficultyListElements[difficulty] = (difficulty ~= GameEnum.Difficulty.Special) and
            Roact.createElement("TextButton", {
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                LayoutOrder = difficultyLayoutOrders[difficulty],

                Text = difficulty,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                BackgroundColor3 = (selectedDifficulty == difficulty) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(230, 230, 230),
                TextColor3 = (selectedDifficulty == difficulty) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),

                [Roact.Event.MouseEnter] = function()
                    self.updateHoveredDifficulty(difficulty)
                end,

                [Roact.Event.MouseLeave] = function()
                    self.updateHoveredDifficulty(nil)
                end,

                [Roact.Event.Activated] = function()
                    self:setState({
                        selectedDifficulty = difficulty
                    })
                end
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                }),
            })
        or nil
    end

    for i = 1, #accessKeys do
        local access = accessKeys[i]

        accessListElements[access] = Roact.createElement("TextButton", {
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = i,

            Text = accessButtonTexts[access],
            Font = Style.Constants.MainFont,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
    
            BackgroundColor3 = (selectedAccess == access) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(230, 230, 230),
            TextColor3 = (selectedAccess == access) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),

            [Roact.Event.Activated] = function()
                self:setState({
                    selectedAccess = access
                })
            end
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
            }),
        })
    end

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.new(1, 1, 1)
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
        }),

        Padding = Roact.createElement(Padding, { Style.Constants.MajorElementPadding }),

        MapListSection = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0.5, -8, 1, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Header = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
        
                Text = "Select a Map",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                TextColor3 = Color3.new(0, 0, 0)
            }),

            MapList = Roact.createElement("ScrollingFrame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -40),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,

                CanvasSize = self.mapListLength:map(function(length)
                    return UDim2.new(0, 0, 0, length)
                end),

                VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
                ScrollBarThickness = 6,

                ScrollBarImageColor3 = Color3.new(0, 0, 0)
            }, mapListElements)
        }),

        DifficultySection = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0.5, -8, 0.5, -8),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Header = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
        
                Text = "Difficulty",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                TextColor3 = Color3.new(0, 0, 0)
            }),

            DifficultyDescription = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -120),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
        
                Text = self.hoveredDifficulty:map(function(difficulty)
                    if (difficulty) then
                        return difficultyDescriptions[difficulty]
                    else
                        return selectedDifficulty and difficultyDescriptions[selectedDifficulty] or ""
                    end
                end),

                Font = Enum.Font.Gotham,
                TextSize = 16,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
        
                TextColor3 = Color3.new(0, 0, 0)
            }),

            DifficultyList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 72),
                Position = UDim2.new(0.5, 0, 0, 40),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, difficultyListElements)
        }),

        AccessSection = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0.5, -8, 0, 112),
            Position = UDim2.new(1, 0, 0.5, 8),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Header = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
        
                Text = "Access",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                TextColor3 = Color3.new(0, 0, 0)
            }),

            AccessList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 72),
                Position = UDim2.new(0.5, 0, 0, 40),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, accessListElements)
        }),

        Buttons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0.5, -8, 0, 24),
            Position = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            DoneButton = Roact.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 80, 0, 24),
                Position = UDim2.new(1, -88, 0.5, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
    
                Text = "Done",
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                BackgroundColor3 = Color3.fromRGB(0, 170, 255),
                TextColor3 = Color3.new(1, 1, 1),
    
                [Roact.Event.Activated] = function()
                    if (not (selectedMap and selectedDifficulty and selectedAccess)) then return end

                    local accessRules

                    if (selectedAccess == "OpenAccess") then
                        accessRules = {
                            ApprovalType = GameEnum.GameAccessApprovalType.AutomaticApproval,
                            Ruleset = {},
                        }
                    elseif (selectedAccess == "ClosedAccess") then
                        accessRules = {
                            ApprovalType = GameEnum.GameAccessApprovalType.ManualApproval,
                            Ruleset = {},
                        }
                    elseif (selectedAccess == "FriendsOnly") then
                        accessRules = {
                            ApprovalType = GameEnum.GameAccessApprovalType.AutoRuleset,

                            Ruleset = {
                                { RuleType = GameEnum.GameAccessRuleType.ApproveFriends, },
                                { RuleType = GameEnum.GameAccessRuleType.Reject, }
                            },
                        }
                    end

                    Matchmaking.OpenGame(LocalPlayer, {
                        MapName = selectedMap,
                        GameMode = GameEnum.GameMode.TowerDefense,
                        Difficulty = selectedDifficulty,
                    }, {}, accessRules)

                    self.props.updateSelectedPage("MainMenu")
                end
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                }),
            }),

            CancelButton = Roact.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 80, 0, 24),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
    
                Text = "Cancel",
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
        
                BackgroundColor3 = Color3.fromRGB(230, 230, 230),
                TextColor3 = Color3.new(0, 0, 0),
    
                [Roact.Event.Activated] = function()
                    self.props.updateSelectedPage("MainMenu")
                end
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                }),
            })
        })
    })
end

---

local PlayMenu = Roact.PureComponent:extend("PlayMenu")

PlayMenu.init = function(self)
    self:setState({
        selectedPage = 1
    })

    self.updateSelectedPage = function(pageName)
        local pageIndex

        for i = 1, #pages do
            local page = pages[i]

            if (page.name == pageName) then
                pageIndex = i
                break
            end
        end

        self:setState({
            selectedPage = pageIndex
        })
    end
end

PlayMenu.render = function(self)
    local selectedPage = self.state.selectedPage
    local page = pages[selectedPage]

    return Roact.createElement(page.element, {
        updateSelectedPage = self.updateSelectedPage
    })
end

return PlayMenu