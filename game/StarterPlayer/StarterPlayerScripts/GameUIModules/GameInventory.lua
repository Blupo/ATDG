-- todo: ui should update when upgrading

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local IconButton = require(root:WaitForChild("IconButton"))
local ObjectViewport = require(root:WaitForChild("ObjectViewport"))
local Padding = require(root:WaitForChild("Padding"))
local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))
local SpecialActions = SystemCoordinator.waitForSystem("SpecialActions")

---

local Inventory = Roact.Component:extend("Inventory")

Inventory.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)

    self.updateObjectList = function()
        local objectList = {}
        local category = self.state.category

        if ((category == GameEnum.UnitType.TowerUnit) or (category == GameEnum.UnitType.FieldUnit)) then
            local objectListDictionary = PlayerData.GetPlayerObjectGrants(LocalPlayer.UserId)

            for name in pairs(objectListDictionary[GameEnum.ObjectType.Unit]) do
                if (Unit.GetUnitType(name) == category) then
                    table.insert(objectList, name)
                end
            end
        elseif (category == GameEnum.ItemType.SpecialAction) then
            objectList = PlayerData.GetPlayerInventory(LocalPlayer.UserId)[category]
        elseif (category == GameEnum.ObjectType.Roadblock) then
            -- todo?
        end

        table.sort(objectList, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        self:setState({
            objects = objectList,
        })
    end

    self:setState({
        category = GameEnum.UnitType.TowerUnit,
        objects = {},

        placementFlowOpen = false,
        open = false,
    })
end

Inventory.didMount = function(self)
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

    self.updateObjectList()
end

Inventory.willUnmount = function(self)
    self.placementFlowStarted:Disconnect()
    self.placementFlowStopped:Disconnect()
end

Inventory.didUpdate = function(self, _, prevState)
    local category = self.state.category
    if (category == prevState.category) then return end

    self.updateObjectList()
end

Inventory.render = function(self)
    if (self.state.placementFlowOpen) then return nil end

    local isOpen = self.state.open
    local category = self.state.category
    local objectType

    if (category == GameEnum.UnitType.TowerUnit) or (category == GameEnum.UnitType.FieldUnit) then
        objectType = GameEnum.ObjectType.Unit
    else
        objectType = category
    end

    local objects = self.state.objects
    local selectedName = self.state.name
    local objectListChildren = {}
    local attributesPreviewChildren = {}

    if ((category == GameEnum.UnitType.TowerUnit) or (category == GameEnum.UnitType.FieldUnit)) then
        for i = 1, #objects do
            local objectName = objects[i]

            objectListChildren[objectName] = Roact.createElement(ObjectViewport, {
                LayoutOrder = i,

                objectType = GameEnum.ObjectType.Unit,
                objectName = objectName,

                showLevel = true,
                titleDisplayType = GameEnum.ObjectViewportTitleType.ObjectName,

                onActivated = function()
                    self:setState({
                        name = objectName,
                    })
                end,

                onMouseEnter = function() end,
                onMouseLeave = function() end,
            })
        end
    elseif (category == GameEnum.ItemType.SpecialAction) then
        for actionName, quantity in pairs(objects) do
            objectListChildren[actionName] = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 72),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())
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

                    Text = PlayerData.GetPlayerInventoryItemCount(LocalPlayer.UserId, category, actionName) or "?",
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
                            local result = SpecialActions.UseSpecialAction(LocalPlayer.UserId, actionName)

                            print(result.FailureReason)
                        end,
                    }, {
                        UICorner = Roact.createElement("UICorner", {
                            CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius),
                        }),
                    }),

                    BuyButton = Roact.createElement("TextButton", {
                        Size = UDim2.new(0, 70, 0, 24),
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        LayoutOrder = 1,

                        Text = "Buy (" .. (Shop.GetItemPrice(GameEnum.ItemType.SpecialAction, actionName) or "?") .. ")",
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextYAlignment = Enum.TextYAlignment.Center,

                        BackgroundColor3 = Color3.new(1, 1, 1),
                        TextColor3 = Color3.new(0, 0, 0),

                        [Roact.Event.Activated] = function()
                            Shop.PurchaseItem(LocalPlayer.UserId, category, actionName)
                        end,
                    }, {
                        UICorner = Roact.createElement("UICorner", {
                            CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius),
                        }),
                    }),
                }),
            })
        end
    elseif (category == GameEnum.ObjectType.Roadblock) then
        -- todo?
    end

    if (selectedName) then
        if ((category == GameEnum.UnitType.TowerUnit) or (category == GameEnum.UnitType.FieldUnit)) then
            local attributes = Unit.GetUnitBaseAttributes(selectedName, Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, selectedName))
            local previewAttributes = PreviewAttributes[category]

            for i = 1, #previewAttributes do
                local attribute = previewAttributes[i]
                local value = attributes[attribute]

                if (tonumber(value) and (attribute ~= "MaxHP")) then
                    value = string.format("%0.2f", value)
                elseif (attribute == "PathType") then
                    if (value == GameEnum.PathType.Ground) then
                        value = "G"
                    elseif (value == GameEnum.PathType.Air) then
                        value = "A"
                    elseif (value == GameEnum.PathType.GroundAndAir) then
                        value = "GA"
                    end
                end

                attributesPreviewChildren[i] = Roact.createElement("Frame", {
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
            
                        Text = value,
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
        elseif (category == GameEnum.ItemType.SpecialAction) then
            -- Special Actions don't have stats
        elseif (category == GameEnum.ObjectType.Roadblock) then
            -- todo?
        end

        attributesPreviewChildren.UIGridLayout = Roact.createElement("UIGridLayout", {
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

    if (category ~= GameEnum.ItemType.SpecialAction) then
        objectListChildren.UIGridLayout = Roact.createElement("UIGridLayout", {
            CellPadding = UDim2.new(0, 8, 0, 8),
            CellSize = UDim2.new(0, Style.Constants.ObjectViewportFrameSize, 0, Style.Constants.ObjectViewportFrameSize),

            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = 3,
            SortOrder = Enum.SortOrder.LayoutOrder,
            StartCorner = Enum.StartCorner.TopLeft,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updateListLength(obj.AbsoluteContentSize.Y)
            end
        })
    else
        objectListChildren.UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.Constants.MinorElementPadding),

            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.Name,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,

            [Roact.Change.AbsoluteContentSize] = function(obj)
                self.updateListLength(obj.AbsoluteContentSize.Y)
            end
        })
    end

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
                        name = Roact.None,
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
                        name = Roact.None,
                    })
                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),

            RoadblockCategory = Roact.createElement(IconButton, {
                Text = "Roadblock",
                Image = "",
                LayoutOrder = 3,
                
                onActivated = function()
                    -- todo?
                    print("future version?")
                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),

            SpecialCategory = Roact.createElement(IconButton, {
                Text = "Special",
                Image = "",
                LayoutOrder = 4,
                
                onActivated = function()
                    if (category == GameEnum.ItemType.SpecialAction) then return end

                    self:setState({
                        category = GameEnum.ItemType.SpecialAction,
                        name = Roact.None,
                    })
                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),
        }),

        SelectedObjectInfo = selectedName and
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

                        Text = Shop.GetObjectPlacementPrice(objectType, selectedName) or "?",
                        Image = "rbxassetid://6837004068",

                        onActivated = function()

                            if (category == GameEnum.UnitType.TowerUnit) then
                                -- todo: check for available funds first
                                PlacementFlow.Start(objectType, selectedName)

                                self:setState({
                                    name = Roact.None,
                                })
                            elseif (category == GameEnum.UnitType.FieldUnit) then
                                -- todo
                                print("todo")
                            elseif (category == GameEnum.ObjectType.Roadblock) then
                                -- todo?
                                print("future version?")
                            end
                        end,

                        ImageColor3 = Color3.new(0, 0, 0),
                    }),

                    PersistentUpgradeButton = (objectType == GameEnum.ObjectType.Unit) and
                        Roact.createElement(IconButton, {
                            AnchorPoint = Vector2.new(0.5, 1),
                            Size = UDim2.new(1, 0, 0.5, -Style.Constants.MinorElementPadding / 2),
                            Position = UDim2.new(0.5, 0, 1, 0),
                            LayoutOrder = 2,

                            Text = Shop.GetUnitPersistentUpgradePrice(LocalPlayer.UserId, selectedName) or "MAX",
                            Image = "rbxassetid://6837004663",

                            onActivated = function()
                                Shop.PurchaseUnitPersistentUpgrade(LocalPlayer.UserId, selectedName)
                            end,

                            ImageColor3 = Color3.new(0, 0, 0),
                        })
                    or nil,
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

                        Text = selectedName .. " (" .. Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, selectedName) .. ")",
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
                    }, attributesPreviewChildren)
                })
            })
        or nil,

        ObjectList = Roact.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, -((72 * 2) + (Style.Constants.MajorElementPadding * 2))),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            CanvasSize = self.listLength:map(function(length)
                return UDim2.new(0, 0, 0, length)
            end)
        }, objectListChildren)
    })
end

return Inventory