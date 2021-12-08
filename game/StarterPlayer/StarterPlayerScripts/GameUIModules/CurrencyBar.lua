local Players = game:GetService("Players")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Color = require(GameUIModules:WaitForChild("Color"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        LayoutOrder?

        currencyType: CurrencyType
]]

local CurrencyBarItem = Roact.PureComponent:extend("CurrencyBarItem")

CurrencyBarItem.init = function(self)
    self:setState({
        amount = 0,
    })
end

CurrencyBarItem.didMount = function(self)
    self.currencyBalanceChanged = PlayerData.CurrencyBalanceChanged:Connect(function(_, currencyType, newBalance)
        if (currencyType ~= self.props.currencyType) then return end

        self:setState({
            amount = newBalance
        })
    end)

    self:setState({
        amount = PlayerData.GetPlayerCurrencyBalance(LocalPlayer.UserId, self.props.currencyType)
    })
end

CurrencyBarItem.didUpdate = function(self, prevProps)
    local currencyType = self.props.currencyType
    if (currencyType == prevProps.currencyType) then return end

    self:setState({
        amount = PlayerData.GetPlayerCurrencyBalance(LocalPlayer.UserId, currencyType)
    })
end

CurrencyBarItem.willUnmount = function(self)
    self.currencyBalanceChanged:Disconnect()
end

CurrencyBarItem.render = function(self)
    local currencyType = self.props.currencyType
    local currencyColor = Style.Colors[currencyType .. "CurrencyColor"]

    return Roact.createElement("Frame", {
        Size = UDim2.new(0, 90, 1, 0),
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        CurrencyIcon = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = currencyColor,
        }, {
            UICorner = Roact.createElement(StandardComponents.UICorner),

            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = Style.Images[currencyType .. "CurrencyIcon"],

                ImageColor3 = Color.from("Color3", currencyColor):bestContrastingColor(
                    Color.new(0, 0, 0),
                    Color.new(1, 1, 1)
                ):to("Color3")
            })
        }),

        AmountLabel = Roact.createElement(StandardComponents.TextLabel, {
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.new(1, -32, 1, 0),
            Position = UDim2.new(1, 0, 0.5, 0),

            Text = self.state.amount,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextStrokeTransparency = Style.Constants.StandardTextStrokeTransparency,

            TextStrokeColor3 = Color3.new(1, 1, 1)
        })
    })
end

--

--[[
    props

        currencies: array<CurrencyType>
]]

local CurrencyBar = Roact.PureComponent:extend("CurrencyBar")

CurrencyBar.render = function(self)
    local currencies = self.props.currencies
    local currencyBarElements = {}

    for i = 1, #currencies do
        local currency = currencies[i]

        currencyBarElements[currency] = Roact.createElement(CurrencyBarItem, {
            LayoutOrder = i,

            currencyType = currency,
        })
    end

    currencyBarElements.UIListLayout = Roact.createElement(StandardComponents.UIListLayout, {
        FillDirection = Enum.FillDirection.Horizontal,
    })
    
    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(1, 0, 0, Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding),
        Position = UDim2.new(0.5, 0, 1, -Style.Constants.MajorElementPadding),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, currencyBarElements)
end

return CurrencyBar