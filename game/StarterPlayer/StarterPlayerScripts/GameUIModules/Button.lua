local GameUIModules = script.Parent

local Color = require(GameUIModules:WaitForChild("Color"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint?
        Size?
        Position?
        LayoutOrder?
        Color: ColorSequence? = StandardGradient

        BackgroundColor3? = StandardButtonColor
        HoverBackgroundColor3?
        DisabledBackgroundColor3?

        For "Text" display type:
            Text
            TextColor3? = Color3.new(0, 0, 0)
            DisabledTextColor3 = Color3.fromRGB(120, 120, 120)?

        For "Image" display type:
            Image
            ImageSize: UDim2? = UDim2.new(1, 0, 1, 0)
            ImageColor3? = Color3.new(0, 0, 0)
            DisabledImageColor3 = Color3.fromRGB(120, 120, 120)?
        
        disabled: boolean?
        displayType: string<Image | Text | Children>
        onActivated: ()
        onMouseEnter: ()?
        onMouseLeave: ()?
        
        [Roact.Children]?
]]

local Button = Roact.PureComponent:extend("Button")

Button.init = function(self)
    self:setState({
        hovering = false
    })
end

Button.render = function(self)
    local disabled = self.props.disabled
    local hovering = self.state.hovering

    local backgroundColor3 = self.props.BackgroundColor3 or Style.Colors.StandardButtonColor
    local buttonColor

    local displayType = self.props.displayType
    local display

    if (disabled) then
        buttonColor = self.props.DisabledBackgroundColor3 or Color.from("Color3", backgroundColor3):desaturate():to("Color3")
    elseif (hovering) then
        buttonColor = self.props.HoverBackgroundColor3 or Color.from("Color3", backgroundColor3):darken():to("Color3")
    else
        buttonColor = backgroundColor3
    end

    if (displayType == "Image") then
        local imageSizeOffset = self.props.ImageSizeOffset or 0
        local imageColor3 = self.props.ImageColor3 or Color3.new(0, 0, 0)
        local disabledImageColor3 = self.props.DisabledImageColor3 or Color3.fromRGB(120, 120, 120)

        display = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, -imageSizeOffset, 1, -imageSizeOffset),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Image = self.props.Image,
            ScaleType = Enum.ScaleType.Fit,

            ImageColor3 = disabled and disabledImageColor3 or imageColor3,
        })
    elseif (displayType == "Text") then
        local textColor3 = self.props.TextColor3 or Color3.new(0, 0, 0)
        local disabledTextColor3 = self.props.DisabledTextColor3 or Color3.fromRGB(120, 120, 120)

        display = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = self.props.Text,
            Font = Style.Constants.PrimaryFont,
            TextSize = Style.Constants.StandardTextSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            
            TextColor3 = disabled and disabledTextColor3 or textColor3,
        })
    elseif (displayType == "Children") then
        display = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, self.props[Roact.Children])
    else
        return
    end

    return Roact.createElement("TextButton", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,
        AutoButtonColor = false,
        Active = (not disabled),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        Text = "",
        TextTransparency = 1,

        BackgroundColor3 = buttonColor,

        [Roact.Event.MouseEnter] = function()
            if (disabled) then return end

            if (self.props.onMouseEnter) then
                self.props.onMouseEnter()
            end

            self:setState({
                hovering = true
            })
        end,

        [Roact.Event.MouseLeave] = function()
            if (disabled) then return end

            if (self.props.onMouseLeave) then
                self.props.onMouseLeave()
            end

            self:setState({
                hovering = false
            })
        end,

        [Roact.Event.Activated] = function()
            if (disabled) then return end

            self.props.onActivated()
        end
    }, {
        UICorner = Roact.createElement(StandardComponents.UICorner),

        UIGradient = Roact.createElement(StandardComponents.UIGradient, {
            Color = self.props.Color,
        }),

        Display = display,
    })
end

return Button