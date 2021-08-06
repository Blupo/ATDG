local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---

local root = script.Parent
local PlayerScripts = root.Parent

local Animator = require(root:WaitForChild("Animator"))
local Otter = require(root:WaitForChild("Otter"))
local Roact = require(root:WaitForChild("Roact"))
local Padding = require(root:WaitForChild("Padding"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local TimeSyncService = require(PlayerModules:WaitForChild("TimeSyncService"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local Promise = require(SharedModules:WaitForChild("Promise"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local Game = SystemCoordinator.waitForSystem("Game")

---

local FONT = Enum.Font.FredokaOne
local HINT_TEXT_SIZE = 8
local TITLE_TEXT_SIZE = 50
local MAIN_TEXT_SIZE = 80
local TIMER_TEXT_SIZE = 32
local STAT_TEXT_SIZE = 24
local CORNER_RADIUS_PX = 12

local BKG_COLORS = {
    [GameEnum.GamePhase.Intermission] = {
        CurrentRoundPrimaryBkg = Color3.new(1, 1, 1),
        CurrentRoundSecondaryBkg = Color3.new(0.5, 0.5, 0.5),
        TotalRoundsPrimaryBkg = Color3.new(1, 1, 1),
        TotalRoundsSecondaryBkg = Color3.new(0.5, 0.5, 0.5),
    },

    [GameEnum.GamePhase.FinalIntermission] = {
        CurrentRoundPrimaryBkg = Color3.new(0.4, 0.4, 0.4),
        CurrentRoundSecondaryBkg = Color3.new(0.5, 0.5, 0.5),
        TotalRoundsPrimaryBkg = Color3.new(0.4, 0.4, 0.4),
        TotalRoundsSecondaryBkg = Color3.new(0.5, 0.5, 0.5),
    },

    [GameEnum.GamePhase.Round] = {
        CurrentRoundPrimaryBkg = Color3.new(1, 1, 0),
        CurrentRoundSecondaryBkg = Color3.new(1, 0, 1),
        TotalRoundsPrimaryBkg = Color3.fromRGB(255, 85, 127),
        TotalRoundsSecondaryBkg = Color3.fromRGB(255, 128, 85),
    },

    [GameEnum.GamePhase.Preparation] = {
        CurrentRoundPrimaryBkg = Color3.new(1, 1, 1),
        CurrentRoundSecondaryBkg = Color3.new(1, 1, 1),
        TotalRoundsPrimaryBkg = Color3.new(1, 1, 1),
        TotalRoundsSecondaryBkg = Color3.new(1, 1, 1),
    },
}

local cornerRadiusScale = CORNER_RADIUS_PX / 100

local randomValueInRange = function(min: number, max: number): number
    return ((max - min) * math.random()) + min
end

local formatTime = function(t: number): string
    t = math.ceil(t)
	
	return string.format("%02d:%02d", t / 60, t % 60)
end

local roundedCornersChildren = function(radiusScale, radiusOffset, children)
    children = children or {}

    children["UICorner"] = Roact.createElement("UICorner", {
        CornerRadius = UDim.new(radiusScale or 0, radiusOffset or 0)
    })

    return children
end

local generateTransition = function(phase1, phase2)
    return {
        CurrentRoundPrimaryBkg = {BKG_COLORS[phase1].CurrentRoundPrimaryBkg, BKG_COLORS[phase2].CurrentRoundPrimaryBkg},
        CurrentRoundSecondaryBkg = {BKG_COLORS[phase1].CurrentRoundSecondaryBkg, BKG_COLORS[phase2].CurrentRoundSecondaryBkg},
        TotalRoundsPrimaryBkg = {BKG_COLORS[phase1].TotalRoundsPrimaryBkg, BKG_COLORS[phase2].TotalRoundsPrimaryBkg},
        TotalRoundsSecondaryBkg = {BKG_COLORS[phase1].TotalRoundsSecondaryBkg, BKG_COLORS[phase2].TotalRoundsSecondaryBkg},
    }
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
        TextSize = self.props.TextSize or HINT_TEXT_SIZE,
        TextStrokeTransparency = 0.5,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Bottom,

        TextColor3 = Color3.new(0, 0, 0),
        TextStrokeColor3 = Color3.new(1, 1, 1),
    })
end

---

local StatIndicator = Roact.PureComponent:extend("StatIndicator")

StatIndicator.init = function(self)
    self.animator = Animator.new({
        rotation = 0,
        xOffset = 0,
        yOffset = 0,
    })

    self.scheduleCallback = function()
        local newPromise = Promise.delay(3)

        newPromise:andThen(function()
            self.animator.Motor:setGoal({
                rotation = Otter.spring(randomValueInRange(-180, 180), {
                    frequency = math.random(2, 4),
                }),

                xOffset = Otter.spring(randomValueInRange(-5, 5), {
                    frequency = math.random(3, 4),
                }),

                yOffset = Otter.spring(randomValueInRange(-5, 5), {
                    frequency = math.random(3, 4),
                }),
            })
        end):andThen(self.scheduleCallback)

        self.animationPromise = newPromise
    end

    self.animator.Motor:setGoal({
        rotation = Otter.spring(randomValueInRange(-180, 180), {
            frequency = math.random(2, 4),
        }),

        xOffset = Otter.spring(randomValueInRange(-5, 5), {
            frequency = math.random(3, 4),
        }),

        yOffset = Otter.spring(randomValueInRange(-5, 5), {
            frequency = math.random(3, 4),
        }),
    })

    self.scheduleCallback()
end

StatIndicator.willUnmount = function(self)
    if (self.animtionPromise) then
        self.animationPromise:cancel()
    end
end

StatIndicator.render = function(self)
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        LayoutOrder = self.props.LayoutOrder,
    }, {
        StatIconBkg = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, 5, 0.5, 0),
            BorderSizePixel = 0,

            BackgroundColor3 = Color3.new(1, 1, 1),
        }, roundedCornersChildren(0, 6, {
            StatIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, -6, 1, -6),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,

                Image = self.props.Image,
                ImageColor3 = self.props.ImageColor3
            }),

            RotatingBkg = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 30, 0, 30),
                BorderSizePixel = 0,
                ZIndex = -1,

                Position = self.animator.Binding:map(function(values)
                    return UDim2.new(0.5, values.xOffset, 0.5, values.yOffset)
                end),

                Rotation = self.animator.Binding:map(function(values)
                    return values.rotation
                end),
    
                BackgroundColor3 = self.props.BkgColor or Color3.new(1, 1, 1),
            }, roundedCornersChildren(0, 6)),
        })),

        StatText = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = self.props.Text,
            Font = FONT,
            TextSize = STAT_TEXT_SIZE,
            TextStrokeTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,

            BackgroundColor3 = Color3.new(1, 1, 1),
            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = self.props.StrokeColor or Color3.new(1, 1, 1),
        })
    })
