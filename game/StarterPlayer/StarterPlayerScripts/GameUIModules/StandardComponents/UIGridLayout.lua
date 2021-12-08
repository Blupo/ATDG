local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        CellSize
        CellPadding? = UDim2.new(0, SpaciousElementPadding, 0, SpaciousElementPadding)
        FillDirection? = Enum.FillDirection.Horizontal
        StartCorner? = Enum.StartCorner.TopLeft
        HorizontalAlignment? = Enum.HorizontalAlignment.Left
        VerticalAlignment? = Enum.VerticalAlignment.Top
        SortOrder? = Enum.SortOrder.LayoutOrder

        [Roact.Change.AbsoluteContentSize]?
        [Roact.Children]?
]]

local StandardUIGridLayout = Roact.PureComponent:extend("StandardUIGridLayout")

StandardUIGridLayout.render = function(self)
    return Roact.createElement("UIGridLayout", {
        CellSize = self.props.CellSize,
        CellPadding = self.props.CellPadding or UDim2.new(0, Style.Constants.SpaciousElementPadding, 0, Style.Constants.SpaciousElementPadding),
        StartCorner = self.props.StartCorner or Enum.StartCorner.TopLeft,
        FillDirection = self.props.FillDirection or Enum.FillDirection.Horizontal,
        HorizontalAlignment = self.props.HorizontalAlignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment = self.props.VerticalAlignment or Enum.VerticalAlignment.Top,
        SortOrder = self.props.SortOrder or Enum.SortOrder.LayoutOrder,

        [Roact.Change.AbsoluteContentSize] = self.props[Roact.Change.AbsoluteContentSize]
    }, self.props[Roact.Children])
end

return StandardUIGridLayout