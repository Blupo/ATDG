local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

---

--[[
    props

        onActivated
        onMouseEnter
        onMouseLeave

        disabled

        AnchorPoint?
        Size?
        Position?
        LayoutOrder?
]]

local IconButton = Roact.PureComponent:extend("IconButton")

IconButton.render = function(self)
    return Roact.createElement("TextButton", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.fromRGB(230, 230, 230),

        Text = "",
        TextTransparency = 1,

        [Roact.Event.Activated] = function()
            if (self.props.disabled) then return end

            self.props.onActivated()
        end,

        [Roact.Event.MouseEnter] = self.props.onMouseEnter and
            function()
                if (self.props.disabled) then return end

                self.props.onMouseEnter()
            end
        or nil,

        [Roact.Event.MouseLeave] = self.props.onMouseLeave and
            function()
                if (self.props.disabled) then return end
                
                self.props.onMouseLeave()
            end
        or nil
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius),
        }),

        Icon = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, -4, 1, -4),
            Position = UDim2.new(0, 2, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,

            Image = self.props.Image,
            ImageColor3 = self.props.ImageColor3,
        }),

        Label = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.new(1, -36, 1, 0),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = self.props.Text,
            Font = Style.Constants.MainFont,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            
            TextColor3 = Color3.new(0, 0, 0)
        })
    })
end

return IconButton