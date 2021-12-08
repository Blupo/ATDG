-- TODO: Return to Lobby stuff

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Button = require(GameUIModules:WaitForChild("Button"))
local MainElementContainer = require(GameUIModules:WaitForChild("MainElementContainer"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local StatListItem = require(GameUIModules:WaitForChild("StatListItem"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local Notifications = require(PlayerModules:WaitForChild("Notifications"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SharedGameData = require(SharedModules:WaitForChild("SharedGameData"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local Game = SystemCoordinator.waitForSystem("Game")
local GameStats = SystemCoordinator.waitForSystem("GameStats")

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout

---

local RETURN_TIMEOUT = 60

--[[
    Rewards are sorted alphabetically, in the category order:

        Currencies
        Tower Units
        Field Units

    Stats have a set sorting order:

        Play Time
        Total DMG
]]

local statSortOrder = {
    GameEnum.GameStat.TimePlayed,
    GameEnum.PlayerStat.TotalDMG,
}

local formatStat = function(stat, value)
    if (stat == GameEnum.GameStat.TimePlayed) then
        return string.format("%02d:%02d Play Time", math.floor(value / 60), math.floor(value % 60))
    elseif (stat == GameEnum.PlayerStat.TotalDMG) then
        return string.format("%0.3f Total DMG", value)
    end
end

---

local GameResultsPage = Roact.PureComponent:extend("GameResultsPage")

GameResultsPage.init = function(self)
    self.start = os.clock()
    self.timeLeft, self.updateTimeLeft = Roact.createBinding(RETURN_TIMEOUT)
    self.rewardListLength, self.updateRewardListLength = Roact.createBinding(0)
    self.statListLength, self.updateStatListLength = Roact.createBinding(0)

    self.teleportToLobby = function()
        if (self.timeoutConnection) then
            self.timeoutConnection:Disconnect()
            self.timeoutConnection = nil
        end

        self.updateTimeLeft(nil)
        Notifications.SendCoreNotification("Teleporting", "You are being teleported back to the lobby.", "Game")
        TeleportService:Teleport(SharedGameData.PlaceIds.Lobby)
    end

    self:setState({
        rewards = {
            Currency = {},
            Unit = {},
        },

        stats = {},
    })
end

GameResultsPage.didMount = function(self)
    local ticketRewards = Game.GetTicketReward()
    local stats = GameStats.GetStats(LocalPlayer.UserId)
    local derivedGameState = Game.GetDerivedGameState()

    self.timeoutConnection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        local elapsed = now - self.start
        elapsed = (elapsed <= RETURN_TIMEOUT) and elapsed or RETURN_TIMEOUT

        self.updateTimeLeft(RETURN_TIMEOUT - elapsed)

        if (elapsed >= RETURN_TIMEOUT) then
            self.teleportToLobby()
        end
    end)

    self:setState({
        rewards = {
            Currency = {
                [GameEnum.CurrencyType.Tickets] = ticketRewards
            },

            Unit = {}
        },

        stats = stats,
        gameCompleted = derivedGameState.Completed,
    })
end

GameResultsPage.willUnmount = function(self)
    if (self.timeoutConnection) then
        self.timeoutConnection:Disconnect()
        self.timeoutConnection = nil
    end
end

GameResultsPage.render = function(self)
    local rewards = self.state.rewards
    local stats = self.state.stats
    local gameCompleted = self.state.gameCompleted

    local sortedRewardCurrencies = {}
    local sortedStats = {}

    local sortedRewardUnits = {
        [GameEnum.UnitType.TowerUnit] = {},
        [GameEnum.UnitType.FieldUnit] = {},
    }

    local sortedRewardTowerUnits = sortedRewardUnits[GameEnum.UnitType.TowerUnit]
    local sortedRewardFieldUnits = sortedRewardUnits[GameEnum.UnitType.FieldUnit]
    local rewardListElements = {}
    local statListElements = {}

    for currency in pairs(rewards.Currency) do
        table.insert(sortedRewardCurrencies, currency)
    end

    for stat in pairs(stats) do
        table.insert(sortedStats, table.find(statSortOrder, stat), stat)
    end

    for i = 1, #rewards.Unit do
        local unit = rewards.Unit[i]
        local unitType = Unit.GetUnitType(unit)

        table.insert(sortedRewardUnits[unitType], unit)
    end

    table.sort(sortedRewardCurrencies, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    table.sort(sortedRewardTowerUnits, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    table.sort(sortedRewardFieldUnits, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    for i = 1, #sortedRewardCurrencies do
        local currency = sortedRewardCurrencies[i]

        table.insert(rewardListElements, Roact.createElement(StatListItem, {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardIconSize),
            LayoutOrder = i,

            Text = rewards.Currency[currency] .. " " .. currency,
            Image = Style.Images[currency .. "CurrencyIcon"],

            ImageColor3 = Style.Colors[currency .. "CurrencyColor"]
        }))
    end

    for i = 1, #sortedRewardTowerUnits do
        table.insert(rewardListElements, Roact.createElement(StatListItem, {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardIconSize),
            LayoutOrder = #rewardListElements + i,

            Text = sortedRewardTowerUnits[i],
            Image = Style.Images.TowerUnitIcon,

            ImageColor3 = Style.Colors.TowerUnitIconColor,
        }))
    end

    for i = 1, #sortedRewardFieldUnits do
        table.insert(rewardListElements, Roact.createElement(StatListItem, {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardIconSize),
            LayoutOrder = #rewardListElements + i,

            Text = sortedRewardFieldUnits[i],
            Image = Style.Images.FieldUnitIcon,

            ImageColor3 = Style.Colors.FieldUnitIconColor,
        }))
    end

    for i = 1, #sortedStats do
        local stat = sortedStats[i]

        table.insert(statListElements, Roact.createElement(StatListItem, {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardIconSize),
            LayoutOrder = i,

            Text = formatStat(stat, stats[stat]),
            Image = Style.Images[stat .. "StatIcon"],

            ImageColor3 = Style.Colors[stat .. "StatColor"],
        }))
    end

    rewardListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateRewardListLength(obj.AbsoluteContentSize.Y)
        end
    })

    statListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateStatListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createElement(MainElementContainer, {
        ScaleX = 0.4,
        ScaleY = 0.4,
        AspectRatio = 1.5,
        
        StrokeGradient = Style.Colors.YellowProminentGradient,
    }, {
        Header = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
            Position = UDim2.new(0.5, 0, 0, 0),

            Text = "Game Results",
            TextSize = Style.Constants.PrimaryHeaderTextSize,
        }),

        ResultsSubtext = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
            Position = UDim2.new(0.5, 0, 0, Style.Constants.PrimaryHeaderTextSize),

            Text = gameCompleted and "You finished the game!" or "You didn't finish the game...",
            Font = Style.Constants.SecondaryFont,
        }),

        RewardsSection = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 1, -(Style.Constants.PrimaryHeaderTextSize + Style.Constants.StandardTextSize + Style.Constants.MajorElementPadding)),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),
                Position = UDim2.new(0.5, 0, 0, 0),
    
                Text = "Rewards",
                TextSize = Style.Constants.SecondaryHeaderTextSize,
            }),

            List = Roact.createElement(StandardScrollingFrame, {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -(Style.Constants.SecondaryHeaderTextSize + Style.Constants.SpaciousElementPadding)),
                Position = UDim2.new(0.5, 0, 1, 0),

                CanvasSize = self.rewardListLength:map(function(length)
                    return UDim2.new(0, 0, 0, length)
                end)
            }, rewardListElements)
        }),

        StatsSection = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Size = UDim2.new(
                0.5, -Style.Constants.SpaciousElementPadding / 2,
                1, -(
                    Style.Constants.PrimaryHeaderTextSize +
                    Style.Constants.StandardTextSize +
                    Style.Constants.MajorElementPadding +
                    Style.Constants.StandardButtonHeight +
                    Style.Constants.SpaciousElementPadding
                )
            ),
        }, {
            Header = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),
                Position = UDim2.new(0.5, 0, 0, 0),
    
                Text = "Stats",
                TextSize = Style.Constants.SecondaryHeaderTextSize,
            }),

            List = Roact.createElement(StandardScrollingFrame, {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 1, -(Style.Constants.SecondaryHeaderTextSize + Style.Constants.SpaciousElementPadding)),
                Position = UDim2.new(0.5, 0, 1, 0),

                CanvasSize = self.statListLength:map(function(length)
                    return UDim2.new(0, 0, 0, length)
                end)
            }, statListElements)
        }),

        ReturnButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 20, 0, Style.Constants.StandardButtonHeight),
            Position = UDim2.new(1, 0, 1, 0),

            BackgroundColor3 = Style.Colors.DialogButtonColor,
            TextColor3 = Color3.new(1, 1, 1),

            displayType = "Text",
            onActivated = self.teleportToLobby,

            Text = self.timeLeft:map(function(timeLeft)
                return "Return to Lobby" .. (timeLeft and (" (" .. math.ceil(timeLeft) .. ")") or "")
            end),
        })
    })
end

return GameResultsPage