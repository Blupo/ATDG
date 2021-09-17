local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local IconButton = require(GameUIModules:WaitForChild("IconButton"))
local Padding = require(GameUIModules:WaitForChild("Padding"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))
local UnitViewport = require(GameUIModules:WaitForChild("UnitViewport"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local SpecialActions = SystemCoordinator.waitForSystem("SpecialActions")

---

local UnitInventory = Roact.PureComponent:extend("UnitInventory")
local SpecialInventory = Roact.PureComponent:extend("SpecialInventory")

local pageElements = {
    [GameEnum.UnitType.TowerUnit] = UnitInventory,
    [GameEnum.UnitType.FieldUnit] = UnitInventory,
    [GameEnum.ItemType.SpecialAction] = SpecialInventory,
}

---

--[[
    props

        unitType: string

        AnchorPoint
        Size
        Position
]]

UnitInventory.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)

    self:setState({
        unitGrants = {},
    })
end

UnitInventory.didMount = function(self)
    self.objectGranted = PlayerData.ObjectGranted:Connect(function(_, objectType: string, objectName: string)
        if (objectType ~= GameEnum.ObjectType.Unit) then return end

        local unitType = Unit.GetUnitType(objectName)
        if (unitType ~= self.props.unitType) then return end

        local newUnitGrants = CopyTable(self.state.unitGrants)
        newUnitGrants[objectName] = true

        self:setState({
            unitGrants = newUnitGrants
        })
    end)

    self.unitPersistentUpgraded = Unit.UnitPersistentUpgraded:Connect(function(_, unitName: string, newLevel: number)
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
        unitGrants = unitGrants,
    })
end

UnitInventory.willUnmount = function(self)
    self.objectGranted:Disconnect()
    self.unitPersistentUpgraded:Disconnect()
end

UnitInventory.didUpdate = function(self, prevProps)
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
        unitGrants = unitGrants,

        selectedUnit = Roact.None,
        selectedUnitLevel = Roact.None,
    })
end

