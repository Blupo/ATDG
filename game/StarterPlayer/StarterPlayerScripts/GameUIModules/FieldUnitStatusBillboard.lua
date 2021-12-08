local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local StatusEffectColors = require(PlayerModules:WaitForChild("StatusEffectColors"))

local StatusEffects = SystemCoordinator.waitForSystem("StatusEffects")

local StandardTextLabel = StandardComponents.TextLabel

---

local defColorString = string.format("%d,%d,%d",
    Style.Colors.DEFAttributeIconColor.R * 255,
    Style.Colors.DEFAttributeIconColor.G * 255,
    Style.Colors.DEFAttributeIconColor.B * 255
)

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
        def = 0,

        statusEffects = {},
    })
end

FieldUnitBillboard.didMount = function(self)
    local thisUnitId = self.props.unitId
    local thisUnit = Unit.fromId(self.props.unitId)
    if (not thisUnit) then return end

    self.attributeChanged = thisUnit.AttributeChanged:Connect(function(attributeName, newValue)
        if (attributeName == "HP") then
            self:setState({
                hp = newValue
            })
        elseif (attributeName == "DEF") then
            self:setState({
                def = newValue
            })
        end
    end)

    self.effectApplied = StatusEffects.EffectApplied:Connect(function(unitId: string, effectName: string)
        if (unitId ~= thisUnitId) then return end

        local newStatusEffects = {
            [effectName] = true,
        }

        for effect in pairs(self.state.statusEffects) do
            newStatusEffects[effect] = true
        end

        self:setState({
           statusEffects = newStatusEffects 
        })
    end)

    self.effectRemoved = StatusEffects.EffectRemoved:Connect(function(unitId: string, effectName: string)
        if (unitId ~= thisUnitId) then return end

        local newStatusEffects = {}

        for effect in pairs(self.state.statusEffects) do
            if (effect ~= effectName) then
                newStatusEffects[effect] = true
            end
        end

        self:setState({
           statusEffects = newStatusEffects 
        })
    end)

    local statusEffectsArray = StatusEffects.GetUnitEffects(thisUnitId)
    local statusEffectsDictionary = {}

    for i = 1, #statusEffectsArray do
        statusEffectsDictionary[statusEffectsArray[i]] = true
    end

    self:setState({
        name = thisUnit.DisplayName,
        level = thisUnit.Level,

        hp = thisUnit:GetAttribute("HP"),
        maxHP = thisUnit:GetAttribute("MaxHP"),
        def = thisUnit:GetAttribute("DEF"),

        statusEffects = statusEffectsDictionary,
    })
end

FieldUnitBillboard.willUnmount = function(self)
    self.attributeChanged:Disconnect()
    self.effectApplied:Disconnect()
    self.effectRemoved:Disconnect()
end

FieldUnitBillboard.render = function(self)
    local hp, maxHP = self.state.hp, self.state.maxHP
    local def = self.state.def
    local statusEffects = self.state.statusEffects

    local statusEffectsAlphabetSort = {}
    local statusEffectChildren = {}
    
    for effectName in pairs(statusEffects) do
        table.insert(statusEffectsAlphabetSort, effectName)
    end

    table.sort(statusEffectsAlphabetSort, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    for effectName in pairs(statusEffects) do
        statusEffectChildren[effectName] = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = table.find(statusEffectsAlphabetSort, effectName) or 0,
            
            BackgroundColor3 = StatusEffectColors[effectName] or Color3.new(0, 0, 0),
        })
    end

    statusEffectChildren.UIListLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0.05, 0),

        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    return Roact.createElement("BillboardGui", {
        Adornee = self.props.Adornee,
        Size = self.props.Size,
        StudsOffsetWorldSpace = self.props.StudsOffsetWorldSpace,
        LightInfluence = 0,
        ResetOnSpawn = false,
        ClipsDescendants = true,
    }, {
        UnitNameLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0),
            Size = UDim2.new(0.75, 0, 0.25, 0),
            Position = UDim2.new(0, 0, 0, 0),

            Text = self.state.name,
            TextStrokeTransparency = 0.5,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),

        UnitLevelLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0.25, 0, 0.25, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            SizeConstraint = Enum.SizeConstraint.RelativeYY,

            Text = self.state.level,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(Style.Constants.StandardCornerRadius / 50, 0)
            })
        }),

        StatusEffectsContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0.2, 0),
            Position = UDim2.new(0.5, 0, 0.55, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, statusEffectChildren),

        HPContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0.4, 0),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = Color3.new(1, 1, 1),
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(Style.Constants.StandardCornerRadius / 50, 0)
            }),

            HPBar = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new((hp / maxHP) * 0.925, 0, 0.05, 0),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.new(0, 0, 0),
            }),

            HPReadout = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0.75, 0, 0.5, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),

                Text = string.format(
                    "%d/%d/<font color=\"rgb(" .. defColorString .. ")\">%d</font>",
                    math.ceil(hp),
                    math.ceil(maxHP),
                    def
                ),

                TextScaled = true,
                RichText = true,
                TextXAlignment = Enum.TextXAlignment.Center,
            })
        })
    })
end

return FieldUnitBillboard