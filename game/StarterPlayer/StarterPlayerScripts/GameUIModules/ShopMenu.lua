local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Padding = require(GameUIModules:WaitForChild("Padding"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))
local UnitViewport = require(GameUIModules:WaitForChild("UnitViewport"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))

local SharedGameData = require(SharedModules:WaitForChild("SharedGameData"))
local GameConstants = SharedGameData.GameConstants

---

local UnitShopPage = Roact.PureComponent:extend("UnitShopPage")
local SpecialShopPage = Roact.PureComponent:extend("SpecialShopPage")

---

local maxHotbarItems = GameConstants.MaxHotbarItems
local unitPrices = ShopPrices.ObjectGrantPrices[GameEnum.ObjectType.Unit]
local actionPrices = ShopPrices.ItemPrices[GameEnum.ItemType.SpecialAction]
local actionPricesSorted = {}

local unitPricesSorted = {
    [GameEnum.UnitType.TowerUnit] = {},
    [GameEnum.UnitType.FieldUnit] = {},
}

local shopCategories = {
    {
        name = "Units",
        element = UnitShopPage,
    },

    {
        name = "Special",
        element = SpecialShopPage,
    }
}

---

for unitName, price in pairs(unitPrices) do
    local unitType = Unit.GetUnitType(unitName)

    table.insert(unitPricesSorted[unitType], {
        unitName = unitName,
        price = price,
    })
end

for actionName, price in pairs(actionPrices) do
    table.insert(actionPricesSorted, {
        actionName = actionName,
        price = price
    })
end

table.sort(unitPricesSorted[GameEnum.UnitType.TowerUnit], function(a, b)
    return a.price < b.price
end)

table.sort(unitPricesSorted[GameEnum.UnitType.FieldUnit], function(a, b)
    return a.price < b.price
end)

table.sort(actionPricesSorted, function(a, b)
    return a.price < b.price
end)


---

UnitShopPage.init = function(self)
    self.unitListLength, self.updateUnitListLength = Roact.createBinding(0)
    self.towerUnitListLength, self.updateTowerUnitListLength = Roact.createBinding(0)
    self.fieldUnitListLength, self.updateFieldUnitListLength = Roact.createBinding(0)
end

UnitShopPage.didMount = function(self)
    self.objectGrantedConnection = PlayerData.ObjectGranted:Connect(function(_, objectType: string, objectName: string)
        if (objectType ~= GameEnum.ObjectType.Unit) then return end
        if (self.state.selectedUnit ~= objectName) then return end
        
        self:setState({
            playerOwnsSelectedUnit = true,
        })
    end)

    self.playerHotbarChanged = PlayerData.HotbarChanged:Connect(function(_, objectType: string, newHotbar: {[number]: string})
        local selectedUnit = self.state.selectedUnit
        if (not selectedUnit) then return end

        local selectedUnitType = Unit.GetUnitType(selectedUnit)
        if (selectedUnitType ~= objectType) then return end

        self:setState({
            selectedUnitHotbarIndex = table.find(newHotbar, selectedUnit) or Roact.None,
        })
    end)
end

UnitShopPage.willUnmount = function(self)
    self.objectGrantedConnection:Disconnect()
    self.playerHotbarChanged:Disconnect()
end

