local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local GameUIModules = script.Parent
local CurrencyBar = require(GameUIModules:WaitForChild("CurrencyBar"))
local GameResultsPage = require(GameUIModules:WaitForChild("GameResultsPage"))
local GameState = require(GameUIModules:WaitForChild("GameState"))
local Hotbar = require(GameUIModules:WaitForChild("Hotbar"))
local MainInventory = require(GameUIModules:WaitForChild("MainInventory"))
local Roact = require(GameUIModules:WaitForChild("Roact"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local Game = SystemCoordinator.waitForSystem("Game")

---

local GameServerUI = Roact.PureComponent:extend("GameServerUI")

GameServerUI.init = function(self)
    self:setState({
        gameEnded = false
    })
end

GameServerUI.didMount = function(self)
    local gameState = Game.GetDerivedGameState()

    self.phaseChangedConnection = Game.PhaseChanged:Connect(function(phase)
        if (phase == GameEnum.GamePhase.Ended) then
            self:setState({
                gameEnded = true,
            })
        end
    end)

    self:setState({
        gameEnded = (gameState.GamePhase == GameEnum.GamePhase.Ended)
    })
end

GameServerUI.willUnmount = function(self)
    self.phaseChangedConnection:Disconnect()
end

GameServerUI.render = function(self)
    local elements

    if (self.state.gameEnded) then
        elements = {
            GameState = Roact.createElement(GameState),
            GameResults = Roact.createElement(GameResultsPage),
        }
    else
        elements = {
            GameState = Roact.createElement(GameState),
            Hotbar = Roact.createElement(Hotbar),
            MainInventory = Roact.createElement(MainInventory),

            CurrencyBar = Roact.createElement(CurrencyBar, {
                currencies = {
                    GameEnum.CurrencyType.Tickets,
                    GameEnum.CurrencyType.Points
                }
            }),
        }
    end

    return Roact.createFragment(elements)
end

return GameServerUI