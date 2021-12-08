local GameUIModules = script.Parent
local Button = require(GameUIModules:WaitForChild("Button"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint?
        Position?
        LayoutOrder?

        subtext: string
        hoverSubtext: string?
        selected: boolean?
        
        onActivated: ()
        onMouseEnter: ()?
        onMouseLeave: ()?

        [Roact.Children]?
]]

local InventoryListFrame = Roact.PureComponent:extend("InventoryListFrame")

InventoryListFrame.init = function(self)
    self:setState({
        hovering = false,
    })
end

InventoryListFrame.render = function(self)
    local subtext

    if (self.state.hovering) then
        subtext = self.props.hoverSubtext or self.props.subtext
    else
        subtext = self.props.subtext
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Size = UDim2.new(
            0, Style.Constants.InventoryFrameButtonSize,
            0, Style.Constants.InventoryFrameButtonSize +
                Style.Constants.MinorElementPadding +
                Style.Constants.StandardTextSize + 
                Style.Constants.SpaciousElementPadding
        ),
    }, {
        Button = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(0, Style.Constants.InventoryFrameButtonSize, 0, Style.Constants.InventoryFrameButtonSize),
            Position = UDim2.new(0.5, 0, 0, 0),

            Color = self.props.selected and ColorSequence.new(Color3.new(1, 1, 1), Style.Colors.SelectionColor) or Style.Colors.StandardGradient,
            BackgroundColor3 = Color3.new(1, 1, 1),

            displayType = "Children",
            onActivated = self.props.onActivated,

            onMouseEnter = function()
                if (self.props.onMouseEnter) then
                    self.props.onMouseEnter()
                end

                self:setState({
                    hovering = true
                })
            end,

            onMouseLeave = function()
                if (self.props.onMouseLeave) then
                    self.props.onMouseLeave()
                end

                self:setState({
                    hovering = false
                })
            end,
        }, self.props[Roact.Children]),

        Subtext = Roact.createElement(StandardComponents.TextLabel, {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize + Style.Constants.SpaciousElementPadding),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 0,

            Text = subtext,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, {
            UICorner = Roact.createElement(StandardComponents.UICorner),
            UIPadding = Roact.createElement(StandardComponents.UIPadding, { Style.Constants.MinorElementPadding })
        })
    })
end

return InventoryListFrame