end

---

local GameState = Roact.Component:extend("GameState")

GameState.init = function(self)
    self.phaseTransitionAnimators = {}
    self.time, self.updateTime = Roact.createBinding(0)

    for i = 1, 4 do
        self.phaseTransitionAnimators[i] = Animator.new({
            rotation = randomValueInRange(-360, 360),
            size = 0,
            xOffset = randomValueInRange(-100, 100),
            yOffset = randomValueInRange(-100, 100),
        })
    end

    self.phaseTransitionAnimators.PhaseLabel = Animator.new({
        position = -1,
        transparency = 1,
        textStrokeTransparency = 1,
    })

    self.bkgAnimators = {
        CurrentRoundPrimaryBkg = Animator.new({
            rotation = -90,
            colorTransitionAlpha = 0,
        }),

        TotalRoundsPrimaryBkg = Animator.new({
            rotation = 90,
            colorTransitionAlpha = 0,
        }),

        CurrentRoundSecondaryBkg = Animator.new({
            rotation = 0,
            xOffset = 0,
            yOffset = 0,
            colorTransitionAlpha = 0,
        }),

        TotalRoundsSecondaryBkg = Animator.new({
            rotation = 0,
            xOffset = 0,
            yOffset = 0,
            colorTransitionAlpha = 0,
        }),
    }

    self.getPhaseText = function(phase)
        local phaseText

        if (phase == GameEnum.GamePhase.Round) then
            phaseText = phase .. " " .. self.state.currentRound
        elseif (phase == GameEnum.GamePhase.FinalIntermission) then
            phaseText = "Game over"
        else
            phaseText = phase
        end

        return phaseText
    end

    self.stopTimerLoop = function()
        if (not self.timerLoop) then return end

        self.timerLoop:Disconnect()
        self.timerLoop = nil
    end
    
    self.makeTimerLoop = function(startTime, length)
        if (not (self.clock and startTime and length)) then return end
        self.stopTimerLoop()

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

    self.resetPhaseTransitionAnimators = function()
        self.phaseTransitionAnimators.PhaseLabel.Motor:setGoal({
            position = Otter.instant(-1),
            transparency = Otter.instant(1),
            textStrokeTransparency = Otter.instant(1),
        })

        self.bkgAnimators.CurrentRoundPrimaryBkg.Motor:setGoal({
            colorTransitionAlpha = Otter.instant(0),
        })

        self.bkgAnimators.TotalRoundsPrimaryBkg.Motor:setGoal({
            colorTransitionAlpha = Otter.instant(0),
        })

        self.bkgAnimators.CurrentRoundSecondaryBkg.Motor:setGoal({
            colorTransitionAlpha = Otter.instant(0),
        })

        self.bkgAnimators.TotalRoundsSecondaryBkg.Motor:setGoal({
            colorTransitionAlpha = Otter.instant(0),
        })

        -- we need to yield for at least 2 frames for the goals to be set
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()
    end

    self.doPhaseTransitionAnimation = function()
        if (self.phaseTransitionAnimationPromise) then
            self.phaseTransitionAnimationPromise:cancel()
            self.phaseTransitionAnimationPromise = nil
        end

        -- phase 1
        for k, animator in pairs(self.phaseTransitionAnimators) do
            if (k ~= "PhaseLabel") then
                animator.Motor:setGoal({
                    rotation = Otter.spring(randomValueInRange(-360, 360), {
                        frequency = randomValueInRange(0.1, 0.5)
                    }),

                    size = Otter.spring(TITLE_TEXT_SIZE * 1.5),
                    xOffset = Otter.spring(0),
                    yOffset = Otter.spring(0)
                })
            end
        end

        self.phaseTransitionAnimators.PhaseLabel.Motor:setGoal({
            position = Otter.spring(0),
            transparency = Otter.spring(0),
            textStrokeTransparency = Otter.instant(0.5),
        })

        self.bkgAnimators.CurrentRoundPrimaryBkg.Motor:setGoal({
            rotation = Otter.spring(randomValueInRange(-90, -45)),
            colorTransitionAlpha = Otter.spring(1),
        })

        self.bkgAnimators.TotalRoundsPrimaryBkg.Motor:setGoal({
            rotation = Otter.spring(randomValueInRange(0, 90)),
            colorTransitionAlpha = Otter.spring(1),
        })

        self.bkgAnimators.CurrentRoundSecondaryBkg.Motor:setGoal({
            rotation = Otter.spring(randomValueInRange(-360, 360)),
            xOffset = Otter.spring(randomValueInRange(-5, 5)),
            yOffset = Otter.spring(randomValueInRange(-5, 5)),
            colorTransitionAlpha = Otter.spring(1),
        })

        self.bkgAnimators.TotalRoundsSecondaryBkg.Motor:setGoal({
            rotation = Otter.spring(randomValueInRange(-360, 360)),
            xOffset = Otter.spring(randomValueInRange(-5, 5)),
            yOffset = Otter.spring(randomValueInRange(-5, 5)),
            colorTransitionAlpha = Otter.spring(1),
        })

        -- phase 2
        self.phaseTransitionAnimationPromise = Promise.new(function(resolve, _, onCancel)
            local disconnect
            disconnect = self.phaseTransitionAnimators.PhaseLabel.Motor:onComplete(function()
                if (disconnect) then
                    disconnect()
                    disconnect = nil
                end

                resolve()
            end)

            onCancel(function()
                if (disconnect) then
                    disconnect()
                end
            end)
        end):andThen(function()
            return Promise.delay(1)
        end):andThen(function()
            return Promise.new(function(resolve, _, onCancel)
                local disconnectOnComplete

                onCancel(function()
                    if (disconnectOnComplete) then
                        disconnectOnComplete()
                        disconnectOnComplete = nil
                    end
                end)

                for k, animator in pairs(self.phaseTransitionAnimators) do
                    if (k ~= "PhaseLabel") then
                        animator.Motor:setGoal({
                            rotation = Otter.spring(randomValueInRange(-360, 360)),
                            size = Otter.spring(0),
                            xOffset = Otter.spring(randomValueInRange(-100, 100)),
                            yOffset = Otter.spring(randomValueInRange(-100, 100))
                        })
                    end
                end
        
                do
                    local labelAnimator = self.phaseTransitionAnimators.PhaseLabel
        
                    labelAnimator.Motor:setGoal({
                        position = Otter.spring(1),
                        transparency = Otter.spring(1),
                        textStrokeTransparency = Otter.spring(1),
                    })
    
                    disconnectOnComplete = labelAnimator.Motor:onComplete(function()
                        if (disconnectOnComplete) then
                            disconnectOnComplete()
                            disconnectOnComplete = nil
                        end
    
                        labelAnimator.Motor:setGoal({
                            position = Otter.instant(-1),
                        })

                        resolve()
                    end)
                end
            end)
        end)
    end

    self:setState({
        currentRound = 0,
        totalRounds = 0,
        phaseText = "",
        enemiesRemaining = 0,
        centralTowerHP = 0,
        lastPhase = GameEnum.GamePhase.Preparation,

        phaseTransitionContainerRotation = randomValueInRange(-8, 8),
        bkgColors = BKG_COLORS[GameEnum.GamePhase.Preparation],
        bkgColorTransitions = generateTransition(GameEnum.GamePhase.Preparation, GameEnum.GamePhase.Preparation),

        phaseTransitionChildrenColors = {
            Color3.fromHSV(math.random(), 1, 1),
            Color3.fromHSV(math.random(), 1, 1),
            Color3.fromHSV(math.random(), 1, 1),
            Color3.fromHSV(math.random(), 1, 1),
        },
    })
