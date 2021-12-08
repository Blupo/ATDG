local GameUIModules = script.Parent.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint?
        Size?
        Position?
        CanvasSize?

        [Roact.Children]?
]]

local StandardScrollingFrame = Roact.PureComponent:extend("StandardScrollingFrame")

StandardScrollingFrame.render = function(self)
    return Roact.createElement("ScrollingFrame", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        CanvasPosition = Vector2.new(0, 0),
        CanvasSize = self.props.CanvasSize,

        --[[ TODO
        TopImage = Style.ScrollbarImage,
        MidImage = Style.ScrollbarImage,
        BottomImage = Style.ScrollbarImage,
        --]]

        HorizontalScrollBarInset = Enum.ScrollBarInset.None,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right,
        ScrollBarThickness = Style.Constants.StandardScrollbarThickness,

        ScrollBarImageColor3 = Color3.new(0, 0, 0),
    }, self.props[Roact.Children])
end

return StandardScrollingFrame