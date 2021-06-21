local GameUI = script.Parent
local PlayerScripts = GameUI.Parent

local Roact = require(GameUI:WaitForChild("Roact"))
local Style = require(GameUI:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

---

--[[
    props

    Adornee?
    Size?
    StudsOffsetWorldSpace?

    unitId: string
]]

local FieldUnitBillboard = Roact.PureComponent:extend("FieldUnitBillboard")

FieldUnitBillboard.init = function(self)
    self:setState({
        name = "",
        hp = 0,
        maxHP = 0,
    })
end

FieldUnitBillboard.didMount = function(self)
    local unit = Unit.fromId(self.props.unitId)
    if (not unit) then return end

    self.unitRemoving = Unit.UnitRemoving:Connect(function(unitId)
        if (unitId ~= self.props.unitId) then return end

        if (self.hpChanged) then
            self.hpChanged:Disconnect()
            self.hpChanged = nil
        end

        self.unitRemoving:Disconnect()
        self.unitRemoving = nil
    end)

    self.hpChanged = unit.AttributeChanged:Connect(function(attributeName, newValue)
        if (attributeName ~= "HP") then return end

        self:setState({
            hp = newValue
        })
    end)

    self:setState({
        name = unit.Name,
        level = unit.Level,

        hp = unit:GetAttribute("HP"),
        maxHP = unit:GetAttribute("MaxHP"),
    })
end

FieldUnitBillboard.willUnmount = function(self)
    if (self.unitRemoving) then
        self.unitRemoving:Disconnect()
        self.unitRemoving = nil
    end

    if (self.hpChanged) then
        self.hpChanged:Disconnect()
        self.hpChanged = nil
    end
end

FieldUnitBillboard.render = function(self)
    return Roact.createElement("BillboardGui", {
        Adornee = self.props.Adornee,
        Size = self.props.Size,
        StudsOffsetWorldSpace = self.props.StudsOffsetWorldSpace,
        LightInfluence = 0,
        ResetOnSpawn = false,
        ClipsDescendants = true,
    }, {
        UnitNameLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0, 0),
            Size = UDim2.new(0.75, 0, 0.25, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Text = self.state.name,
            Font = Style.Constants.MainFont,
            TextStrokeTransparency = 0.5,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,

            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1),
        }),

        UnitLevelLabel = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0.25, 0, 0.25, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,

            Text = self.state.level,
            Font = Style.Constants.MainFont,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,

            BackgroundColor3 = Color3.new(1, 1, 1),
            TextColor3 = Color3.new(0, 0, 0),
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(Style.Constants.StandardCornerRadius / 50, 0)
            })
        }),

        HPBar = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0.5, 0),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = Color3.new(1, 1, 1),
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(Style.Constants.StandardCornerRadius / 50, 0)
            }),

            HPReadout = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0.75, 0, 0.5, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = string.format("%0.3f/%0.3f", self.state.hp, self.state.maxHP),
                Font = Style.Constants.MainFont,
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(0, 0, 0),
            })
        })
    })
end

return FieldUnitBillboard