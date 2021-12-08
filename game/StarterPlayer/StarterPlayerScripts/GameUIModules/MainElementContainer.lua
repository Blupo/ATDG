local GameUIModules = script.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint? = Vector2.new(0.5, 0.5)
        Position? = UDim2.new(0.5, 0, 0.5, 0)
        Size
            If AspectRatio is not specified
        ScaleX: number
        ScaleY: number
            If AspectRatio is specified
        AspectRatio?
        StrokeGradient? = StandardGradient
        Padding? = MajorElementPadding

        [Roact.Children]?
]]

local MainElementContainer = Roact.PureComponent:extend("MainElementContainer")

MainElementContainer.render = function(self)
    local aspectRatio = self.props.AspectRatio

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint or Vector2.new(0.5, 0.5),
        Position = self.props.Position or UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Active = true,

        Size = aspectRatio and
            UDim2.new(self.props.ScaleX, -Style.Constants.ProminentBorderWidth * 2, self.props.ScaleY, -Style.Constants.ProminentBorderWidth * 2)
        or self.props.Size,

        BackgroundColor3 = Color3.new(1, 1, 1),
    }, {
        UIPadding = Roact.createElement(StandardComponents.UIPadding, { self.props.Padding or Style.Constants.MajorElementPadding }),

        UICorner = Roact.createElement(StandardComponents.UICorner, {
            CornerRadius = Style.Constants.LargeCornerRadius
        }),

        UIStroke = Roact.createElement(StandardComponents.UIStroke, {
            Gradient = self.props.StrokeGradient or Style.Colors.StandardGradient,
            Thickness = Style.Constants.ProminentBorderWidth,
        }),

        UIAspectRatioConstraint = (aspectRatio) and
            Roact.createElement("UIAspectRatioConstraint", {
                AspectRatio = aspectRatio,
                AspectType = Enum.AspectType.FitWithinMaxSize,
                DominantAxis = Enum.DominantAxis.Width,
            })
        or nil,

        Content = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, self.props[Roact.Children])
    })
end

return MainElementContainer