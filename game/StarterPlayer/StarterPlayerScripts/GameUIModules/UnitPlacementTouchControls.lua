local GameUIModules = script.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout

---

local ICON_SIZE = 64

local generateButton = function(props)
    return Roact.createElement("TextButton", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        LayoutOrder = props.LayoutOrder,

        Text = "",
        TextTransparency = 1,

        BackgroundColor3 = props.BackgroundColor3,

        [Roact.Event.Activated] = props.onActivated,
    }, {
        UICorner = Roact.createElement(StandardUICorner),

        Image = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, -Style.Constants.MinorElementPadding, 1, -Style.Constants.MinorElementPadding),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Image = props.Image,
            ImageColor3 = props.ImageColor3,
        })
    })
end

--[[
    props

        Adornee
        StudsOffsetWorldSpace

        onRotateLeft: ()
        onRotateRight: ()
        onCancel: ()
        onPlace: ()
]]

local UnitPlacementTouchControls = Roact.PureComponent:extend("UnitPlacementTouchControls")

UnitPlacementTouchControls.render = function(self)
    return Roact.createElement("BillboardGui", {
        Adornee = self.props.Adornee,
        Size = UDim2.new(0, (ICON_SIZE * 4) + (Style.Constants.MajorElementPadding * 3), 0, ICON_SIZE),
        StudsOffsetWorldSpace = self.props.StudsOffsetWorldSpace,
        LightInfluence = 0,
        Active = true,
        AlwaysOnTop = true,
        ResetOnSpawn = false,
        ClipsDescendants = true,
    }, {
        UIListLayout = Roact.createElement(StandardUIListLayout, {
            Padding = UDim.new(0, Style.Constants.MajorElementPadding),
    
            FillDirection = Enum.FillDirection.Horizontal,
        }),

        RotateLeftButton = generateButton({
            Image = "rbxassetid://7547827485",
            LayoutOrder = 0,

            BackgroundColor3 = Color3.fromRGB(230, 230, 230),
            ImageColor3 = Color3.new(0, 0, 0),

            onActivated = self.props.onRotateLeft,
        }),

        RotateRightButton = generateButton({
            Image = "rbxassetid://7547826314",
            LayoutOrder = 3,

            BackgroundColor3 = Color3.fromRGB(230, 230, 230),
            ImageColor3 = Color3.new(0, 0, 0),

            onActivated = self.props.onRotateRight,
        }),

        PlaceButton = generateButton({
            Image = "rbxassetid://1469818624",
            LayoutOrder = 1,

            BackgroundColor3 = Color3.fromRGB(0, 170, 255),
            ImageColor3 = Color3.new(1, 1, 1),

            onActivated = self.props.onPlace,
        }),

        CancelButton = generateButton({
            Image = "rbxassetid://367878870",
            LayoutOrder = 2,

            BackgroundColor3 = Color3.fromRGB(200, 0, 0),
            ImageColor3 = Color3.new(1, 1, 1),

            onActivated = self.props.onCancel,
        }),
    })
end

---

return UnitPlacementTouchControls