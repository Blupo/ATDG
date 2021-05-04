local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

---

local root = script.Parent
local Otter = require(root:WaitForChild("Otter"))
local Roact = require(root:WaitForChild("Roact"))
local Padding = require(root:WaitForChild("Padding"))
local RoundedFrame = require(root:WaitForChild("RoundedFrame"))

local PlayerScripts = root.Parent
local GameModules = PlayerScripts:WaitForChild("GameModules")
local Util = PlayerScripts:WaitForChild("Util")

local Game = require(GameModules:WaitForChild("Game"))
local TimeSyncService = require(Util:WaitForChild("TimeSyncService"))

---

local FONT = Enum.Font.FredokaOne
local HINT_TEXT_SIZE = 8
local MAIN_TEXT_SIZE = 80
local CORNER_RADIUS_PX = 12

local randomValueInRange = function(min: number, max: number): number
    return ((max - min) * math.random()) + min
end

local formatTime = function(t: number): string
    t = math.ceil(t)
	
	return string.format("%02d:%02d", t / 60, t % 60)
end

---

local HintTextLabel = Roact.PureComponent:extend("HintTextLabel")

HintTextLabel.render = function(self)
    return Roact.createElement("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(1, -CORNER_RADIUS_PX * 2, 0, HINT_TEXT_SIZE),
        Position = UDim2.new(0.5, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = -1,
        BackgroundTransparency = 1,

        Text = self.props.Text,
        Font = FONT,
        TextSize = HINT_TEXT_SIZE,
        TextStrokeTransparency = 0.7,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Bottom,

        TextColor3 = Color3.new(0, 0, 0),
        TextStrokeColor3 = Color3.new(1, 1, 1),
    })
end

---

local GameState = Roact.Component:extend("GameState")

GameState.init = function(self)
    self.time, self.updateTime = Roact.createBinding(0)

    self.makeTimerLoop = function(startTime, length)
        if (not (self.clock and startTime and length)) then return end

        self.timerLoop = RunService.Heartbeat:Connect(function()
            local elapsed = self.clock:GetTime() - startTime
            
            if ((elapsed >= length) and self.timerLoop) then
                self.timerLoop:Disconnect()
                self.timerLoop = nil
                return
            end
            
            local timeLeft = length - elapsed
            self.updateTime(timeLeft)
        end)
    end

    self:setState({
        isTenFoot = GuiService:IsTenFootInterface(),
        screenSize = Vector2.new(),

        currentRound = 0,
        totalRounds = 0,
    })
end

GameState.didMount = function(self)
    local gameState = Game.GetDerivedGameState()
    self.clock = TimeSyncService:WaitForSyncedClock()

    self.endedConnection = Game.Ended:Connect(function()
        if (self.timerLoop) then
            self.timerLoop:Disconnect()
            self.timerLoop = nil
        end

        self:setState({
            ended = true
        })
    end)

    self.roundStartedConnection = Game.RoundStarted:Connect(function(roundNum)
        self:setState({
            currentRound = roundNum
        })
    end)

    self.roundEndedConnection = Game.RoundEnded:Connect(function()
        if (self.timerLoop) then
            self.timerLoop:Disconnect()
            self.timerLoop = nil
        end
    end)

    self.phaseChangedConnection = Game.PhaseChanged:Connect(function(_, phaseStartTime, phaseLength)
        if (not (phaseStartTime and phaseLength)) then return end

        self.makeTimerLoop(phaseStartTime, phaseLength)
    end)

    if (gameState.CurrentPhaseLength and gameState.CurrentPhaseStartTime) then
        self.makeTimerLoop(gameState.CurrentPhaseLength, gameState.CurrentPhaseStartTime)
    end

    self:setState({
        totalRounds = gameState.TotalRounds
    })
end

GameState.willUnmount = function(self)
    self.roundStartedConnection:Disconnect()
    self.roundEndedConnection:Disconnect()
    self.phaseChangedConnection:Disconnect()

    if (self.timerLoop) then
        self.timerLoop:Disconnect()
    end
end

