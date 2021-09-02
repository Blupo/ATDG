local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))
local CurrencyBar = require(root:WaitForChild("CurrencyBar"))
local Hotbar = require(root:WaitForChild("Hotbar"))
local GameInventory = require(root:WaitForChild("GameInventory"))
local GameOverUI = require(root:WaitForChild("GameOverUI"))
local GameState = require(root:WaitForChild("GameState"))
local Padding = require(root:WaitForChild("Padding"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local Game = SystemCoordinator.waitForSystem("Game")

---

local GameUI = Roact.Component:extend("GameUI")

GameUI.init = function(self)
    self:setState({
        gameRunning = false,
        gameEnded = false,
    })
end

GameUI.didMount = function(self)
    local gameRunning = Game.IsRunning()

    if (gameRunning) then
        self:setState({
            gameRunning = gameRunning
        })
    else
        self.gameStarted = Game.Started:Connect(function()
            self.gameStarted:Disconnect()
            self.gameStarted = nil

            self:setState({
                gameRunning = true
            })
        end)
    end

    self.phaseChanged = Game.PhaseChanged:Connect(function(phase: string)
        if (phase == GameEnum.GamePhase.FinalIntermission) then
            self:setState({
                gamePhase = phase,
            })
        end
    end)

    self.gameEnded = Game.Ended:Connect(function(gameCompleted: boolean)
        self.phaseChanged:Disconnect()
        self.phaseChanged = nil

        self:setState({
            gameRunning = false,
            gamePhase = GameEnum.GamePhase.Ended,
            gameCompleted = gameCompleted,
        })
    end)
end

GameUI.willUnmount = function(self)
    self.gameEnded:Disconnect()
end

GameUI.render = function(self)
    local gameRunning = self.state.gameRunning
    local gamePhase = self.state.gamePhase
    local ui

    if (gameRunning) then
        ui = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Padding = Roact.createElement(Padding, {16}),
            
            CurrencyBar = Roact.createElement(CurrencyBar),
            Hotbar = Roact.createElement(Hotbar),
            GameInventory = Roact.createElement(GameInventory),
            GameState = Roact.createElement(GameState),
            
            -- todo: FinalIntermission dialog
        })
    else
        if (gamePhase == GameEnum.GamePhase.Ended) then
            ui = Roact.createElement(GameOverUI, {
                gameCompleted = self.state.gameCompleted
            })
        end
    end

    return Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    }, {
        UI = ui
    })
end

return GameUI