UnitInventory.render = function(self)
    local unitType = self.props.unitType
    local unitGrants = self.state.unitGrants
    local selectedUnit = self.state.selectedUnit
    local selectedUnitLevel = self.state.selectedUnitLevel

    local unitListChildren = {}
    local selectedUnitAttributesPreviewChildren = {}

    for unitName in pairs(unitGrants) do
        unitListChildren[unitName] = Roact.createElement(UnitViewport, {
            unitName = unitName,
            titleDisplayType = "UnitName",
            rightInfoDisplayType = "Level",

            onActivated = function()
                self:setState({
                    selectedUnit = unitName,
                    selectedUnitLevel = Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, unitName),
                })
            end,
        })
    end

    unitListChildren.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, Style.Constants.MinorElementPadding, 0, Style.Constants.MinorElementPadding),
        CellSize = UDim2.new(0, Style.Constants.UnitViewportFrameSize, 0, Style.Constants.UnitViewportFrameSize),

        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.Name,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end
    })

    if (selectedUnit) then
        local attributes = Unit.GetUnitBaseAttributes(selectedUnit, selectedUnitLevel)
        local previewAttributes = PreviewAttributes[unitType]

        for i = 1, #previewAttributes do
            local attribute = previewAttributes[i]
            local attributeValue = attributes[attribute]

            if (tonumber(attributeValue) and (attribute ~= "MaxHP")) then
                if (attributeValue ~= math.huge) then
                    attributeValue = string.format("%0.2f", attributeValue)
                else
                    attributeValue = "∞"
                end
            elseif (attribute == "PathType") then
                if (attributeValue == GameEnum.PathType.Ground) then
                    attributeValue = "G"
                elseif (attributeValue == GameEnum.PathType.Air) then
                    attributeValue = "A"
                elseif (attributeValue == GameEnum.PathType.GroundAndAir) then
                    attributeValue = "GA"
                end
            end

            selectedUnitAttributesPreviewChildren[i] = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = i,
            }, {
                Icon = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 22, 0, 22),
                    Position = UDim2.new(0, 2, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = Style.Images[attribute .. "AttributeIcon"],

                    ImageColor3 = Style.Colors[attribute .. "AttributeIconColor"]
                }),
        
                Label = Roact.createElement("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(1, -(22 + Style.Constants.MinorElementPadding), 0, 16),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
        
                    Text = attributeValue,
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextStrokeTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextScaled = true,

                    TextColor3 = Color3.new(0, 0, 0)
                })
            })
        end

        selectedUnitAttributesPreviewChildren.UIGridLayout = Roact.createElement("UIGridLayout", {
            CellPadding = UDim2.new(0, 4, 0, 4),
            CellSize = UDim2.new(0.5, -2, 0.5, -2),

            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = 2,
            SortOrder = Enum.SortOrder.LayoutOrder,
            StartCorner = Enum.StartCorner.TopLeft,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        })
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        UnitList = Roact.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 1, -(72 + Style.Constants.MajorElementPadding)),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            CanvasSize = self.listLength:map(function(length)
                return UDim2.new(0, 0, 0, length)
            end),

            VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
            ScrollBarThickness = 6,

            ScrollBarImageColor3 = Color3.new(0, 0, 0)
        }, unitListChildren),

        SelectedUnitInfo = (selectedUnit) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 0, 72),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                Buttons = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Size = UDim2.new(0.4, -8, 1, 0),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    PlaceButton = Roact.createElement(IconButton, {
                        AnchorPoint = Vector2.new(0.5, 0),
                        Size = UDim2.new(1, 0, 0.5, -Style.Constants.MinorElementPadding / 2),
                        Position = UDim2.new(0.5, 0, 0, 0),
                        LayoutOrder = 1,

                        Text = Shop.GetObjectPlacementPrice(GameEnum.ObjectType.Unit, selectedUnit) or "?",
                        Image = "rbxassetid://6837004068",

                        onActivated = function()

                            if (unitType == GameEnum.UnitType.TowerUnit) then
                                -- todo: check for available funds first
                                self:setState({
                                    selectedUnit = Roact.None,
                                })
                                
                                PlacementFlow.Start(GameEnum.ObjectType.Unit, selectedUnit)
                            elseif (unitType == GameEnum.UnitType.FieldUnit) then
                                -- todo
                                print("Coming in a future update.")
                            end
                        end,

                        ImageColor3 = Color3.new(0, 0, 0),
                    }),

                    PersistentUpgradeButton = Roact.createElement(IconButton, {
                        AnchorPoint = Vector2.new(0.5, 1),
                        Size = UDim2.new(1, 0, 0.5, -Style.Constants.MinorElementPadding / 2),
                        Position = UDim2.new(0.5, 0, 1, 0),
                        LayoutOrder = 2,

                        Text = Shop.GetUnitPersistentUpgradePrice(selectedUnit, selectedUnitLevel) or "MAX",
                        Image = "rbxassetid://6837004663",

                        onActivated = function()
                            Shop.PurchaseUnitPersistentUpgrade(LocalPlayer.UserId, selectedUnit)
                        end,

                        ImageColor3 = Color3.new(0, 0, 0),
                    }),
                }),

                Info = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.6, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    NameLabel = Roact.createElement("TextLabel", {
                        AnchorPoint = Vector2.new(0, 0),
                        Size = UDim2.new(1, 0, 0, 16),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,

                        Text = Unit.GetUnitDisplayName(selectedUnit) .. " (" .. selectedUnitLevel .. ")",
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextStrokeTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        TextScaled = true,

                        TextColor3 = Color3.new(0, 0, 0)
                    }),

                    AttributesPreview = Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(0.5, 1),
                        Size = UDim2.new(1, 0, 1, -(16 + Style.Constants.MinorElementPadding)),
                        Position = UDim2.new(0.5, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, selectedUnitAttributesPreviewChildren)
                })
            })
        or nil,
    })
