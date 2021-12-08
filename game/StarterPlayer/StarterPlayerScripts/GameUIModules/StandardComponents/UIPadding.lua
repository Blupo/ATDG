local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props: array<number>
        If 0 numbers are provided:
            Top = Bottom = Left = Right = SpaciousElementPadding
        If 1 number is provided:
            Top = Bottom = Left = Right = props[1]
        If 2 numbers are provided:
            Top, Bottom = props[1]
            Left, Right = props[2]
        If 4 numbers are provided:
            Top = props[1]
            Bottom = props[2]
            Left = props[3]
            Right = props[4]
]]

local StandardUIPadding = Roact.PureComponent:extend("StandardUIPadding")

StandardUIPadding.render = function(self)
    local top, bottom, left, right

    local paddings = self.props
    local numPaddings = #paddings

    if (numPaddings == 0) then
        top, bottom, left, right =
            Style.Constants.SpaciousElementPadding,
            Style.Constants.SpaciousElementPadding,
            Style.Constants.SpaciousElementPadding,
            Style.Constants.SpaciousElementPadding
    elseif (numPaddings == 1) then
        top, bottom, left, right = paddings[1], paddings[1], paddings[1], paddings[1]
    elseif (numPaddings == 2) then
        top, bottom, left, right = paddings[1], paddings[1], paddings[2], paddings[2]
    elseif (numPaddings == 4) then
        top, bottom, left, right = paddings[1], paddings[2], paddings[3], paddings[4]
    end

    return Roact.createElement("UIPadding", {
        PaddingTop = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom),
        PaddingLeft = UDim.new(0, left),
        PaddingRight = UDim.new(0, right),
    })
end

return StandardUIPadding