UnitShopPage.render = function(self)
    local selectedUnit = self.state.selectedUnit
    local selectedUnitLevel = self.state.selectedUnitLevel
    local playerOwnsSelectedUnit = self.state.playerOwnsSelectedUnit
    local selectedUnitHotbarIndex = self.state.selectedUnitHotbarIndex

    local selectedUnitPreviewAttributes = selectedUnit and PreviewAttributes[Unit.GetUnitType(selectedUnit)] or nil
    local selectedUnitBaseAttributes = selectedUnit and Unit.GetUnitBaseAttributes(selectedUnit, selectedUnitLevel) or nil
    local selectedUnitMaxLevel = selectedUnit and Unit.GetUnitMaxLevel(selectedUnit) or nil
    local selectedUnitGrantPrice = selectedUnit and Shop.GetObjectGrantPrice(GameEnum.ObjectType.Unit, selectedUnit) or nil
    local selectedUnitUpgradePriceText

    if (selectedUnitGrantPrice) then
        selectedUnitGrantPrice = (selectedUnitGrantPrice ~= math.huge) and selectedUnitGrantPrice or "∞"
    end

    if (selectedUnit) then
        if (selectedUnitLevel == 1) then
            selectedUnitUpgradePriceText = Shop.GetObjectPlacementPrice(GameEnum.ObjectType.Unit, selectedUnit) or "?"
        elseif (selectedUnitLevel == selectedUnitMaxLevel) then
            selectedUnitUpgradePriceText = "N/A"
        else
            selectedUnitUpgradePriceText = Shop.GetUnitUpgradePrice(selectedUnit, selectedUnitLevel) or "?"
        end
    end

    local grantPriceTextSize = selectedUnit and TextService:GetTextSize(selectedUnitGrantPrice or "?", 16, Style.Constants.MainFont, Vector2.new(math.huge, math.huge)) or nil

    local towerUnitPrices = unitPricesSorted[GameEnum.UnitType.TowerUnit]
    local fieldUnitPrices = unitPricesSorted[GameEnum.UnitType.FieldUnit]

    local towerUnitListElements = {}
    local fieldUnitListElements = {}
    local statListElements = {}

    for i = 1, #towerUnitPrices do
        local priceInfo = towerUnitPrices[i]
        local unitName = priceInfo.unitName

        towerUnitListElements[unitName] = Roact.createElement(UnitViewport, {
            LayoutOrder = i,

            unitName = unitName,
            titleDisplayType = "UnitName",
            rightInfoDisplayType = "Unlocked",
            
            onActivated = function()
                local unitType = Unit.GetUnitType(unitName)
                local playerHotbar = PlayerData.GetPlayerHotbar(LocalPlayer.UserId, unitType)

                self:setState({
                    selectedUnit = unitName,
                    selectedUnitLevel = 1,
                    playerOwnsSelectedUnit = PlayerData.PlayerHasObjectGrant(LocalPlayer.UserId, GameEnum.ObjectType.Unit, unitName),
                    selectedUnitHotbarIndex = playerHotbar and table.find(playerHotbar, unitName) or Roact.None,
                })
            end,
        })
    end

    for i = 1, #fieldUnitPrices do
        local priceInfo = fieldUnitPrices[i]
        local unitName = priceInfo.unitName

        fieldUnitListElements[unitName] = Roact.createElement(UnitViewport, {
            LayoutOrder = i,

            unitName = unitName,
            titleDisplayType = "UnitName",
            rightInfoDisplayType = "Unlocked",
            
            onActivated = function()
                local unitType = Unit.GetUnitType(unitName)
                local playerHotbar = PlayerData.GetPlayerHotbar(LocalPlayer.UserId, unitType)

                self:setState({
                    selectedUnit = unitName,
                    selectedUnitLevel = 1,
                    playerOwnsSelectedUnit = PlayerData.PlayerHasObjectGrant(LocalPlayer.UserId, GameEnum.ObjectType.Unit, unitName),
                    selectedUnitHotbarIndex = playerHotbar and table.find(playerHotbar, unitName) or Roact.None,
                })
            end,
        })
    end

    if (selectedUnit) then
        for i = 1, #selectedUnitPreviewAttributes do
            local attribute = selectedUnitPreviewAttributes[i]
            local attributeValue = selectedUnitBaseAttributes[attribute]

            if (tonumber(attributeValue) and (attribute ~= "MaxHP")) then
                if (attributeValue ~= math.huge) then
                    attributeValue = string.format("%0.2f", attributeValue)
                else
                    attributeValue = "∞"
                end

                if ((attribute == "RANGE") and (selectedUnitBaseAttributes.UnitTargeting == GameEnum.UnitTargeting.AreaOfEffect)) then
                    attributeValue = attributeValue .. " (AoE)"
                end
            elseif (attribute == "PathType") then
                if (attributeValue == GameEnum.PathType.GroundAndAir) then
                    attributeValue = "GA"
                end
            end

            statListElements[attribute] = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = i
            }, {
                AttributeIcon = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Image = Style.Images[attribute .. "AttributeIcon"],
                    ImageColor3 = Style.Colors[attribute .. "AttributeIconColor"]
                }),

                AttributeValueLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(1, -32, 1, 0),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = attributeValue,
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                })
            })
        end

        statListElements.UpgradePrice = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = #selectedUnitPreviewAttributes + 1,
        }, {
            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = (selectedUnitLevel == 1) and "rbxassetid://3482240803" or "rbxassetid://6837004663",
                ImageColor3 = Color3.new(0, 0, 0)
            }),

            ValueLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = selectedUnitUpgradePriceText,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(0, 0, 0)
            })
        })

        statListElements.SellingPrice = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = #selectedUnitPreviewAttributes + 2,
        }, {
            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = "rbxassetid://7198417722",
                ImageColor3 = Color3.new(0, 0, 0)
            }),

            ValueLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = Shop.GetUnitSellingPrice(selectedUnit, selectedUnitLevel),
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(0, 0, 0)
            })
        })

        statListElements.UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.Constants.MinorElementPadding),
    
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })
    end

    towerUnitListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
        CellSize = UDim2.new(0, Style.Constants.UnitViewportFrameSize, 0, Style.Constants.UnitViewportFrameSize),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateTowerUnitListLength(obj.AbsoluteContentSize.Y)
        end
    })

    fieldUnitListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
        CellSize = UDim2.new(0, Style.Constants.UnitViewportFrameSize, 0, Style.Constants.UnitViewportFrameSize),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateFieldUnitListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createFragment({
        UnitList = Roact.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(selectedUnit and UDim.new(0.75, -16) or UDim.new(1, 0), UDim.new(1, 0)),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            CanvasSize = self.unitListLength:map(function(listLength)
                return UDim2.new(0, 0, 0, listLength)
            end),

            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            ScrollBarThickness = 6,

            ScrollBarImageColor3 = Color3.new(0, 0, 0)
        }, {
            TowerUnitHeader = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 0,

                Text = "Tower Units",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,

                TextColor3 = Color3.new(0, 0, 0)
            }),

            TowerUnitList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 1,
        
                Size = self.towerUnitListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, towerUnitListElements),

            FieldUnitHeader = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 2,

                Text = "Field Units",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,

                TextColor3 = Color3.new(0, 0, 0)
            }),

            FieldUnitList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 3,
        
                Size = self.fieldUnitListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, fieldUnitListElements),

            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, Style.Constants.MajorElementPadding),
        
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
        
                [Roact.Change.AbsoluteContentSize] = function(obj)
                    self.updateUnitListLength(obj.AbsoluteContentSize.Y)
                end
            }),
        }),

        SelectedUnitInfo = (selectedUnit) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.25, 0, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
                }),
    
                Padding = Roact.createElement(Padding, { Style.Constants.MinorElementPadding }),

                UnitNameLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = selectedUnit,
                    Font = Style.Constants.MainFont,
                    TextSize = 24,
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                -- TODO
                FlavorTextLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, 32),
                    Position = UDim2.new(0.5, 0, 0, 32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = "<i>" .. "Blupo please add details. >:(" .. "</i>",
                    RichText = true,
                    Font = Enum.Font.Gotham,
                    TextSize = 16,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                PurchaseButton = Roact.createElement("TextButton", {
                    AnchorPoint = Vector2.new(1, 1),
                    Size = UDim2.new(1, -32, 0, 24),
                    Position = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    Text = "",
                    TextTransparency = 1,

                    BackgroundColor3 = Color3.fromRGB(230, 230, 230),

                    [Roact.Event.Activated] = function()
                        Shop.PurchaseObjectGrant(LocalPlayer.UserId, GameEnum.ObjectType.Unit, selectedUnit)
                    end,
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                    }),
        
                    UIListLayout = Roact.createElement("UIListLayout", {
                        Padding = UDim.new(0, 2),

                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),

                    PriceLabel = Roact.createElement("TextLabel", {
                        Size = UDim2.new(playerOwnsSelectedUnit and UDim.new(1, 0) or UDim.new(0, grantPriceTextSize.X), UDim.new(1, 0)),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 0,

                        Text = playerOwnsSelectedUnit and "Purchased" or (selectedUnitGrantPrice or "?"),
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,

                        TextColor3 = Color3.new(0, 0, 0)
                    }),

                    TicketIcon = (not playerOwnsSelectedUnit) and
                        Roact.createElement("ImageLabel", {
                            Size = UDim2.new(0, 24, 0, 24),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            LayoutOrder = 1,

                            Image = "rbxassetid://327284812",
                            ImageColor3 = Color3.new(0, 0, 0)
                        })
                    or nil
                }),

                HotbarButton = Roact.createElement("TextButton", {
                    AnchorPoint = Vector2.new(0, 1),
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    Text = "",
                    TextTransparency = 1,

                    BackgroundColor3 = Color3.fromRGB(230, 230, 230),

                    [Roact.Event.Activated] = function()
                        local selectedUnitType = Unit.GetUnitType(selectedUnit)
                        local playerHotbar = PlayerData.GetPlayerHotbar(LocalPlayer.UserId, selectedUnitType)
                        if (not playerHotbar) then return end

                        local newHotbar = CopyTable(playerHotbar)

                        if (selectedUnitHotbarIndex) then
                            table.remove(newHotbar, selectedUnitHotbarIndex)
                        else
                            if (#newHotbar > maxHotbarItems) then return end

                            table.insert(newHotbar, selectedUnit)
                        end

                        PlayerData.SetPlayerHotbar(LocalPlayer.UserId, selectedUnitType, newHotbar)
                    end,
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                    }),

                    Icon = Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Size = UDim2.new(1, -4, 1, -4),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
            
                        Image = selectedUnitHotbarIndex and "rbxassetid://7447693659" or "rbxassetid://7447694738",
                        ImageColor3 = Color3.new(0, 0, 0)
                    })
                }),

                LevelSelector = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0.5, 0, 1, -32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0, 
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                    }),

                    ContextLabel = Roact.createElement("TextLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.new(0, 40, 1, 0),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,

                        Text = "Level",
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,

                        TextColor3 = Color3.new(0, 0, 0)
                    }),

                    SelectorContainer = Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(1, -48, 1, 0),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, {
                        Padding = Roact.createElement(Padding, { 0, Style.Constants.MajorElementPadding }),

                        IncrementButton = (selectedUnitLevel < selectedUnitMaxLevel) and
                            Roact.createElement("ImageButton", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                Size = UDim2.new(0, 24, 0, 24),
                                Position = UDim2.new(1, 0, 0.5, 0),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,

                                Image = "rbxassetid://330699633",
                                ImageColor3 = Color3.new(0, 0, 0),

                                [Roact.Event.Activated] = function()
                                    self:setState({
                                        selectedUnitLevel = math.min(selectedUnitLevel + 1, selectedUnitMaxLevel)
                                    })
                                end,
                            })
                        or nil,

                        DecrementButton = (selectedUnitLevel > 1) and
                            Roact.createElement("ImageButton", {
                                AnchorPoint = Vector2.new(0, 0.5),
                                Size = UDim2.new(0, 24, 0, 24),
                                Position = UDim2.new(0, 0, 0.5, 0),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,

                                Image = "rbxassetid://330699522",
                                ImageColor3 = Color3.new(0, 0, 0),

                                [Roact.Event.Activated] = function()
                                    self:setState({
                                        selectedUnitLevel = math.max(selectedUnitLevel - 1, 1)
                                    })
                                end,
                            })
                        or nil,

                        LevelLabel = Roact.createElement("TextLabel", {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(0, 20, 0, 24),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,

                            Text = selectedUnitLevel,
                            Font = Style.Constants.MainFont,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,

                            TextColor3 = Color3.new(0, 0, 0)
                        })
                    })
                }),

                StatList = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 1, -136),
                    Position = UDim2.new(0.5, 0, 0, 72),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, statListElements)
            })
        or nil
    })
