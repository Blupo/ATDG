local root = script.Parent
local Roact = require(root:WaitForChild("Roact"))
local GameState = require(root:WaitForChild("GameState"))

local PlayerScripts = root.Parent
local GameModules = PlayerScripts:WaitForChild("GameModules")
local Game = require(GameModules:WaitForChild("Game"))

---

local GameUI = Roact.Component:extend("GameUI")

GameUI.init = function(self)
    self:setState({
        gameStarted = false
    })
end

GameUI.didMount = function(self)
    local gameStarted = Game:HasStarted()

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
            Roact.createElement(GameState)
        or nil
    })
end

return GameUI