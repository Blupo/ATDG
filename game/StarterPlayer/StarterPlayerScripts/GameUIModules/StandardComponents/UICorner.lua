local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        CornerRadius? = StandardCornerRadius
]]

local StandardUICorner = Roact.PureComponent:extend("StandardUICorner")

StandardUICorner.render = function(self)
    return Roact.createElement("UICorner", {
        CornerRadius = UDim.new(0, self.props.CornerRadius or Style.Constants.StandardCornerRadius)
    })
end

return StandardUICorner