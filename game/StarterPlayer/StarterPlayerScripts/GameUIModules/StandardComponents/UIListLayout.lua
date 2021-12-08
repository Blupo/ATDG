local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        Padding? = UDim.new(0, SpaciousElementPadding)
        FillDirection? = Enum.FillDirection.Vertical
        HorizontalAlignment? = Enum.HorizontalAlignment.Center
        VerticalAlignment? = Enum.VerticalAlignment.Center
        SortOrder? = Enum.SortOrder.LayoutOrder

        [Roact.Change.AbsoluteContentSize]?
]]

local StandardUIListLayout = Roact.PureComponent:extend("StandardUIListLayout")

StandardUIListLayout.render = function(self)
    return Roact.createElement("UIListLayout", {
        Padding = self.props.Padding or UDim.new(0, Style.Constants.SpaciousElementPadding),
        FillDirection = self.props.FillDirection or Enum.FillDirection.Vertical,
        HorizontalAlignment = self.props.HorizontalAlignment or Enum.HorizontalAlignment.Center,
        VerticalAlignment = self.props.VerticalAlignment or Enum.VerticalAlignment.Center,
        SortOrder = self.props.SortOrder or Enum.SortOrder.LayoutOrder,

        [Roact.Change.AbsoluteContentSize] = self.props[Roact.Change.AbsoluteContentSize]
    })
end

return StandardUIListLayout