end

---

SpecialShopPage.init = function(self)
    self.loadingImage = Roact.createRef()
    self.pageListLength, self.updatePageListLength = Roact.createBinding(0)
    self.ticketListLength, self.updateTicketListLength = Roact.createBinding(0)
    self.actionListLength, self.updateActionListLength = Roact.createBinding(0)

    self:setState({
        ticketProducts = {},
        productLoadingStatus = "wait",
    })
end

SpecialShopPage.didMount = function(self)
    self.rotator = RunService.Heartbeat:Connect(function(step)
        local loadingImage = self.loadingImage:getValue()
        if (not loadingImage) then return end

        if (self.state.productLoadingStatus == "wait") then
            loadingImage.Rotation = (loadingImage.Rotation + (step * 60)) % 360  
        else
            loadingImage.Rotation = 0
        end
    end)

    self.inventoryChangedConnection = PlayerData.InventoryChanged:Connect(function(_, itemType: string, itemName: string, newAmount: number, _)
        if (itemType ~= GameEnum.ItemType.SpecialAction) then return end
        if (self.state.selectedAction ~= itemName) then return end

        self:setState({
            selectedActionCount = newAmount
        })
    end)

    local ticketProducts = Shop.GetProducts()[GameEnum.DevProductType.Ticket]
    local ticketProductsSorted = {}

    for ticketAmount, productId in pairs(ticketProducts) do
        local productInfo = MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)

        table.insert(ticketProductsSorted, {
            ticketAmount = ticketAmount,
            price = productInfo.PriceInRobux,
            productId = productId
        })
    end

    table.sort(ticketProductsSorted, function(a, b)
        return tonumber(a.ticketAmount) < tonumber(b.ticketAmount)
    end)

    self:setState({
        ticketProducts = ticketProductsSorted,
        productLoadingStatus = Roact.None,
    })

    self.rotator:Disconnect()