end

GameState.didMount = function(self)
    local gameState = Game.GetDerivedGameState()
    self.clock = TimeSyncService:WaitForSyncedClock()

    self.endedConnection = Game.Ended:Connect(function()
        self.stopTimerLoop()

        self:setState({
            ended = true
        })
    end)

    self.roundStartedConnection = Game.RoundStarted:Connect(function(roundNum)
        self:setState({
            currentRound = roundNum
        })
    end)

    self.roundEndedConnection = Game.RoundEnded:Connect(self.stopTimerLoop)

    self.unitAddedConnection = Unit.UnitAdded:Connect(function(unitId)
        local unit = Unit.fromId(unitId)
        if (unit.Owner ~= 0) then return end
        if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return false end

        self:setState({
            enemiesRemaining = self.state.enemiesRemaining + 1
        })
    end)

    self.unitRemovingConnection = Unit.UnitRemoving:Connect(function(unitId)
        local unit = Unit.fromId(unitId)
        if (unit.Owner ~= 0) then return end
        if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return false end

        self:setState({
            enemiesRemaining = self.state.enemiesRemaining - 1
        })
    end)

    self.centralTowerHealthChangedConnection = Game.CentralTowerHealthChanged:Connect(function(owner, newHealth)
        if (owner ~= 0) then return end

        self:setState({
            centralTowerHP = newHealth
        })
    end)

    self.phaseChangedConnection = Game.PhaseChanged:Connect(function(phase, phaseStartTime, phaseLength)
        self.stopTimerLoop()
        if (not (phaseStartTime and phaseLength)) then return end

        self:setState({
            phaseText = self.getPhaseText(phase),
            lastPhase = phase,

            phaseTransitionContainerRotation = randomValueInRange(-8, 8),
            bkgColors = BKG_COLORS[phase],
            bkgColorTransitions = generateTransition(self.state.lastPhase, phase),

            phaseTransitionChildrenColors = {
                Color3.fromHSV(math.random(), 1, 1),
                Color3.fromHSV(math.random(), 1, 1),
                Color3.fromHSV(math.random(), 1, 1),
                Color3.fromHSV(math.random(), 1, 1),
            },
        })

        self.makeTimerLoop(phaseStartTime, phaseLength)
        self.resetPhaseTransitionAnimators()
        self.doPhaseTransitionAnimation()
    end)

    if (gameState.CurrentPhaseLength and gameState.CurrentPhaseStartTime) then
        self.makeTimerLoop(gameState.CurrentPhaseLength, gameState.CurrentPhaseStartTime)
    end

    self:setState({
        totalRounds = gameState.TotalRounds,
        phaseText = self.getPhaseText(gameState.GamePhase),
        centralTowerHP = gameState.CentralTowersHealth["0"], -- for some reason the index gets turned into a string
        bkgColorTransitions = generateTransition(self.state.lastPhase, gameState.GamePhase),

        enemiesRemaining = #Unit.GetUnits(function(unit)
            if (unit.Owner ~= 0) then return false end
            if (unit.Type ~= GameEnum.UnitType.FieldUnit) then return false end

            return true
        end)
    })

    self.doPhaseTransitionAnimation()
