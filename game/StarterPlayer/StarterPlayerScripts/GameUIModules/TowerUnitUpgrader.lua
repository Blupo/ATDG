local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

local TARGETING_CYCLE = {
    GameEnum.UnitTargeting.First,
    GameEnum.UnitTargeting.Last,
    GameEnum.UnitTargeting.Closest,
    GameEnum.UnitTargeting.Farthest,
    GameEnum.UnitTargeting.Strongest,
    GameEnum.UnitTargeting.Fastest,
    GameEnum.UnitTargeting.Random
}

local ATTRIBUTE_PREVIEW = { "DMG", "RANGE", "CD" }

---

--[[
    props

    unitId: string
]]

---

local TowerUnitUpgradeBillboard = Roact.PureComponent:extend("TowerUnitUpgradeBillboard")

TowerUnitUpgradeBillboard.init = function(self)
    self:setState({
        name = "",
        level = 1,
        target = "First",
        
        attributeChanges = {},
    })
end

TowerUnitUpgradeBillboard.didMount = function(self)
    local unitId = self.props.unitId
    local unit = Unit.fromId(unitId)
    local unitName = unit.Name
    local unitLevel = unit.Level

    local upgradePrice = Shop.GetUnitUpgradePrice(unitName, unitLevel)
    local sellingPrice = Shop.GetUnitSellingPrice(unitName, unitLevel)

    local thisLevelBaseAttributes = Unit.GetUnitBaseAttributes(unitName, unitLevel)
    local nextLevelBaseAttributes = Unit.GetUnitBaseAttributes(unitName, unitLevel + 1)

    local attributeChanges = {}

    for i = 1, #ATTRIBUTE_PREVIEW do
        local attribute = ATTRIBUTE_PREVIEW[i]
        local thisLevelAttributeValue = thisLevelBaseAttributes[attribute]
        local nextLevelAttributeValue = nextLevelBaseAttributes[attribute]

        if (thisLevelAttributeValue ~= nextLevelAttributeValue) then
            attributeChanges[attribute] = {thisLevelAttributeValue, nextLevelAttributeValue}
        end
    end

    self.unitUpgraded = unit.Upgraded:Connect(function(newLevel)
        local newLevelBaseAttributes = Unit.GetUnitBaseAttributes(unitName, newLevel)
        local newNextLevelBaseAttributes = Unit.GetUnitBaseAttributes(unitName, newLevel + 1)
        local newUpgradePrice = Shop.GetUnitUpgradePrice(unitName, newLevel)
        local newSellingPrice = Shop.GetUnitSellingPrice(unitName, newLevel)
        local newAttributeChanges = {}

        for i = 1, #ATTRIBUTE_PREVIEW do
            local attribute = ATTRIBUTE_PREVIEW[i]
            local newLevelAttributeValue = newLevelBaseAttributes[attribute]
            local newNextLevelAttributeValue = newNextLevelBaseAttributes[attribute]

            if (newNextLevelAttributeValue ~= newLevelAttributeValue) then
                newAttributeChanges[attribute] = {newLevelAttributeValue, newNextLevelAttributeValue}
            end
        end

        self:setState({
            level = newLevel,

            upgradePrice = newUpgradePrice or Roact.None,
            sellingPrice = newSellingPrice,
            attributeChanges = newAttributeChanges,
        })
    end)

    self.targetChanged = unit.AttributeChanged:Connect(function(attribute, newValue)
        if (attribute ~= "UnitTargeting") then return end

        self:setState({
            target = newValue
        })
    end)

    self:setState({
        name = unit.DisplayName,
        level = unitLevel,
        target = unit:GetAttribute("UnitTargeting"),

        upgradePrice = upgradePrice,
        sellingPrice = sellingPrice,
        attributeChanges = attributeChanges,
    })
end

TowerUnitUpgradeBillboard.willUnmount = function(self)
    self.unitUpgraded:Disconnect()
    self.targetChanged:Disconnect()
end

