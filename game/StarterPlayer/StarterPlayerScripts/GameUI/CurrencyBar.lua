local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))

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

            Text = self.props.Text or "###",
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextStrokeColor3 = Color3.new(1, 1, 1),
            TextStrokeTransparency = 0.5,
        })
    })
end

local CurrencyBar = Roact.PureComponent:extend("CurrencyBar")

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
        }),

        Points = Roact.createElement(CurrencyItem, {
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 1,
        })
    })
end

return CurrencyBar