end

SpecialShopPage.willUnmount = function(self)
    self.inventoryChangedConnection:Disconnect()
end

SpecialShopPage.render = function(self)
    local selectedAction = self.state.selectedAction
    local ticketProducts = self.state.ticketProducts
    local selectedActionPrice = selectedAction and Shop.GetItemPrice(GameEnum.ItemType.SpecialAction, selectedAction) or nil

    if (selectedActionPrice) then
        selectedActionPrice = (selectedActionPrice ~= math.huge) and selectedActionPrice or "∞"
    end

    local selectedActionPriceTextSize = selectedAction and TextService:GetTextSize(selectedActionPrice or "?", 16, Style.Constants.MainFont, Vector2.new(math.huge, math.huge)) or nil

    local ticketListElements = {}
    local actionListElements = {}

    if (#ticketProducts < 1) then
        ticketListElements.LoadingIndicator = Roact.createElement("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Image = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = "rbxassetid://6973265105",
                ImageColor3 = Color3.new(0, 0, 0),

                [Roact.Ref] = self.loadingImage,
            })
        })
    else
        for i = 1, #ticketProducts do
            local productInfo = ticketProducts[i]

            ticketListElements[productInfo.ticketAmount] = Roact.createElement("TextButton", {
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                LayoutOrder = i,
    
                Text = "",
                TextTransparency = 1,
    
                BackgroundColor3 = Color3.fromRGB(230, 230, 230),
                
                [Roact.Event.Activated] = function()
                    MarketplaceService:PromptProductPurchase(LocalPlayer, productInfo.productId, false)
                end,
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
                }),
    
                Padding = Roact.createElement(Padding, { Style.Constants.MinorElementPadding }),
    
                TicketAmountLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 1, -16),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = productInfo.ticketAmount,
                    Font = Style.Constants.MainFont,
                    TextSize = 32,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                PriceLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, 16),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = productInfo.price .. " R$",
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                })
            })
        end
    end

    for i = 1, #actionPricesSorted do
        local priceInfo = actionPricesSorted[i]

        actionListElements[priceInfo.actionName] = Roact.createElement("TextButton", {
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = i,

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = Color3.fromRGB(230, 230, 230),
            
            [Roact.Event.Activated] = function()
                self:setState({
                    selectedAction = priceInfo.actionName,
                    selectedActionCount = PlayerData.GetPlayerInventoryItemCount(LocalPlayer.UserId, GameEnum.ItemType.SpecialAction, priceInfo.actionName)
                })
            end,
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
            }),

            Padding = Roact.createElement(Padding, { Style.Constants.MinorElementPadding }),

            Image = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = "rbxassetid://3043812414", -- todo: replace this
                ImageColor3 = Color3.new(0, 0, 0),
            })
        })
    end

    ticketListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
        CellSize = UDim2.new(0, Style.Constants.UnitViewportFrameSize, 0, Style.Constants.UnitViewportFrameSize),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateTicketListLength(obj.AbsoluteContentSize.Y)
        end
    })

    actionListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
        CellSize = UDim2.new(0, Style.Constants.UnitViewportFrameSize, 0, Style.Constants.UnitViewportFrameSize),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateActionListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createFragment({
        SpecialList = Roact.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(selectedAction and UDim.new(0.7, -16) or UDim.new(1, 0), UDim.new(1, 0)),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            CanvasSize = self.pageListLength:map(function(listLength)
                return UDim2.new(0, 0, 0, listLength)
            end),

            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            ScrollBarThickness = 6,

            ScrollBarImageColor3 = Color3.new(0, 0, 0)
        }, {
            TicketHeader = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 0,

                Text = "Tickets",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,

                TextColor3 = Color3.new(0, 0, 0)
            }),

            TicketList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 1,
        
                Size = self.ticketListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, ticketListElements),

            ActionHeader = Roact.createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 2,

                Text = "Special Action Tokens",
                Font = Style.Constants.MainFont,
                TextSize = 32,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,

                TextColor3 = Color3.new(0, 0, 0)
            }),

            ActionList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 3,
        
                Size = self.actionListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, actionListElements),

            UIListLayout = Roact.createElement("UIListLayout", {
                Padding = UDim.new(0, Style.Constants.MajorElementPadding),
        
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
        
                [Roact.Change.AbsoluteContentSize] = function(obj)
                    self.updatePageListLength(obj.AbsoluteContentSize.Y)
                end
            }),
        }),

        SelectedActionInfo = selectedAction and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.fromRGB(245, 245, 245)
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
                }),
    
                Padding = Roact.createElement(Padding, { Style.Constants.MinorElementPadding }),

                ActionNameLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = selectedAction,
                    Font = Style.Constants.MainFont,
                    TextSize = 24,
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                -- TODO
                FlavorTextLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 1, -90),
                    Position = UDim2.new(0.5, 0, 0, 32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = "Blupo, please add details. >:(",
                    Font = Enum.Font.Gotham,
                    TextSize = 16,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                BackgroundImage = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Image = "rbxassetid://3043812414", -- todo: replace this
                    ImageTransparency = 0.75,
                    ScaleType = Enum.ScaleType.Fit,

                    ImageColor3 = Color3.new(0, 0, 0),
                }),

                OwnedLabel = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, -32, 0, 16),
                    Position = UDim2.new(0.5, 0, 1, -32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,

                    Text = "Owned: " .. self.state.selectedActionCount,
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                PurchaseButton = Roact.createElement("TextButton", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, -32, 0, 24),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,

                    Text = "",
                    TextTransparency = 1,

                    BackgroundColor3 = Color3.fromRGB(230, 230, 230),

                    [Roact.Event.Activated] = function()
                        Shop.PurchaseItem(LocalPlayer.UserId, GameEnum.ItemType.SpecialAction, selectedAction)
                    end,
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                    }),
        
                    UIListLayout = Roact.createElement("UIListLayout", {
                        Padding = UDim.new(0, 2),

                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),

                    PriceLabel = Roact.createElement("TextLabel", {
                        Size = UDim2.new(0, selectedActionPriceTextSize.X, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 0,

                        Text = selectedActionPrice,
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,

                        TextColor3 = Color3.new(0, 0, 0)
                    }),

                    TicketIcon = Roact.createElement("ImageLabel", {
                        Size = UDim2.new(0, 24, 0, 24),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 1,

                        Image = "rbxassetid://327284812",
                        ImageColor3 = Color3.new(0, 0, 0)
                    })
                }),
            })
        or nil
    })
