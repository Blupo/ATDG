local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local GameUIModules = script.Parent
local CurrencyBar = require(GameUIModules:WaitForChild("CurrencyBar"))
local Hotbar = require(GameUIModules:WaitForChild("Hotbar"))
local GamePage = require(GameUIModules:WaitForChild("GamePage"))
local MenuButton = require(GameUIModules:WaitForChild("MenuButton"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local ShopPage = require(GameUIModules:WaitForChild("ShopPage"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

local menuPages = {
    GamePage = GamePage,
    ShopPage = ShopPage,
}

---

local LobbyServerUI = Roact.PureComponent:extend("LobbyServerUI")

LobbyServerUI.render = function(self)
    local currentPage = self.state.currentPage

    return Roact.createFragment({
        MenuButtons = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, Style.Constants.MenuButtonSize, 1, 0),
            Position = UDim2.new(0, Style.Constants.MajorElementPadding * 2, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            GamesPageButton = Roact.createElement(MenuButton, {
                LayoutOrder = 0,
                Image = Style.Images.GamesPageMenuButtonIcon,
                Color = Style.Colors.YellowProminentGradient,

                onActivated = function()
                    self:setState({
                        currentPage = (currentPage == "GamePage") and Roact.None or "GamePage",
                    })
                end,
            }),

            ShopPageButton = Roact.createElement(MenuButton, {
                LayoutOrder = 1,
                Image = Style.Images.ShopPageMenuButtonIcon,
                Color = Style.Colors.OrangeProminentGradient,

                onActivated = function()
                    self:setState({
                        currentPage = (currentPage == "ShopPage") and Roact.None or "ShopPage",
                    })
                end,
            }),

            UIListLayout = Roact.createElement(StandardComponents.UIListLayout, {
                Padding = UDim.new(0, Style.Constants.MajorElementPadding)
            })
        }),

        CurrentPage = (currentPage) and 
            Roact.createElement(menuPages[currentPage])
        or nil,

        CurrencyBar = Roact.createElement(CurrencyBar, {
            currencies = {
                GameEnum.CurrencyType.Tickets,
            }
        }),

        Hotbar = Roact.createElement(Hotbar),
    })
end

return LobbyServerUI