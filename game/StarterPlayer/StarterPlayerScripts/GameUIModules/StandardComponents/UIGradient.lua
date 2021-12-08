local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        Color? = StandardGradient
        Rotation? = StandardGradientRotation
        Transparency? = NumberSequence.new(0)
]]

local StandardUIGradient = Roact.PureComponent:extend("StandardUIGradient")

StandardUIGradient.render = function(self)
    return Roact.createElement("UIGradient", {
        Color = self.props.Color or Style.Colors.StandardGradient,
        Rotation = self.props.Rotation or Style.Constants.StandardGradientRotation,
        Transparency = self.props.Transparency or NumberSequence.new(0)
    })
end

return StandardUIGradient