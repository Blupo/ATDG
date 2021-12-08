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
local PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding
local StandardUIGridLayout = StandardComponents.UIGridLayout

---

--[[
    props

        unitType: UnitType
]]

local UnitInventorySubpage = Roact.PureComponent:extend("UnitInventorySubpage")

UnitInventorySubpage.init = function(self)
    self.unitListLength, self.updateUnitListLength = Roact.createBinding(0)
    self.selectedUnitStatListLength, self.updateSelectedUnitStatListLength = Roact.createBinding(0)

    self:setState({
        ownedUnits = {}
    })
end

UnitInventorySubpage.didMount = function(self)
    self.objectGrantedConnection = PlayerData.ObjectGranted:Connect(function(_, objectType: string, objectName: string)
        if (objectType ~= GameEnum.ObjectType.Unit) then return end

        self:setState({
            showUnits = self.getUnitList(),
            playerOwnsSelectedUnit = (self.state.selectedUnit == objectName) and true or nil,
        })
    end)

    self.unitPersistentUpgradedConnection = Unit.UnitPersistentUpgraded:Connect(function(_, unitName: string, newLevel: number)
        local selectedUnit = self.state.selectedUnit
        if (selectedUnit ~= unitName) then return end

        self:setState({
            selectedUnitLevel = newLevel,
        })
    end)

    local unitGrants = PlayerData.GetPlayerObjectGrants(LocalPlayer.UserId)[GameEnum.ObjectType.Unit]

    for unitName in pairs(unitGrants) do
        local unitType = Unit.GetUnitType(unitName)

        if (unitType ~= self.props.unitType) then
            unitGrants[unitName] = nil
        end
    end

    self:setState({
        ownedUnits = unitGrants,
    })
end

UnitInventorySubpage.willUnmount = function(self)
    self.objectGrantedConnection:Disconnect()
    self.unitPersistentUpgradedConnection:Disconnect()
end

UnitInventorySubpage.didUpdate = function(self, prevProps)
    local unitType = self.props.unitType
    if (unitType == prevProps.unitType) then return end

    local unitGrants = PlayerData.GetPlayerObjectGrants(LocalPlayer.UserId)[GameEnum.ObjectType.Unit]

    for unitName in pairs(unitGrants) do
        local thisUnitType = Unit.GetUnitType(unitName)

        if (thisUnitType ~= unitType) then
            unitGrants[unitName] = nil
        end
    end

    self:setState({
        ownedUnits = unitGrants,

        selectedUnit = Roact.None,
        selectedUnitLevel = Roact.None,
    })
end

