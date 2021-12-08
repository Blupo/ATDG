local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local GameListPage = require(GameUIModules:WaitForChild("GameListPage"))
local MainElementContainer = require(GameUIModules:WaitForChild("MainElementContainer"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local SimpleGameCreationPage = require(GameUIModules:WaitForChild("SimpleGameCreationPage"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Matchmaking = require(GameModules:WaitForChild("Matchmaking"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

local pages = {
    GameList = GameListPage,
    SimpleGameCreation = SimpleGameCreationPage,
    FullGameCreation = nil, -- TODO
}

---

local GamePage = Roact.PureComponent:extend("GamePage")

GamePage.init = function(self)
    self:setState({
        page = "GameList",
    })
end

GamePage.render = function(self)
    local page = self.state.page
    local pageProps

    if (page == "GameList") then
        pageProps = {
            onCreateSimpleGame = function()
                self:setState({
                    page = "SimpleGameCreation",
                })
            end,

            onCreateFullGame = function()
                print("Full game creation is not available")
            end,
        }
    else
        pageProps = {
            onCancel = function()
                self:setState({
                    page = "GameList",
                })
            end,

            onCreateGame = function(map, difficulty, accessRules)
                Matchmaking.OpenGame(LocalPlayer, {
                    MapName = map,
                    GameMode = GameEnum.GameMode.TowerDefense,
                    Difficulty = difficulty,
                }, {}, accessRules)

                self:setState({
                    page = "GameList",
                })
            end,
        }
    end

    return Roact.createElement(MainElementContainer, {
        ScaleX = 0.5,
        ScaleY = 0.5,
        AspectRatio = 1.4,

        StrokeGradient = Style.Colors.YellowProminentGradient,
    }, {
        Page = Roact.createElement(pages[page], pageProps)
    })
end

return GamePage