GameState.render = function(self)
    local bkgColor = Color3.fromHSV(math.random(), 1, 1)
    local invertedBkgColor = Color3.new(1 - bkgColor.R, 1 - bkgColor.G, 1 - bkgColor.B)

    local secondBkgColor = Color3.fromHSV(math.random(), 1, 1)
    local secondInvertedBkgColor = Color3.new(1 - secondBkgColor.R, 1 - secondBkgColor.G, 1 - secondBkgColor.B)
    
    local phaseTransitionChildren = {}

    for i = 1, 4 do
        phaseTransitionChildren[i] = Roact.createElement(RoundedFrame, {
            radiusScale = CORNER_RADIUS_PX / 100,

            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BorderSizePixel = 0,
            BackgroundTransparency = 0.5,
            Rotation = math.random() * 360,
            ZIndex = -1,

            BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
        })
    end

    phaseTransitionChildren["PhaseLabel"] = Roact.createElement("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 0,
        BackgroundTransparency = 1,

        Text = "Test",

        Font = FONT,
        TextSize = (MAIN_TEXT_SIZE / 2) - (MAIN_TEXT_SIZE / 10),
        TextStrokeTransparency = 0.7,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,

        TextColor3 = Color3.new(0, 0, 0),
        TextStrokeColor3 = Color3.new(1, 1, 1),
    })
    
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        [Roact.Change.AbsoluteSize] = function(obj)
            self:setState({
                screenSize = obj.AbsoluteSize
            })
        end,
    }, {
        Padding = Roact.createElement(Padding, {16}),

        CurrentRoundPrimaryBkg = Roact.createElement(RoundedFrame, {
            radiusScale = CORNER_RADIUS_PX / 100,

            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 100, 0, 100),
            Position = UDim2.new(0, 25, 1, -100),
            BorderSizePixel = 0,
            Rotation = randomValueInRange(-90, -45),
            ZIndex = -1,

            BackgroundColor3 = bkgColor,
        }, {
            CurrentRoundHintLabel = Roact.createElement(HintTextLabel, {
                Text = "CURRENT"
            })
        }),

        TotalRoundsPrimaryBkg = Roact.createElement(RoundedFrame, {
            radiusScale = CORNER_RADIUS_PX / 100,

            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0, 100, 1, -60),
            BorderSizePixel = 0,
            Rotation = randomValueInRange(0, 90),
            ZIndex = -2,

            BackgroundColor3 = secondBkgColor,
        }, {
            TotalRoundsHintLabel = Roact.createElement(HintTextLabel, {
                Text = "TOTAL"
            })
        }),

        CurrentRoundSecondaryBkg = Roact.createElement(RoundedFrame, {
            radiusScale = CORNER_RADIUS_PX / 100,

            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 100, 0, 100),
            Position = UDim2.new(0, 25, 1, -100),
            BorderSizePixel = 0,
            Rotation = math.random() * 360,
            ZIndex = -3,

            BackgroundColor3 = invertedBkgColor,
        }),

        TotalRoundsSecondaryBkg = Roact.createElement(RoundedFrame, {
            radiusScale = CORNER_RADIUS_PX / 100,

            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0, 100, 1, -60),
            BorderSizePixel = 0,
            Rotation = math.random() * 360,
            ZIndex = -4,

            BackgroundColor3 = secondInvertedBkgColor,
        }),

        CurrentRoundLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 100, 0, 100),
            Position = UDim2.new(0, 25, 1, -100),
            BorderSizePixel = 0,
            ZIndex = 0,
            BackgroundTransparency = 1,
    
            Text = self.state.currentRound,
            Font = FONT,
            TextSize = MAIN_TEXT_SIZE,
            TextStrokeTransparency = 0.7,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
    
            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1),
        }),

        TotalRoundsLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0, 100, 1, -60),
            BorderSizePixel = 0,
            ZIndex = 0,
            BackgroundTransparency = 1,
    
            Text = self.state.totalRounds,
            Font = FONT,
            TextSize = MAIN_TEXT_SIZE / 2,
            TextStrokeTransparency = 0.7,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
    
            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1),
        }),

        PhaseTransitionContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 205, 0, 50),
            Position = UDim2.new(0, 0, 1, -230),
            BorderSizePixel = 0,
            ZIndex = 0,
            BackgroundTransparency = 1,
            Rotation = randomValueInRange(-8, 8),
        }, phaseTransitionChildren),

        TimerLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 205, 0, 50),
            Position = UDim2.new(0, 0, 1, 0),
            BorderSizePixel = 0,
            ZIndex = 0,
            BackgroundTransparency = 1,
    
            Text = self.state.ended and
                "Ended"
            or
                self.time:map(function(time)
                    return formatTime(time)
                end),

            Font = FONT,
            TextSize = (MAIN_TEXT_SIZE / 2) - (MAIN_TEXT_SIZE / 10),
            TextStrokeTransparency = 0.7,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
    
            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1),
        })
    })
end

return GameState