end

---

--[[
    props

        AnchorPoint
        Size
        Position
]]

SpecialInventory.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)

    self:setState({
        inventory = {}
    })
end

SpecialInventory.didMount = function(self)
    self.inventoryChanged = PlayerData.InventoryChanged:Connect(function(_, itemType: string, itemName: string, newAmount: number)
        if (itemType ~= GameEnum.ItemType.SpecialAction) then return end

        local newInventory = CopyTable(self.state.inventory)
        newInventory[itemName] = (newAmount > 0) and newAmount or nil

        self:setState({
            inventory = newInventory
        })
    end)

    self:setState({
        inventory = PlayerData.GetPlayerInventory(LocalPlayer.UserId)[GameEnum.ItemType.SpecialAction]
    })
end

SpecialInventory.willUnmount = function(self)
    self.inventoryChanged:Disconnect()
end

SpecialInventory.render = function(self)
    local inventory = self.state.inventory
    local inventoryListElements = {}

    for actionName, quantity in pairs(inventory) do
        inventoryListElements[actionName] = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = Color3.fromRGB(240, 240, 240),
        }, {
            UIPadding = Roact.createElement(Padding, {Style.Constants.MinorElementPadding}),

            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius),
            }),

            ActionImage = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 48, 0, 48),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 1,

                Image = "rbxassetid://3043812414",
                ImageColor3 = Color3.new(0, 0, 0),
            }),

            ActionName = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(1, -96, 0, 24),
                Position = UDim2.new(0, 64, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = actionName,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextColor3 = Color3.new(0, 0, 0),
            }),

            ActionQuantity = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0, 32, 0, 24),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                Text = quantity,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,

                BackgroundColor3 = Color3.new(1, 1, 1),
                TextColor3 = Color3.new(0, 0, 0),
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius),
                }),
            }),

            Buttons = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Size = UDim2.new(1, -64, 0, 24),
                Position = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                UIListLayout = Roact.createElement("UIListLayout", {
                    Padding = UDim.new(0, Style.Constants.MinorElementPadding),
        
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                }),

                UseButton = Roact.createElement("TextButton", {
                    Size = UDim2.new(0, 60, 0, 24),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    LayoutOrder = 2,

                    Text = "Use",
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    BackgroundColor3 = Color3.new(1, 1, 1),
                    TextColor3 = Color3.new(0, 0, 0),

                    [Roact.Event.Activated] = function()
                        SpecialActions.UseSpecialAction(LocalPlayer.UserId, actionName)
                    end,
                }, {
                    UICorner = Roact.createElement("UICorner", {
                        CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius),
                    }),
                }),
            }),
        })
    end

    inventoryListElements.UIListLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.Constants.MinorElementPadding),

        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.Name,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createElement("ScrollingFrame", {
        AnchorPoint = self.props.AnchorPoint,
        Size = self.props.Size,
        Position = self.props.Position,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,

        CanvasSize = self.listLength:map(function(length)
            return UDim2.new(0, 0, 0, length)
        end),

        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
        ScrollBarThickness = 6,

        ScrollBarImageColor3 = Color3.new(0, 0, 0)
    }, inventoryListElements)
end

---

local GameInventory = Roact.PureComponent:extend("GameInventory")

GameInventory.init = function(self)
    self:setState({
        category = GameEnum.UnitType.TowerUnit,
        placementFlowOpen = false,
        open = false,
    })
end

GameInventory.didMount = function(self)
    self.placementFlowStarted = PlacementFlow.Started:Connect(function()
        self:setState({
            placementFlowOpen = true,
        })
    end)

    self.placementFlowStopped = PlacementFlow.Stopped:Connect(function()
        self:setState({
            placementFlowOpen = false,
        })
    end)
end

