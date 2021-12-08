local GameUIModules = script.Parent

local Color = require(GameUIModules:WaitForChild("Color"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint?
        Position?
        LayoutOrder?
        Image
        Color: ColorSequence

        onActivated: ()
]]

local MenuButton = Roact.PureComponent:extend("MenuButton")

MenuButton.init = function(self)
    self:setState({
        hovering = false
    })
end

MenuButton.render = function(self)
    return Roact.createElement("TextButton", {
        AnchorPoint = self.props.AnchorPoint,
        Size = UDim2.new(0, Style.Constants.MenuButtonSize, 0, Style.Constants.MenuButtonSize),
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Text = "",
        TextTransparency = 1,

        [Roact.Event.MouseEnter] = function()
            self:setState({
                hovering = true
            })
        end,

        [Roact.Event.MouseLeave] = function()
            self:setState({
                hovering = false
            })
        end,

        [Roact.Event.Activated] = function()
            self.props.onActivated()
        end
    }, {
        VisualContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, -Style.Constants.ProminentBorderWidth, 1, -Style.Constants.ProminentBorderWidth),
            Position = UDim2.new(0.5, 0, 0.5, 0),

            BackgroundColor3 = self.state.hovering and Color.new(1, 1, 1):darken():to("Color3") or Color3.new(1, 1, 1),
        }, {
            UICorner = Roact.createElement(StandardComponents.UICorner, { CornerRadius = Style.Constants.LargeCornerRadius }),
            UIGradient = Roact.createElement(StandardComponents.UIGradient, { Color = self.props.Color }),
            UIStroke = Roact.createElement(StandardComponents.UIStroke),

            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 48, 0, 48),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = self.props.Image,
                ImageColor3 = Color3.new(1, 1, 1)
            })
        })
    })
end

return MenuButton