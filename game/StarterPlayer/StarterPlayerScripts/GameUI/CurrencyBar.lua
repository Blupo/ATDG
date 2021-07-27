local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent

local LocalPlayer = Players.LocalPlayer

local Roact = require(root:WaitForChild("Roact"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local PlayerData = SystemCoordinator.getSystem("PlayerData")

---

local CurrencyItem = Roact.PureComponent:extend("CurrencyItem")

CurrencyItem.render = function(self)
    return Roact.createElement("Frame", {
        Size = UDim2.new(0, 90, 1, 0),
        Position = self.props.Position,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = self.props.LayoutOrder,
    }, {
        Icon = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(0, 2, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = self.props.Image or "rbxasset://textures/ui/GuiImagePlaceholder.png",

            ImageColor3 = self.props.ImageColor3
        }),

        Label = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.new(1, -36, 0, 0),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = self.props.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextStrokeTransparency = 0.5,

            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1),
        })
    })
end

local CurrencyBar = Roact.PureComponent:extend("CurrencyBar")

CurrencyBar.init = function(self)
    self:setState({
        currencies = {
            [GameEnum.CurrencyType.Tickets] = 0,
            [GameEnum.CurrencyType.Points] = 0,
        }
    })
end

CurrencyBar.didMount = function(self)
    self.currencyBalanceChanged = PlayerData.CurrencyBalanceChanged:Connect(function(_, currencyType, newBalance)
        local currenciesCopy = CopyTable(self.state.currencies)
        currenciesCopy[currencyType] = newBalance

        self:setState({
            currencies = currenciesCopy
        })
    end)

    self:setState({
        currencies = PlayerData.GetPlayerAllCurrenciesBalances(LocalPlayer.UserId)
    })
end

CurrencyBar.willUnmount = function(self)
    self.currencyBalanceChanged:Disconnect()
end

CurrencyBar.render = function(self)
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(0, 220, 0, 32),
        Position = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, 16),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),

        Tickets = Roact.createElement(CurrencyItem, {
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 0,

            Text = self.state.currencies[GameEnum.CurrencyType.Tickets]
        }),

        Points = Roact.createElement(CurrencyItem, {
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 1,

            Text = self.state.currencies[GameEnum.CurrencyType.Points]
        })
    })
end

return CurrencyBar