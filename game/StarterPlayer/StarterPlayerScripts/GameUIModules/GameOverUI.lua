local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")

---

local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))
local Padding = require(root:WaitForChild("Padding"))
local Style = require(root:WaitForChild("Style"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local LocalPlayer = Players.LocalPlayer
local Game = SystemCoordinator.waitForSystem("Game")
local GameStats = SystemCoordinator.waitForSystem("GameStats")

---

local RETURN_TIMEOUT = 60

--[[
    props

        gameCompleted: boolean
]]

local GameOverUI = Roact.Component:extend("GameOverUI")

GameOverUI.init = function(self)
    self.start = os.clock()
    self.timeLeft, self.updateTimeLeft = Roact.createBinding(RETURN_TIMEOUT)
    
    self:setState({
        ticketReward = 0,
        stats = {}
    })

    self.timeoutConnection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        local elapsed = now - self.start
        elapsed = (elapsed <= RETURN_TIMEOUT) and elapsed or RETURN_TIMEOUT

        self.updateTimeLeft(RETURN_TIMEOUT - elapsed)

        if (elapsed >= RETURN_TIMEOUT) then
            self.timeoutConnection:Disconnect()
            self.timeoutConnection = nil

            StarterGui:SetCore("SendNotification", {
                Title = "Teleporting",
                Text = "You are being teleported back to the lobby.",
                Icon = "rbxassetid://6869244717",
            })

            TeleportService:Teleport(6421134421)
        end
    end)
end

GameOverUI.didMount = function(self)
    self:setState({
        ticketReward = Game.GetTicketReward(),
        stats = GameStats.GetStats(LocalPlayer.UserId)
    })
end

GameOverUI.willUnmount = function(self)
    if (self.timeoutConnection) then
        self.timeoutConnection:Disconnect()
        self.timeoutConnection = nil
    end
end

GameOverUI.render = function(self)
    local stats = self.state.stats

    local timePlayed = stats[GameEnum.GameStat.TimePlayed] or 0
    local minutes = math.floor(timePlayed / 60)
    local seconds = timePlayed % 60

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 500, 0, 250),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.new(1, 1, 1)
    }, {
        UIPadding = Roact.createElement(Padding, {Style.Constants.MajorElementPadding}),

        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius),
        }),

        RewardsContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0),
            Size = UDim2.new(0.5, -8, 1, -32),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Header = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = "Rewards",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(0, 0, 0)
            }),

            List = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -40),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                UIListLayout = Roact.createElement("UIListLayout", {
                    Padding = UDim.new(0, Style.Constants.MinorElementPadding),
        
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                }),

                TicketsReward = Roact.createElement("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 0,

                    Text = (self.state.ticketReward or 0) .. " Tickets",
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                })
            })
        }),

        StatsContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0.5, -8, 1, -32),
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

                Text = "Stats",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(0, 0, 0)
            }),

            List = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -40),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                UIListLayout = Roact.createElement("UIListLayout", {
                    Padding = UDim.new(0, Style.Constants.MinorElementPadding),
        
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                }),

                TimePlayed = Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 0,
                }, {
                    Label = Roact.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
    
                        Text = "Time Played",
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
    
                        TextColor3 = Color3.new(0, 0, 0)
                    }),

                    Value = Roact.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
    
                        Text = string.format("%d:%02d", minutes, seconds),
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextYAlignment = Enum.TextYAlignment.Center,
    
                        TextColor3 = Color3.new(0, 0, 0)
                    })
                }),

                TotalDMG = Roact.createElement("Frame", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
                }, {
                    Label = Roact.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
    
                        Text = "Total DMG",
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
    
                        TextColor3 = Color3.new(0, 0, 0)
                    }),

                    Value = Roact.createElement("TextLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
    
                        Text = math.floor((stats[GameEnum.PlayerStat.TotalDMG] or 0) + 0.5),
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextYAlignment = Enum.TextYAlignment.Center,
    
                        TextColor3 = Color3.new(0, 0, 0)
                    })
                }),
            })
        }),

        ReturnToLobbyTimer = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0, 40, 0, 24),
            Position = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = self.timeLeft:map(function(timeLeft)
                return "(" .. math.ceil(timeLeft) .. ")"
            end),

            Font = Style.Constants.MainFont,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,

            TextColor3 = Color3.new(0, 0, 0)
        }),

        ReturnToLobbyButton = Roact.createElement("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0, 140, 0, 24),
            Position = UDim2.new(1, -48, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Text = "Return to Lobby",
            Font = Style.Constants.MainFont,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,

            BackgroundColor3 = Color3.fromRGB(230, 230, 230),
            TextColor3 = Color3.new(0, 0, 0),

            [Roact.Event.Activated] = function()
                if (self.timeoutConnection) then
                    self.timeoutConnection:Disconnect()
                    self.timeoutConnection = nil
                end

                StarterGui:SetCore("SendNotification", {
                    Title = "Teleporting",
                    Text = "You are being teleported back to the lobby.",
                    Icon = "rbxassetid://6869244717",
                })

                TeleportService:Teleport(6421134421)
            end,
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius),
            }),
        }),

        DEBUG_COMPLETED_LABEL = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 140, 0, 24),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = self.props.gameCompleted and "Game Completed!" or "Incomplete Game",
            Font = Style.Constants.MainFont,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,

            TextColor3 = Color3.new(0, 0, 0)
        }),
    })
end

return GameOverUI