UnitInventorySubpage.render = function(self)
    local unitType = self.props.unitType
    local ownedUnits = self.state.ownedUnits
    local selectedUnit = self.state.selectedUnit
    local selectedUnitLevel = self.state.selectedUnitLevel

    local selectedUnitIsMaxLevel
    local selectedUnitPlacementPrice
    local selectedUnitPersistentUpgradePrice
    local selectedUnitPlacementPriceTextSize
    local selectedUnitPersistentUpgradePriceTextSize

    local unitListElements = {}
    local statListElements = {}

    for unit in pairs(ownedUnits) do
        local selected = (unit == selectedUnit)

        unitListElements[unit] = Roact.createElement(UnitFrame, {
            unitName = unit,
            selected = selected,
            subtextDisplayType = "UnitName",
            
            onActivated = function()
                self:setState({
                    selectedUnit = selected and Roact.None or unit,
                    selectedUnitLevel = selected and Roact.None or Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, unit),
                })
            end,
        })
    end

    if (selectedUnit) then
        local selectedUnitPreviewAttributes = PreviewAttributes[unitType]
        local selectedUnitBaseAttributes = Unit.GetUnitBaseAttributes(selectedUnit, selectedUnitLevel)

        selectedUnitIsMaxLevel = (selectedUnitLevel == Unit.GetUnitMaxLevel(selectedUnit))
        selectedUnitPlacementPrice = Shop.GetObjectPlacementPrice(GameEnum.ObjectType.Unit, selectedUnit)
        selectedUnitPersistentUpgradePrice = Shop.GetUnitPersistentUpgradePrice(selectedUnit, selectedUnitLevel)

        selectedUnitPlacementPriceTextSize = TextService:GetTextSize(
            selectedUnitPlacementPrice,
            Style.Constants.StandardTextSize,
            Style.Constants.PrimaryFont,
            Vector2.new(math.huge, Style.Constants.StandardTextSize)
        )

        selectedUnitPersistentUpgradePriceTextSize = (selectedUnitPersistentUpgradePrice) and
            TextService:GetTextSize(
                selectedUnitPersistentUpgradePrice,
                Style.Constants.StandardTextSize,
                Style.Constants.PrimaryFont,
                Vector2.new(math.huge, Style.Constants.StandardTextSize)
            )
        or nil

        for i = 1, #selectedUnitPreviewAttributes do
            local attribute = selectedUnitPreviewAttributes[i]
            local attributeValue = FormatAttribute(attribute, selectedUnitBaseAttributes[attribute])

            statListElements[attribute] = Roact.createElement(StatListItem, {
                LayoutOrder = i,
                
                Text = attributeValue,
                Image = Style.Images[attribute .. "AttributeIcon"],

                ImageColor3 = Style.Colors[attribute .. "AttributeIconColor"]
            })
        end

        statListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
            CellSize = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.StandardButtonHeight),

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updateSelectedUnitStatListLength(obj.AbsoluteContentSize.Y)
            end
        })
    end

    unitListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
        SortOrder = Enum.SortOrder.Name,

        CellSize = UDim2.new(
            0, Style.Constants.InventoryFrameButtonSize,
            0, Style.Constants.InventoryFrameButtonSize + Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding
        ),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateUnitListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createFragment({
        UnitList = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),

            Size = UDim2.new(1, 0, 1, (selectedUnit) and
                -(
                    Style.Constants.StandardTextSize +
                    (Style.Constants.StandardIconSize * 2) +
                    Style.Constants.LargeButtonHeight +
                    (Style.Constants.SpaciousElementPadding * 4) +
                    Style.Constants.MajorElementPadding
                ) or 0
            ) ,

            CanvasSize = self.unitListLength:map(function(listLength)
                return UDim2.new(0, 0, 0, listLength)
            end),
        }, unitListElements),

        SelectedUnitInfo = (selectedUnit) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                Size = UDim2.new(1, 0, 0,
                    Style.Constants.StandardTextSize +
                    (Style.Constants.StandardButtonHeight * 2) +
                    Style.Constants.LargeButtonHeight +
                    (Style.Constants.SpaciousElementPadding * 3) +
                    Style.Constants.MajorElementPadding
                ),

                BackgroundColor3 = Color3.new(1, 1, 1),
            }, {
                UICorner = Roact.createElement(StandardUICorner),
                UIPadding = Roact.createElement(StandardUIPadding),

                SelectedUnit = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                    Position = UDim2.new(0.5, 0, 0, 0),

                    Text = Unit.GetUnitDisplayName(selectedUnit) .. " (" .. selectedUnitLevel .. ")",
                    TextScaled = true,
                    TextYAlignment = Enum.TextYAlignment.Top,
                }),

                StatList = Roact.createElement(StandardScrollingFrame, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 1, -(Style.Constants.StandardTextSize + Style.Constants.LargeButtonHeight + (Style.Constants.SpaciousElementPadding * 2))),
                    Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardTextSize + Style.Constants.SpaciousElementPadding),

                    CanvasSize = self.selectedUnitStatListLength:map(function(length)
                        return UDim2.new(0, 0, 0, length)
                    end),
                }, statListElements),

                PlaceButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.LargeButtonHeight),
                    Position = UDim2.new(0, 0, 1, 0),

                    displayType = "Children",
                    onActivated = function()
                        -- todo: check for available funds first
                        self:setState({
                            selectedUnit = Roact.None,
                            selectedUnitLevel = Roact.None,
                        })
                        
                        PlacementFlow.Start(selectedUnit)
                    end,
                }, {
                    Icon = Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                        Position = UDim2.new(0, Style.Constants.MinorElementPadding, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,

                        Image = Style.Images.PlaceUnitIcon,
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
                            Size = UDim2.new(0, selectedUnitPlacementPriceTextSize.X, 1, 0),
                            LayoutOrder = 1,

                            Text = selectedUnitPlacementPrice,
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

                PersistentUpgradeButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 1),
                    Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.LargeButtonHeight),
                    Position = UDim2.new(1, 0, 1, 0),

                    displayType = "Children",
                    onActivated = function()
                        Shop.PurchaseUnitPersistentUpgrade(LocalPlayer.UserId, selectedUnit)
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
                                selectedUnitIsMaxLevel and UDim.new(1, 0) or UDim.new(0, selectedUnitPersistentUpgradePriceTextSize.X),
                                UDim.new(1, 0)
                            ),

                            Text = selectedUnitIsMaxLevel and "MAX" or selectedUnitPersistentUpgradePrice,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            TextYAlignment = Enum.TextYAlignment.Center,
                        }),

                        CurrencyIcon = (not selectedUnitIsMaxLevel) and
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
        or nil
    })
end

return UnitInventorySubpage