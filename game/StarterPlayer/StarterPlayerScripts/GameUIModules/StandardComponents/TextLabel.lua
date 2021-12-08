local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint?
        Position?
        Size?
        LayoutOrder?
        SizeConstraint?
        BackgroundTransparency? = 1

        Text
        Font? = Style.PrimaryFont
        TextSize? = StandardTextSize
        TextScaled?
        TextWrapped?
        TextXAlignment? = Enum.TextXAlignment.Left
        TextYAlignment? = Enum.TextYAlignment.Center
        TextStrokeTransparency?
        RichText?

        BackgroundColor3? = Color3.new(1, 1, 1)
        TextColor3? = Color3.new(0, 0, 0)
        TextStrokeColor3? = Color3.new(1, 1, 1)

        [Roact.Children]?
]]

local StandardTextLabel = Roact.PureComponent:extend("StandardTextLabel")

StandardTextLabel.render = function(self)
    return Roact.createElement("TextLabel", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = self.props.BackgroundTransparency or 1,
        BorderSizePixel = 0,
        SizeConstraint = self.props.SizeConstraint,

        Text = self.props.Text,
        Font = self.props.Font or Style.Constants.PrimaryFont,
        TextSize = self.props.TextSize or Style.Constants.StandardTextSize,
        TextScaled = self.props.TextScaled,
        TextWrapped = self.props.TextWrapped,
        TextXAlignment = self.props.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = self.props.TextYAlignment or Enum.TextYAlignment.Center,
        TextStrokeTransparency = self.props.TextStrokeTransparency,
        RichText = self.props.RichText,

        BackgroundColor3 = self.props.BackgroundColor3 or Color3.new(1, 1, 1),
        TextColor3 = self.props.TextColor3 or Color3.new(0, 0, 0),
        TextStrokeColor3 = self.props.TextStrokeColor3 or Color3.new(1, 1, 1),
    }, self.props[Roact.Children])
end

return StandardTextLabel