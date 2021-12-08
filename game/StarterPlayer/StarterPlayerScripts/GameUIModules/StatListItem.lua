local GameUIModules = script.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint?
        Size?
        Position?
        LayoutOrder?

        Image
        Text
        TextXAlignment?

        ImageColor3? = Color3.new(0, 0, 0)
        TextColor3? = Color3.new(0, 0, 0)
]]

local StatListItem = Roact.PureComponent:extend("StatListItem")

StatListItem.render = function(self)
    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Icon = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Image = self.props.Image,
            ImageColor3 = self.props.ImageColor3,
        }),

        StatText = Roact.createElement(StandardComponents.TextLabel, {
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.new(1, -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding), 0, Style.Constants.StandardTextSize),
            Position = UDim2.new(1, 0, 0.5, 0),

            Text = self.props.Text,
            TextScaled = true,
            TextXAlignment = self.props.TextXAlignment,
        })
    })
end

return StatListItem