end

---

local ShopMenu = Roact.PureComponent:extend("ShopMenu")

ShopMenu.init = function(self)
    self:setState({
        selectedCategory = 1
    })
end

ShopMenu.render = function(self)
    local selectedCategory = self.state.selectedCategory
    local categorySelectorChildren = {}

    for i = 1, #shopCategories do
        local category = shopCategories[i]

        categorySelectorChildren[category.name] = Roact.createElement("TextButton", {
            Size = UDim2.new(0, 128, 0, 32),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = i,

            Text = category.name,
            Font = Style.Constants.MainFont,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,

            BackgroundColor3 = Color3.fromRGB(230, 230, 230),
            TextColor3 = Color3.new(0, 0, 0),

            [Roact.Event.Activated] = function()
                if (selectedCategory == i) then return end
                
                self:setState({
                    selectedCategory = i
                })
            end,
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
            }),
        })
    end

    categorySelectorChildren.UIListLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0.6, 0, 0.5, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.new(1, 1, 1)
    }, {
        UISizeConstraint = Roact.createElement("UISizeConstraint", {
            MaxSize = Vector2.new(735, 455)
        }),

        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
        }),

        Padding = Roact.createElement(Padding, { Style.Constants.MajorElementPadding }),

        CategorySelector = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, categorySelectorChildren),

        ShopPage = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 1, -48),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Roact.createElement(shopCategories[selectedCategory].element),
        }),
    })
end

return ShopMenu