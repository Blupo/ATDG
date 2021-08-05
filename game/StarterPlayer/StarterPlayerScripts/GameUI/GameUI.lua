local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))
local CurrencyBar = require(root:WaitForChild("CurrencyBar"))
local Hotbar = require(root:WaitForChild("Hotbar"))
local Inventory = require(root:WaitForChild("Inventory"))
local GameState = require(root:WaitForChild("GameState"))
local Padding = require(root:WaitForChild("Padding"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local Game = SystemCoordinator.waitForSystem("Game")

---

local GameUI = Roact.Component:extend("GameUI")

GameUI.init = function(self)
    self:setState({
        gameStarted = false,
        
        screenSize = Vector2.new()
    })
end

GameUI.didMount = function(self)
    local gameStarted = Game.HasStarted()

    if (gameStarted) then
        self:setState({
            gameStarted = gameStarted
        })
    else
        self.startedConnection = Game.Started:Connect(function()
            self.startedConnection:Disconnect()
            self.startedConnection = nil

            self:setState({
                gameStarted = gameStarted
            })
        end)
    end
end

GameUI.render = function(self)
    return Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    }, {
        UI = self.state.gameStarted and
            Roact.createElement("Frame", {
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
                
                CurrencyBar = Roact.createElement(CurrencyBar),
                Hotbar = Roact.createElement(Hotbar),
                Inventory = Roact.createElement(Inventory),
                State = Roact.createElement(GameState),
            })
        or nil
    })
end

return GameUI