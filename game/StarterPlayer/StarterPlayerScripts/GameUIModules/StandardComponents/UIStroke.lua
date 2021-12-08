local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        Thickness? = StandardBorderWidth
        Gradient: ColorSequence?
]]

local StandardUIStroke = Roact.PureComponent:extend("StandardUIStroke")

StandardUIStroke.render = function(self)
    return Roact.createElement("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
        Thickness = self.props.Thickness or Style.Constants.StandardBorderWidth,

        Color = Color3.new(1, 1, 1)
    }, {
        UIGradient = self.props.Gradient and
            Roact.createElement("UIGradient", {
                Color = self.props.Gradient,
                Rotation = Style.Constants.StandardGradientRotation,
                Transparency = NumberSequence.new(0)
            })
        or nil
    })
end

return StandardUIStroke