TowerUnitUpgradeBillboard.render = function(self)
    local unitId = self.props.unitId
    local unit = Unit.fromId(unitId)
    if (not unit) then return end

    local target = self.state.target
    local upgradePrice = self.state.upgradePrice
    local sellingPrice = self.state.sellingPrice

    local changesListChildren = {}

    for attribute, values in pairs(self.state.attributeChanges) do
        changesListChildren[attribute] = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            LayoutOrder = table.find(ATTRIBUTE_PREVIEW, attribute),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            AttributeIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = Style.Images[attribute .. "AttributeIcon"],
                ImageColor3 = Style.Colors[attribute .. "AttributeIconColor"],
            }),

            TransitionIcon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0.625, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = "rbxassetid://2089572676",
                ImageColor3 = Color3.new(0, 0, 0),
            }),

            OriginalValueLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0.35, 0, 1, 0),
                Position = UDim2.new(0.15, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = values[1],
                Font = Style.Constants.MainFont,
                TextSize = 16,

                TextColor3 = Color3.new(0, 0, 0)
            }),

            NewValueLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.35, 0, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = values[2] or "",
                Font = Style.Constants.MainFont,
                TextSize = 16,

                TextColor3 = Color3.new(0, 0, 0)
            })
        })
    end

    changesListChildren.UIListLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, 0),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    return Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
    }, {
        Container = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 240, 0, 200),
            Position = UDim2.new(0, 16, 0.5, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = Color3.new(1, 1, 1),
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
            }),

            UIPadding = Roact.createElement("UIPadding", {
                PaddingTop = UDim.new(0, Style.Constants.MajorElementPadding),
                PaddingBottom = UDim.new(0, Style.Constants.MajorElementPadding),
                PaddingLeft = UDim.new(0, Style.Constants.MajorElementPadding),
                PaddingRight = UDim.new(0, Style.Constants.MajorElementPadding),
            }),

            UnitNameLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, -28, 0, 20),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = self.state.name,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(0, 0, 0),
            }),

            UnitLevelLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                SizeConstraint = Enum.SizeConstraint.RelativeYY,

                Text = self.state.level,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                BackgroundColor3 = Color3.fromRGB(230, 230, 230),
                TextColor3 = Color3.new(0, 0, 0),
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                }),
            }),

            ChangesList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 1, -92),
                Position = UDim2.new(0.5, 0, 0, 28),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, changesListChildren),

            TargetingToggle = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Size = UDim2.new(0.5, -4, 0, 56),
                Position = UDim2.new(0, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                TargetingLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, 16),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = "Target",
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0),
                }),

                ToggleButton = Roact.createElement("TextButton", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    Text = target,
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    BackgroundColor3 = Color3.fromRGB(230, 230, 230),
                    TextColor3 = Color3.new(0, 0, 0),

                    [Roact.Event.Activated] = function()
                        local index = table.find(TARGETING_CYCLE, target)
                        if (not index) then return end

                        local newIndex = index + 1
                        newIndex = (newIndex <= #TARGETING_CYCLE) and newIndex or 1

                        unit:SetAttribute("UnitTargeting", TARGETING_CYCLE[newIndex])
                    end
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                    }),
                })
            }),

            UpgradeButton = Roact.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 1),
                Size = UDim2.new(0.5, -4, 0, 32),
                Position = UDim2.new(1, 0, 1, -40),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                Text = "",
                TextTransparency = 1,

                BackgroundColor3 = Color3.fromRGB(230, 230, 230),

                [Roact.Event.Activated] = function()
                    if (not upgradePrice) then return end

                    Shop.PurchaseUnitUpgrade(unitId)
                end,
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                }),

                Icon = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,

                    Image = Style.Images.UpgradeUnitIcon,
                    ImageColor3 = Color3.new(0, 0, 0),
                }),

                UpgradePriceLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(0.75, 0, 0.75, 0),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = upgradePrice or "MAX",
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            }),

            SellButton = Roact.createElement("TextButton", {
                AnchorPoint = Vector2.new(1, 1),
                Size = UDim2.new(0.5, -4, 0, 32),
                Position = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                Text = "",
                TextTransparency = 1,

                BackgroundColor3 = Color3.fromRGB(230, 230, 230),

                [Roact.Event.Activated] = function()
                    if (not sellingPrice) then return end

                    Shop.SellUnit(unitId)
                end,
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                }),

                Icon = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(0, 6, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Image = Style.Images.SellUnitIcon,
                    ImageColor3 = Color3.new(0, 0, 0),
                }),

                SellingPriceLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(0.75, 0, 0.75, 0),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = sellingPrice or "?",
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            })
        })
    })
end

return TowerUnitUpgradeBillboard