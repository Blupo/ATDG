local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Button = require(GameUIModules:WaitForChild("Button"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local StatListItem = require(GameUIModules:WaitForChild("StatListItem"))
local Style = require(GameUIModules:WaitForChild("Style"))
local UnitFrame = require(GameUIModules:WaitForChild("UnitFrame"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local FormatAttribute = require(PlayerModules:WaitForChild("FormatAttribute"))
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local SharedGameData = require(SharedModules:WaitForChild("SharedGameData"))
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding
local StandardUIGridLayout = StandardComponents.UIGridLayout

---

local maxHotbarItems = SharedGameData.GameConstants.MaxHotbarItems
local unitPrices = ShopPrices.ObjectGrantPrices[GameEnum.ObjectType.Unit]

---

local UnitShopSubpage = Roact.PureComponent:extend("UnitShopSubpage")

UnitShopSubpage.init = function(self)
    self.unitListLength, self.updateUnitListLength = Roact.createBinding(0)
    self.towerUnitListLength, self.updateTowerUnitListLength = Roact.createBinding(0)
    self.fieldUnitListLength, self.updateFieldUnitListLength = Roact.createBinding(0)
    self.selectedUnitStatListLength, self.updateSelectedUnitStatListLength = Roact.createBinding(0)

    self.getUnitList = function()
        local unitsMap = {}
        local playerUnitGrants = PlayerData.GetPlayerObjectGrants(LocalPlayer.UserId)[GameEnum.ObjectType.Unit]

        local unitsSorted = {
            [GameEnum.UnitType.TowerUnit] = {},
            [GameEnum.UnitType.FieldUnit] = {},
        }

        for unitName in pairs(unitPrices) do
            unitsMap[unitName] = true
        end

        for unitName in pairs(playerUnitGrants) do
            unitsMap[unitName] = true
        end

        for unitName in pairs(unitsMap) do
            local unitType = Unit.GetUnitType(unitName)

            table.insert(unitsSorted[unitType], unitName)
        end

        table.sort(unitsSorted[GameEnum.UnitType.TowerUnit], function(a, b)
            return string.lower(a) < string.lower(b)
        end)
        
        table.sort(unitsSorted[GameEnum.UnitType.FieldUnit], function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        return unitsSorted
    end

    self:setState({
        showUnits = {
            [GameEnum.UnitType.TowerUnit] = {},
            [GameEnum.UnitType.FieldUnit] = {},
        }
    })
end

UnitShopSubpage.didMount = function(self)
    self.objectGrantedConnection = PlayerData.ObjectGranted:Connect(function(_, objectType: string, objectName: string)
        if (objectType ~= GameEnum.ObjectType.Unit) then return end

        self:setState({
            showUnits = self.getUnitList(),
            playerOwnsSelectedUnit = (self.state.selectedUnit == objectName) and true or nil,
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

    self:setState({
        showUnits = self.getUnitList()
    })
end

UnitShopSubpage.willUnmount = function(self)
    self.objectGrantedConnection:Disconnect()
    self.playerHotbarChanged:Disconnect()
end

UnitShopSubpage.render = function(self)
    local selectedUnit = self.state.selectedUnit
    local selectedUnitLevel = self.state.selectedUnitLevel
    local playerOwnsSelectedUnit = self.state.playerOwnsSelectedUnit
    local selectedUnitHotbarIndex = self.state.selectedUnitHotbarIndex

    local selectedUnitMaxLevel
    local selectedUnitGrantPrice
    local selectedUnitUpgradePriceText
    local selectedUnitGrantPriceTextSize

    local towerUnitPrices = self.state.showUnits[GameEnum.UnitType.TowerUnit]
    local fieldUnitPrices = self.state.showUnits[GameEnum.UnitType.FieldUnit]

    local towerUnitListElements = {}
    local fieldUnitListElements = {}
    local statListElements = {}

    for i = 1, #towerUnitPrices do
        local unitName = towerUnitPrices[i]

        towerUnitListElements[unitName] = Roact.createElement(UnitFrame, {
            LayoutOrder = i,

            unitName = unitName,
            selected = (selectedUnit == unitName),
            subtextDisplayType = "UnitName",
            subtextHoverDisplayType = "GrantCost",
            
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
        local unitName = fieldUnitPrices[i]

        fieldUnitListElements[unitName] = Roact.createElement(UnitFrame, {
            LayoutOrder = i,

            unitName = unitName,
            selected = (selectedUnit == unitName),
            subtextDisplayType = "UnitName",
            subtextHoverDisplayType = "GrantCost",
            
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
        local selectedUnitPreviewAttributes = PreviewAttributes[Unit.GetUnitType(selectedUnit)]
        local selectedUnitBaseAttributes = Unit.GetUnitBaseAttributes(selectedUnit, selectedUnitLevel)
        local selectedUnitBaseAbilities = Unit.GetUnitBaseAbilities(selectedUnit, selectedUnitLevel)
        local sortedAbilities = {}

        selectedUnitMaxLevel = Unit.GetUnitMaxLevel(selectedUnit)
        selectedUnitGrantPrice = Shop.GetObjectGrantPrice(GameEnum.ObjectType.Unit, selectedUnit)
        selectedUnitGrantPriceTextSize = TextService:GetTextSize(selectedUnitGrantPrice or "?", 16, Style.Constants.PrimaryFont, Vector2.new(math.huge, math.huge))

        if (selectedUnitLevel == 1) then
            selectedUnitUpgradePriceText = Shop.GetObjectPlacementPrice(GameEnum.ObjectType.Unit, selectedUnit) or "?"
        elseif (selectedUnitLevel == selectedUnitMaxLevel) then
            selectedUnitUpgradePriceText = "N/A"
        else
            selectedUnitUpgradePriceText = Shop.GetUnitUpgradePrice(selectedUnit, selectedUnitLevel) or "?"
        end

        for ability in pairs(selectedUnitBaseAbilities) do
            table.insert(sortedAbilities, ability)
        end

        table.sort(sortedAbilities, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        for i = 1, #selectedUnitPreviewAttributes do
            local attribute = selectedUnitPreviewAttributes[i]
            local attributeValue = FormatAttribute(attribute, selectedUnitBaseAttributes[attribute])

            if ((attribute == "RANGE") and (selectedUnitBaseAttributes.UnitTargeting == GameEnum.UnitTargeting.AreaOfEffect)) then
                attributeValue = attributeValue .. " (AoE)"
            end

            statListElements[attribute] = Roact.createElement(StatListItem, {
                Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = i,

                Text = attributeValue,
                Image = Style.Images[attribute .. "AttributeIcon"],

                ImageColor3 = Style.Colors[attribute .. "AttributeIconColor"]
            })
        end

        -- TODO: ability display names
        for i = 1, #sortedAbilities do
            local ability = sortedAbilities[i]

            statListElements[ability] = Roact.createElement(StatListItem, {
                Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = #selectedUnitPreviewAttributes + i,

                Text = ability,
                Image = Style.Images.UnitAbilityIcon,

                ImageColor3 = Color3.new(0, 0, 0),
            })
        end

        statListElements.UpgradePrice = (selectedUnitLevel ~= selectedUnitMaxLevel) and
            Roact.createElement(StatListItem, {
                Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
                LayoutOrder = #selectedUnitPreviewAttributes + #sortedAbilities + 1,

                Text = selectedUnitUpgradePriceText,
                Image = Style.Images[(selectedUnitLevel == 1) and "PlaceUnitIcon" or "UpgradeUnitIcon"],

                ImageColor3 = Color3.new(0, 0, 0),
            })
        or nil

        statListElements.SellingPrice = Roact.createElement(StatListItem, {
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, Style.Constants.StandardButtonHeight),
            LayoutOrder = #selectedUnitPreviewAttributes + #sortedAbilities + 2,
            
            Text = Shop.GetUnitSellingPrice(selectedUnit, selectedUnitLevel),
            Image = Style.Images.SellUnitIcon,

            ImageColor3 = Color3.new(0, 0, 0),
        })

        statListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updateSelectedUnitStatListLength(obj.AbsoluteContentSize.Y)
            end,
        })
    end

    towerUnitListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
        CellSize = UDim2.new(
            0, Style.Constants.InventoryFrameButtonSize,
            0, Style.Constants.InventoryFrameButtonSize + Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding
        ),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateTowerUnitListLength(obj.AbsoluteContentSize.Y)
        end
    })

    fieldUnitListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
        CellSize = UDim2.new(
            0, Style.Constants.InventoryFrameButtonSize,
            0, Style.Constants.InventoryFrameButtonSize + Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding
        ),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateFieldUnitListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createFragment({
        UnitList = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(selectedUnit and 0.7 or 1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0.5, 0),

            CanvasSize = self.unitListLength:map(function(listLength)
                return UDim2.new(0, 0, 0, listLength)
            end),
        }, {
            TowerUnitHeader = Roact.createElement(StandardTextLabel, {
                Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
                LayoutOrder = 0,

                Text = "Tower Units",
                TextSize = Style.Constants.PrimaryHeaderTextSize,
            }),

            TowerUnitList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 1,
        
                Size = self.towerUnitListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, towerUnitListElements),

            FieldUnitHeader = Roact.createElement(StandardTextLabel, {
                Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
                LayoutOrder = 2,

                Text = "Field Units",
                TextSize = Style.Constants.PrimaryHeaderTextSize,
            }),

            FieldUnitList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 3,
        
                Size = self.fieldUnitListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, fieldUnitListElements),

            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.MajorElementPadding),

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
                Size = UDim2.new(0.3, -Style.Constants.SpaciousElementPadding, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.new(1, 1, 1),
            }, {
                UICorner = Roact.createElement(StandardUICorner),
                UIPadding = Roact.createElement(StandardUIPadding),

                SelectedUnit = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),
                    Position = UDim2.new(0.5, 0, 0, 0),

                    Text = Unit.GetUnitDisplayName(selectedUnit),
                    TextSize = Style.Constants.SecondaryHeaderTextSize,
                    TextScaled = true,
                    TextYAlignment = Enum.TextYAlignment.Top,
                }),

                StatList = Roact.createElement(StandardScrollingFrame, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, (Style.Constants.SecondaryHeaderTextSize + Style.Constants.SpaciousElementPadding)),
                    
                    Size = UDim2.new(1, 0, 1, -(
                        Style.Constants.StandardButtonHeight * 2 +
                        Style.Constants.SecondaryHeaderTextSize +
                        (Style.Constants.SpaciousElementPadding * 3)
                    )),

                    CanvasSize = self.selectedUnitStatListLength:map(function(length)
                        return UDim2.new(0, 0, 0, length)
                    end),
                }, statListElements),

                LevelSelector = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize + Style.Constants.SpaciousElementPadding),
                    Position = UDim2.new(0.5, 0, 1, -32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0, 
                }, {
                    Label = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.new(0, 40, 1, 0),
                        Position = UDim2.new(0, 0, 0.5, 0),

                        Text = "Level",
                    }),

                    SelectorContainer = Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(1, -(40 + Style.Constants.SpaciousElementPadding), 1, 0),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, {
                        LevelLabel = Roact.createElement(StandardTextLabel, {
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Size = UDim2.new(0, 20, 0, 24),
                            Position = UDim2.new(0.5, 0, 0.5, 0),

                            Text = selectedUnitLevel,
                            TextXAlignment = Enum.TextXAlignment.Center,
                        }),

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
                    })
                }),

                HotbarButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                    Position = UDim2.new(0, 0, 1, 0),

                    Image = Style.Images[selectedUnitHotbarIndex and "StarFilledIcon" or "StarOutlineIcon"],
                    ImageSize = UDim2.new(
                        0, (Style.Constants.StandardIconSize - Style.Constants.MinorElementPadding),
                        0, (Style.Constants.StandardIconSize - Style.Constants.MinorElementPadding)
                    ),

                    BackgroundColor3 = Style.Colors.HotbarButtonColor,

                    displayType = "Image",
                    onActivated = function()
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
                }),

                PurchaseButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 1),
                    Size = UDim2.new(1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding), 0, Style.Constants.StandardButtonHeight),
                    Position = UDim2.new(1, 0, 1, 0),

                    displayType = "Children",

                    onActivated = function()
                        Shop.PurchaseObjectGrant(LocalPlayer.UserId, GameEnum.ObjectType.Unit, selectedUnit)
                    end,
                }, {
                    UIListLayout = Roact.createElement(StandardUIListLayout, {
                        Padding = UDim.new(0, Style.Constants.MinorElementPadding),

                        FillDirection = Enum.FillDirection.Horizontal,
                    }),

                    PriceLabel = Roact.createElement(StandardTextLabel, {
                        Size = UDim2.new(playerOwnsSelectedUnit and UDim.new(1, 0) or UDim.new(0, selectedUnitGrantPriceTextSize.X), UDim.new(1, 0)),
                        LayoutOrder = 0,

                        Text = playerOwnsSelectedUnit and "Owned" or (selectedUnitGrantPrice or "?"),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,
                    }),

                    CurerncyIcon = (not playerOwnsSelectedUnit) and
                        Roact.createElement("ImageLabel", {
                            Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            LayoutOrder = 1,

                            Image = Style.Images.TicketsCurrencyIcon,
                            ImageColor3 = Color3.new(0, 0, 0)
                        })
                    or nil
                }),
            })
        or nil
    })
end

return UnitShopSubpage