GameInventory.willUnmount = function(self)
    self.placementFlowStarted:Disconnect()
    self.placementFlowStopped:Disconnect()
end

GameInventory.render = function(self)
    if (self.state.placementFlowOpen) then
        return Roact.createElement("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0, 250, 0, 24),
            Position = UDim2.new(1, -Style.Constants.MajorElementPadding, 1, -Style.Constants.MajorElementPadding),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            Text = "Unit Placement (Q to Cancel)",
            Font = Style.Constants.MainFont,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,

            BackgroundColor3 = Color3.new(1, 1, 1),
            TextColor3 = Color3.new(0, 0, 0),

            [Roact.Event.Activated] = function()
                PlacementFlow.Stop()
            end
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius),
            }),
        })
    end

    local isOpen = self.state.open
    local category = self.state.category

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(isOpen and 1 or 0, 1),
        Size = UDim2.new(0, 310, 0, 420),
        Position = UDim2.new(1, isOpen and 0 or Style.Constants.MajorElementPadding, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.new(1, 1, 1)
    }, {
        UIPadding = Roact.createElement(Padding, {Style.Constants.MajorElementPadding}),

        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius),
        }),

        ToggleButton = Roact.createElement("TextButton", {
            AnchorPoint = Vector2.new(1, isOpen and 0 or 1),
            Size = UDim2.new(0, 70, 0, 70),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            AutoButtonColor = false,

            Position = UDim2.new(
                UDim.new(0, -Style.Constants.MajorElementPadding * 2),
                isOpen and UDim.new(0, -Style.Constants.MajorElementPadding) or UDim.new(1, Style.Constants.MajorElementPadding)
            ),

            Text = "",
            TextTransparency = 1,
            TextStrokeTransparency = 1,

            BackgroundColor3 = Color3.new(1, 1, 1),

            [Roact.Event.Activated] = function()
                self:setState({
                    open = not self.state.open
                })
            end
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius),
            }),

            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = Style.Images.InventoryIcon,
                ImageColor3 = Color3.new(0, 0, 0),
            })
        }),

        Categories = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(1, 0, 0, 72),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            UIGridLayout = Roact.createElement("UIGridLayout", {
                CellPadding = UDim2.new(0, 8, 0, 8),
                CellSize = UDim2.new(0.5, -4, 0.5, -4),

                FillDirection = Enum.FillDirection.Horizontal,
                FillDirectionMaxCells = 2,
                SortOrder = Enum.SortOrder.LayoutOrder,
                StartCorner = Enum.StartCorner.TopLeft,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            }),

            TowerUnitCategory = Roact.createElement(IconButton, {
                Text = "Tower Unit",
                Image = "",
                LayoutOrder = 1,
                
                onActivated = function()
                    if (category == GameEnum.UnitType.TowerUnit) then return end

                    self:setState({
                        category = GameEnum.UnitType.TowerUnit,
                    })
                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),

            FieldUnitCategory = Roact.createElement(IconButton, {
                Text = "Field Unit",
                Image = "",
                LayoutOrder = 2,
                
                onActivated = function()
                    if (category == GameEnum.UnitType.FieldUnit) then return end

                    self:setState({
                        category = GameEnum.UnitType.FieldUnit,
                    })
                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),

            SpecialCategory = Roact.createElement(IconButton, {
                Text = "Special",
                Image = "",
                LayoutOrder = 3,
                
                onActivated = function()
                    if (category == GameEnum.ItemType.SpecialAction) then return end

                    self:setState({
                        category = GameEnum.ItemType.SpecialAction,
                    })
                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),
        }),

        InventoryPage = Roact.createElement(pageElements[category], {
            unitType = (category ~= GameEnum.ItemType.SpecialAction) and category or nil,

            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 1, -(72 + Style.Constants.MajorElementPadding)),
            Position = UDim2.new(0.5, 0, 1, 0),
        }),
    })
end

return GameInventory