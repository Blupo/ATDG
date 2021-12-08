local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Button = require(GameUIModules:WaitForChild("Button"))
local MainElementContainer = require(GameUIModules:WaitForChild("MainElementContainer"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local FormatAttribute = require(PlayerModules:WaitForChild("FormatAttribute"))
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIListLayout = StandardComponents.UIListLayout

PreviewAttributes = PreviewAttributes[GameEnum.UnitType.TowerUnit]

---

local TARGETING_OPTIONS = {
    GameEnum.UnitTargeting.First,
    GameEnum.UnitTargeting.Last,
    GameEnum.UnitTargeting.Closest,
    GameEnum.UnitTargeting.Farthest,
    GameEnum.UnitTargeting.Strongest,
    GameEnum.UnitTargeting.Fastest,
    GameEnum.UnitTargeting.Random
}

---

--[[
    props

        unitId: string
        onClose: ()
]]

local TowerUnitUpgrader = Roact.PureComponent:extend("TowerUnitUpgrader")

TowerUnitUpgrader.init = function(self)
    self.statListLength, self.updateStatListLength = Roact.createBinding(0)
end

TowerUnitUpgrader.didMount = function(self)
    local unitId = self.props.unitId
    local unit = Unit.fromId(unitId)

    self.unitUpgraded = unit.Upgraded:Connect(function(newLevel)
        self:setState({
            unitLevel = newLevel,
        })
    end)

    self.targetChanged = unit.AttributeChanged:Connect(function(attribute, newValue)
        if (attribute ~= "UnitTargeting") then return end

        self:setState({
            unitTargeting = newValue
        })
    end)

    self:setState({
        unitName = unit.Name,
        unitLevel = unit.Level,
        unitTargeting = unit:GetAttribute("UnitTargeting"),
    })
end

TowerUnitUpgrader.didUpdate = function(self, prevProps)
    if (self.props.unitId == prevProps.unitId) then return end

    local unitId = self.props.unitId
    local unit = Unit.fromId(unitId)

    self.unitUpgraded:Disconnect()
    self.targetChanged:Disconnect()

    self.unitUpgraded = unit.Upgraded:Connect(function(newLevel)
        self:setState({
            unitLevel = newLevel,
        })
    end)

    self.targetChanged = unit.AttributeChanged:Connect(function(attribute, newValue)
        if (attribute ~= "UnitTargeting") then return end

        self:setState({
            unitTargeting = newValue
        })
    end)

    self:setState({
        unitName = unit.Name,
        unitLevel = unit.Level,
        unitTargeting = unit:GetAttribute("UnitTargeting"),
    })
end

TowerUnitUpgrader.willUnmount = function(self)
    self.unitUpgraded:Disconnect()
    self.targetChanged:Disconnect()
end

TowerUnitUpgrader.render = function(self)
    local unitId = self.props.unitId
    if (not self.state.unitName) then return end

    local unitName = self.state.unitName
    local unitLevel = self.state.unitLevel

    local unitTargeting = self.state.unitTargeting
    local doNotShowTargetSwitcher = (unitTargeting == GameEnum.UnitTargeting.AreaOfEffect) or (unitTargeting == GameEnum.UnitTargeting.None)

    local unitMaxLevel = Unit.GetUnitMaxLevel(unitName)
    local unitIsMaxLevel = (unitLevel == unitMaxLevel)

    local unitSellingPrice = Shop.GetUnitSellingPrice(unitName, unitLevel)
    local unitUpgradePrice

    local unitUpgradePriceTextSize
    local unitSellingPriceTextSize = TextService:GetTextSize(
        unitSellingPrice,
        Style.Constants.StandardTextSize,
        Style.Constants.PrimaryFont,
        Vector2.new(math.huge, Style.Constants.StandardTextSize)
    )

    local unitBaseAttributes = Unit.GetUnitBaseAttributes(unitName, unitLevel)
    local unitBaseAbilities = Unit.GetUnitBaseAbilities(unitName, unitLevel)
    local unitNextLevelBaseAttributes
    local unitNextLevelBaseAbilities

    local sortedAbilitiesList = {}
    local statListElements = {}
    local switcherElements = {}

    if (not unitIsMaxLevel) then
        unitNextLevelBaseAttributes = Unit.GetUnitBaseAttributes(unitName, unitLevel + 1)
        unitNextLevelBaseAbilities = Unit.GetUnitBaseAbilities(unitName, unitLevel + 1)

        unitUpgradePrice = Shop.GetUnitUpgradePrice(unitName, unitLevel)

        unitUpgradePriceTextSize = TextService:GetTextSize(
            unitUpgradePrice,
            Style.Constants.StandardTextSize,
            Style.Constants.PrimaryFont,
            Vector2.new(math.huge, Style.Constants.StandardTextSize)
        )

        --[[
            ability order

            abilities that will persist to the next level
            abilities that will be removed at the next level
            abilities that will be added at the next level
        ]]

        for ability in pairs(unitBaseAbilities) do
            if unitNextLevelBaseAbilities[ability] then
                table.insert(sortedAbilitiesList, ability)
            end
        end

        for ability in pairs(unitBaseAbilities) do
            if (not unitNextLevelBaseAbilities[ability]) then
                table.insert(sortedAbilitiesList, ability)
            end
        end
        
        for ability in pairs(unitNextLevelBaseAbilities) do
            if (not unitBaseAbilities[ability]) then
                table.insert(sortedAbilitiesList, ability)
            end
        end
    else
        for ability in pairs(unitBaseAbilities) do
            table.insert(sortedAbilitiesList, ability)
        end
    end

    if (not doNotShowTargetSwitcher) then
        local disabled = (unitTargeting == GameEnum.UnitTargeting.None)

        for i = 1, #TARGETING_OPTIONS do
            local targeting = TARGETING_OPTIONS[i]
            local imageColor

            if (disabled) then
                imageColor = Color3.fromRGB(200, 200, 200)
            else
                imageColor = (targeting == unitTargeting) and Style.Colors.SelectionColor or Color3.new(0, 0, 0)
            end

            switcherElements[targeting] = Roact.createElement(Button, {
                Size = UDim2.new(0, Style.Constants.StandardButtonHeight, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = i,

                Image = Style.Images[targeting .. "TargetingIcon"],
                
                Color = Style.Colors.FlatGradient,
                BackgroundColor3 = Color3.new(1, 1, 1),
                ImageColor3 = imageColor,

                disabled = disabled,
                displayType = "Image",

                onActivated = function()
                    Unit.fromId(unitId):SetAttribute("UnitTargeting", targeting)
                end,
            })
        end
    end

    for i = 1, (#PreviewAttributes - 1) do
        local attribute = PreviewAttributes[i]
        local attributeValue = FormatAttribute(attribute, unitBaseAttributes[attribute])
        local nextLevelAttributeValue = (not unitIsMaxLevel) and FormatAttribute(attribute, unitNextLevelBaseAttributes[attribute]) or nil
        local showComparison = (nextLevelAttributeValue and (attributeValue ~= nextLevelAttributeValue))

        statListElements[attribute .. "Stat"] = Roact.createElement("Frame", {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardIconSize),
            LayoutOrder = i,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
        }, {
            StatIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                Position = UDim2.new(0, 0, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,

                Image = Style.Images[attribute .. "AttributeIcon"],
                ImageColor3 = Style.Colors[attribute .. "AttributeIconColor"],
            }),

            Comparison = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
            }, {
                AttributeValueLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.5, -((Style.Constants.StandardIconSize / 2) + Style.Constants.MinorElementPadding), 0, Style.Constants.StandardTextSize),
                    Position = UDim2.new(0, 0, 0.5, 0),

                    Text = attributeValue,
                    TextScaled = true,
                }),

                ComparisonIcon = (showComparison) and
                    Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,

                        Image = Style.Images.StatComparisonIcon,
                        ImageColor3 = Color3.new(0, 0, 0),
                    })
                or nil,

                NextLevelAttributeValueLabel = (showComparison) and
                    Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(0.5, -((Style.Constants.StandardIconSize / 2) + Style.Constants.MinorElementPadding), 0, Style.Constants.StandardTextSize),
                        Position = UDim2.new(1, 0, 0.5, 0),

                        Text = nextLevelAttributeValue,
                        TextScaled = true,
                    })
                or nil,
            }),
        })
    end

    for i = 1, #sortedAbilitiesList do
        local ability = sortedAbilitiesList[i]
        local abilityState

        if (not unitNextLevelBaseAbilities) then
            abilityState = "Persist"
        else
            if (unitBaseAbilities[ability] and unitNextLevelBaseAbilities[ability]) then
                abilityState = "Persist"
            elseif (unitBaseAbilities[ability] and (not unitNextLevelBaseAbilities[ability])) then
                abilityState = "Remove"
            elseif ((not unitBaseAbilities[ability]) and unitNextLevelBaseAbilities[ability]) then
                abilityState = "Add"
            end
        end

        statListElements[ability .. "Ability"] = Roact.createElement("Frame", {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardIconSize),
            LayoutOrder = i + (#PreviewAttributes - 1),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
        }, {
            StatIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                Position = UDim2.new(0, 0, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,

                Image = Style.Images.UnitAbilityIcon,
                ImageColor3 = Color3.new(0, 0, 0),
            }),

            Info = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding), 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
            }, {
                AbilityName = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),

                    Size = UDim2.new(
                        1, (abilityState ~= "Persist") and -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding) or 0,
                        0, Style.Constants.StandardTextSize
                    ),

                    Text = ability,
                    TextScaled = true,
                }),

                StateIcon = (abilityState ~= "Persist") and
                    Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,

                        Image = Style.Images[(abilityState == "Add") and "AddIcon" or "RemoveIcon"],
                        ImageColor3 = Color3.new(0, 0, 0),
                    })
                or nil,
            })
        })
    end

    statListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        HorizontalAlignment = Enum.HorizontalAlignment.Left,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateStatListLength(obj.AbsoluteContentSize.Y)
        end
    })

    switcherElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        FillDirection = Enum.FillDirection.Horizontal,
    })

    return Roact.createElement(MainElementContainer, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, Style.Constants.ProminentBorderWidth + Style.Constants.MajorElementPadding, 0.5, 0),
        ScaleX = 0.3,
        ScaleY = 0.3,
        AspectRatio = 1,

        StrokeGradient = Style.Colors.RedProminentGradient,
    }, {
        CloseButton = Roact.createElement("ImageButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, Style.Constants.LargeButtonHeight, 0, Style.Constants.LargeButtonHeight),
            Position = UDim2.new(1, Style.Constants.MajorElementPadding, 0, -Style.Constants.MajorElementPadding),
            BorderSizePixel = 0,
            BackgroundTransparency = 0,

            Image = Style.Images.CloseIcon,

            BackgroundColor3 = Style.Colors.RedProminentGradient.Keypoints[1].Value,
            ImageColor3 = Color3.new(0, 0, 0),

            [Roact.Event.Activated] = self.props.onClose,
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(1, 0),
            })
        }),

        SelectedUnitLabel = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),
            Position = UDim2.new(0, 0, 0, 0),

            Text = Unit.GetUnitDisplayName(unitName) .. " (" .. unitLevel .. ")",
            TextSize = Style.Constants.SecondaryHeaderTextSize,
            TextScaled = true,
            TextYAlignment = Enum.TextYAlignment.Top,
        }),

        StatComparison = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, Style.Constants.SecondaryHeaderTextSize + Style.Constants.SpaciousElementPadding),

            Size = UDim2.new(1, 0, 1, -(
                Style.Constants.SecondaryHeaderTextSize +
                Style.Constants.LargeButtonHeight +
                (Style.Constants.SpaciousElementPadding * (doNotShowTargetSwitcher and 2 or 3)) +
                ((not doNotShowTargetSwitcher) and Style.Constants.StandardButtonHeight or 0)
            )),

            CanvasSize = self.statListLength:map(function(length)
                return UDim2.new(0, 0, 0, length)
            end)
        }, statListElements),

        TargetingSwitcher = (not doNotShowTargetSwitcher) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight),
                Position = UDim2.new(0.5, 0, 1, -(Style.Constants.LargeButtonHeight + Style.Constants.SpaciousElementPadding)),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
            }, switcherElements)
        or nil,

        SellButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.LargeButtonHeight),
            Position = UDim2.new(0, 0, 1, 0),

            displayType = "Children",

            onActivated = function()
                Shop.SellUnit(unitId)
            end,
        }, {
            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                Position = UDim2.new(0, Style.Constants.MinorElementPadding, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = Style.Images.SellUnitIcon,
                ImageColor3 = Color3.new(0, 0, 0)
            }),

            PriceContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(Style.Constants.StandardIconSize + (Style.Constants.MinorElementPadding * 3)), 1, 0),
                Position = UDim2.new(1, -Style.Constants.MinorElementPadding, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.Constants.MinorElementPadding),

                    FillDirection = Enum.FillDirection.Horizontal,
                }),

                PriceLabel = Roact.createElement(StandardTextLabel, {
                    Size = UDim2.new(0, unitSellingPriceTextSize.X, 1, 0),
                    LayoutOrder = 1,

                    Text = unitSellingPrice,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                }),

                CurerncyIcon = Roact.createElement("ImageLabel", {
                    Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,

                    Image = Style.Images.PointsCurrencyIcon,
                    ImageColor3 = Color3.new(0, 0, 0)
                })
            }),
        }),

        UpgradeButton = Roact.createElement(Button, {
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.LargeButtonHeight),
            Position = UDim2.new(1, 0, 1, 0),

            disabled = unitIsMaxLevel,
            displayType = "Children",

            onActivated = function()
                Shop.PurchaseUnitUpgrade(unitId)
            end,
        }, {
            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                Position = UDim2.new(0, Style.Constants.MinorElementPadding, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 0,

                Image = Style.Images.UpgradeUnitIcon,
                ImageColor3 = Color3.new(0, 0, 0)
            }),

            PriceContainer = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -(Style.Constants.StandardIconSize + (Style.Constants.MinorElementPadding * 3)), 1, 0),
                Position = UDim2.new(1, -Style.Constants.MinorElementPadding, 0.5, 0),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
            }, {
                UIListLayout = Roact.createElement(StandardUIListLayout, {
                    Padding = UDim.new(0, Style.Constants.MinorElementPadding),

                    FillDirection = Enum.FillDirection.Horizontal,
                }),

                PriceLabel = Roact.createElement(StandardTextLabel, {
                    LayoutOrder = 1,

                    Size = UDim2.new(
                        unitIsMaxLevel and UDim.new(1, 0) or UDim.new(0, unitUpgradePriceTextSize.X),
                        UDim.new(1, 0)
                    ),

                    Text = unitIsMaxLevel and "MAX" or unitUpgradePrice,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                }),

                CurrencyIcon = (not unitIsMaxLevel) and
                    Roact.createElement("ImageLabel", {
                        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 2,

                        Image = Style.Images.PointsCurrencyIcon,
                        ImageColor3 = Color3.new(0, 0, 0)
                    })
                or nil,
            }),
        }),
    })
end

return TowerUnitUpgrader