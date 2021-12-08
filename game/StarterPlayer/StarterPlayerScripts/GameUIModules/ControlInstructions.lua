local TextService = game:GetService("TextService")

---

local GameUIModules = script.Parent

local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout

---

local ICON_SIZE = 40

local controlTypes = {
    [Enum.UserInputType.MouseButton1] = "MouseAndKeyboard",
    [Enum.KeyCode.Q] = "MouseAndKeyboard",
    [Enum.KeyCode.R] = "MouseAndKeyboard",

    [Enum.KeyCode.ButtonA] = "GamepadButton",
    [Enum.KeyCode.ButtonY] = "GamepadButton",
    [Enum.KeyCode.ButtonB] = "GamepadButton",
    [Enum.KeyCode.ButtonL1] = "GamepadBumper",
    [Enum.KeyCode.ButtonR1] = "GamepadBumper",
}

local controlText = {
    [Enum.KeyCode.Q] = "Q",
    [Enum.KeyCode.R] = "R",

    [Enum.KeyCode.ButtonA] = "A",
    [Enum.KeyCode.ButtonY] = "Y",
    [Enum.KeyCode.ButtonB] = "B",
    [Enum.KeyCode.ButtonL1] = "LB",
    [Enum.KeyCode.ButtonR1] = "RB",
}

local controlTextColors = {
    [Enum.KeyCode.ButtonA] = Color3.fromRGB(2, 183, 87),
    [Enum.KeyCode.ButtonY] = Color3.fromRGB(246, 183, 2),
    [Enum.KeyCode.ButtonB] = Color3.fromRGB(226, 35, 26),
}

local controlImages = {
    [Enum.UserInputType.MouseButton1] = "rbxassetid://7547738510",
}

local generateControlFrame = function(control: Enum.UserInputType | Enum.KeyCode)
    local controlType = controlTypes[control]
    if (not controlType) then return end

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, ICON_SIZE, 0, (controlType ~= "GamepadBumper") and ICON_SIZE or 24),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.new(0, 0, 0)
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = (controlType ~= "GamepadButton") and UDim.new(0, Style.Constants.StandardCornerRadius) or UDim.new(1, 0),
        }),

        ControlText = (control ~= Enum.UserInputType.MouseButton1) and
            Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),

                Text = controlText[control],
                TextSize = 24,
                TextXAlignment = Enum.TextXAlignment.Center,

                TextColor3 = controlTextColors[control] or Color3.new(1, 1, 1),
            })
        or nil,

        ControlImage = (control == Enum.UserInputType.MouseButton1) and
            Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, -Style.Constants.MinorElementPadding, 1, -Style.Constants.MinorElementPadding),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = controlImages[control],
                ImageColor3 = Color3.new(1, 1, 1)
            })
        or nil,
    })
end

---

--[[
    props

        controls: {
            [Enum.UserInputType | Enum.KeyCode]: {
                LayoutOrder: number,
                Instructions: string
            }
        }
]]

local ControlInstructions = Roact.PureComponent:extend("ControlInstructions")

ControlInstructions.render = function(self)
    local controls = self.props.controls
    local controlListElements = {}

    for control, controlInfo in pairs(controls) do
        local instructions = controlInfo.Instructions
        local instructionsTextSize = TextService:GetTextSize(instructions, 20, Style.Constants.PrimaryFont, Vector2.new(math.huge, math.huge))

        controlListElements[tostring(control)] = Roact.createElement("Frame", {
            Size = UDim2.new(0, ICON_SIZE + Style.Constants.MinorElementPadding + instructionsTextSize.X, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = controlInfo.LayoutOrder
        }, {
            ControlFrame = generateControlFrame(control),

            InstructionsLabel = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -ICON_SIZE, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),

                Text = instructions,
                TextSize = 20,
                TextStrokeTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Right,
            })
        })
    end

    controlListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),

        FillDirection = Enum.FillDirection.Horizontal,
    })

    return Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, {
        Container = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0, ICON_SIZE),
            Position = UDim2.new(0.5, 0, 1, -120),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, controlListElements)
    })
end

---

return ControlInstructions