end

GameState.willUnmount = function(self)
    for _, animator in pairs(self.phaseTransitionAnimators) do
        animator.DisconnectOnStep()
        animator.Motor:destroy()
    end

    for _, animator in pairs(self.bkgAnimators) do
        animator.DisconnectOnStep()
        animator.Motor:destroy()
    end

    self.roundStartedConnection:Disconnect()
    self.roundEndedConnection:Disconnect()
    self.phaseChangedConnection:Disconnect()
    self.unitAddedConnection:Disconnect()
    self.unitRemovingConnection:Disconnect()
    self.centralTowerHealthChangedConnection:Disconnect()

    if (self.timerLoop) then
        self.timerLoop:Disconnect()
    end
end

GameState.render = function(self)    
    local phaseTransitionChildren = {}

    for i = 1, 4 do
        local animatorBinding = self.phaseTransitionAnimators[i].Binding

        phaseTransitionChildren[i] = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            BackgroundTransparency = 0.5,
            ZIndex = -1,

            Position = animatorBinding:map(function(values)
                return UDim2.new(0.5, values.xOffset, 0.5, values.yOffset)
            end),

            Size = animatorBinding:map(function(values)
                return UDim2.new(0, values.size, 0, values.size)
            end),

            Rotation = animatorBinding:map(function(values)
                return values.rotation
            end),

            BackgroundColor3 = self.state.phaseTransitionChildrenColors[i]
        }, roundedCornersChildren(0.12, 0))
    end

    phaseTransitionChildren.PhaseLabel = Roact.createElement("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 0,
        BackgroundTransparency = 1,

        Position = self.phaseTransitionAnimators.PhaseLabel.Binding:map(function(values)
            return UDim2.new(values.position, 0, 0.5, 0)
        end),

        Text = self.state.phaseText,
        Font = FONT,
        TextSize = TITLE_TEXT_SIZE,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,

        TextTransparency = self.phaseTransitionAnimators.PhaseLabel.Binding:map(function(values)
            return values.transparency
        end),
        
        TextStrokeTransparency = self.phaseTransitionAnimators.PhaseLabel.Binding:map(function(values)
            return values.textStrokeTransparency
        end),

        TextColor3 = Color3.new(0, 0, 0),
        TextStrokeColor3 = Color3.new(1, 1, 1),
    })
    
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        CurrentRoundPrimaryBkg = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 100, 0, 100),
            Position = UDim2.new(0, 75, 1, -150),
            BorderSizePixel = 0,
            ZIndex = -1,

            Rotation = self.bkgAnimators.CurrentRoundPrimaryBkg.Binding:map(function(values)
                return values.rotation
            end),

            BackgroundColor3 = self.bkgAnimators.CurrentRoundPrimaryBkg.Binding:map(function(values)
                local colorTransition = self.state.bkgColorTransitions.CurrentRoundPrimaryBkg

                return colorTransition[1]:Lerp(colorTransition[2], values.colorTransitionAlpha)
            end)
        }, roundedCornersChildren(cornerRadiusScale, 0,  {
                CurrentRoundHintLabel = Roact.createElement(HintTextLabel, {
                    Text = "ROUND",
                    TextSize = 18,
                })
            })
        ),

        TotalRoundsPrimaryBkg = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0, 140, 1, -100),
            BorderSizePixel = 0,
            ZIndex = -2,

            Rotation = self.bkgAnimators.TotalRoundsPrimaryBkg.Binding:map(function(values)
                return values.rotation
            end),

            BackgroundColor3 = self.bkgAnimators.TotalRoundsPrimaryBkg.Binding:map(function(values)
                local colorTransition = self.state.bkgColorTransitions.TotalRoundsPrimaryBkg

                return colorTransition[1]:Lerp(colorTransition[2], values.colorTransitionAlpha)
            end)
        }, roundedCornersChildren(cornerRadiusScale, 0,  {
                TotalRoundsHintLabel = Roact.createElement(HintTextLabel, {
                    Text = "TOTAL"
                })
            })
        ),

        CurrentRoundSecondaryBkg = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 100, 0, 100),
            BorderSizePixel = 0,
            ZIndex = -3,

            Position = self.bkgAnimators.CurrentRoundSecondaryBkg.Binding:map(function(values)
                return UDim2.new(0, 75 + values.xOffset, 1, -150 + values.yOffset)
            end),

            Rotation = self.bkgAnimators.CurrentRoundSecondaryBkg.Binding:map(function(values)
                return values.rotation
            end),

            BackgroundColor3 = self.bkgAnimators.CurrentRoundSecondaryBkg.Binding:map(function(values)
                local colorTransition = self.state.bkgColorTransitions.CurrentRoundSecondaryBkg

                return colorTransition[1]:Lerp(colorTransition[2], values.colorTransitionAlpha)
            end)
        }, roundedCornersChildren(cornerRadiusScale, 0)),

        TotalRoundsSecondaryBkg = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 80, 0, 80),
            BorderSizePixel = 0,
            ZIndex = -4,

            Position = self.bkgAnimators.TotalRoundsSecondaryBkg.Binding:map(function(values)
                return UDim2.new(0, 140 + values.xOffset, 1, -100 + values.yOffset)
            end),

            Rotation = self.bkgAnimators.TotalRoundsSecondaryBkg.Binding:map(function(values)
                return values.rotation
            end),

            BackgroundColor3 = self.bkgAnimators.TotalRoundsSecondaryBkg.Binding:map(function(values)
                local colorTransition = self.state.bkgColorTransitions.TotalRoundsSecondaryBkg

                return colorTransition[1]:Lerp(colorTransition[2], values.colorTransitionAlpha)
            end)
        }, roundedCornersChildren(cornerRadiusScale, 0)),

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
            TextStrokeTransparency = 0.5,
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
    
            Text = "/ " .. self.state.totalRounds,
            Font = FONT,
            TextSize = MAIN_TEXT_SIZE / 2,
            TextStrokeTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
    
            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1),
        }),

        PhaseTransitionContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0, TITLE_TEXT_SIZE),
            Position = UDim2.new(0.5, 0, 1, -200),
            BorderSizePixel = 0,
            ZIndex = 0,
            BackgroundTransparency = 1,
            Rotation = self.state.phaseTransitionContainerRotation,
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
            TextSize = TIMER_TEXT_SIZE,
            TextStrokeTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
    
            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1),
        }),

        StatsContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 100, 0, 200),
            Position = UDim2.new(0, 205, 1, -50),
            BorderSizePixel = 0,
            ZIndex = 0,
            BackgroundTransparency = 1,
        }, {
            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, 0),
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),

            RemainingEnemiesIndicator = Roact.createElement(StatIndicator, {
                LayoutOrder = 0,
                Image = "rbxassetid://3414659960",
                Text = self.state.enemiesRemaining,

                BkgColor = Color3.fromRGB(255, 128, 85),
            }),

            CentralTowerHPIndicator = Roact.createElement(StatIndicator, {
                LayoutOrder = 1,
                Image = "rbxassetid://6711444602",
                ImageColor3 = Color3.new(1, 0, 0),
                Text = math.ceil(self.state.centralTowerHP),

                BkgColor = Color3.new(1, 0, 0),
            })
        })
    })
end

return GameState