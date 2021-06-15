local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent
local PlayerScripts = root.Parent

local IconButton = require(root:WaitForChild("IconButton"))
local ObjectViewport = require(root:WaitForChild("ObjectViewport"))
local Padding = require(root:WaitForChild("Padding"))
local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlacementFlow = require(GameModules:WaitForChild("PlacementFlow"))
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))

local LocalPlayer = Players.LocalPlayer

---
local QUICK_ATTRIBUTES = {
    [GameEnum.ObjectType.Unit] = {
        [GameEnum.UnitType.TowerUnit] = {"DMG", "RANGE", "CD", "PathType"},
        [GameEnum.UnitType.FieldUnit] = {"HP", "DEF", "SPD", "PathType"}
    },

    [GameEnum.ObjectType.Roadblock] = {} -- todo
}


local Inventory = Roact.Component:extend("Inventory")

Inventory.init = function(self)
    self.updateObjectList = function()
        local objectList = {}

        if (self.state.category == GameEnum.UnitType.TowerUnit) then
            local objectListDictionary = PlayerData.GetPlayerObjectGrants(LocalPlayer.UserId)

            for name in pairs(objectListDictionary[GameEnum.ObjectType.Unit]) do
                table.insert(objectList, name)
            end
        else
            -- todo
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
    local statsChildren = {}

    if (category == GameEnum.UnitType.TowerUnit) then
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
    else
        -- todo
    end

    if (selectedName) then
        if ((category == GameEnum.UnitType.TowerUnit) or (category == GameEnum.UnitType.FieldUnit)) then
            local attributes = Unit.GetUnitBaseAttributes(selectedName, Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, selectedName))
            -- badness: remove async call

            local shownAttributes = QUICK_ATTRIBUTES[GameEnum.ObjectType.Unit][category]

            for i = 1, #shownAttributes do
                local attribute = shownAttributes[i]
                local value = attributes[attribute]

                if ((attribute ~= "HP") and tonumber(value)) then
                    value = string.format("%0.2f", value)
                elseif (value == GameEnum.PathType.Ground) then
                    value = "G"
                elseif (value == GameEnum.PathType.Air) then
                    value = "A"
                elseif (value == GameEnum.PathType.GroundAndAir) then
                    value = "GA"
                end

                statsChildren[i] = Roact.createElement("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                }, {
                    Icon = Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.new(0, 28, 0, 28),
                        Position = UDim2.new(0, 2, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", -- todo
    
                        ImageColor3 = Color3.new(1, 1, 1) -- todo
                    }),
            
                    Label = Roact.createElement("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(1, -36, 0, 0),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
            
                        Text = value,
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextStrokeTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
    
                        TextColor3 = Color3.new(0, 0, 0)
                    })
                })
            end
        elseif (category == GameEnum.ObjectType.Roadblock) then
        else
            -- wat
        end

        statsChildren.UIGridLayout = Roact.createElement("UIGridLayout", {
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

    objectListChildren.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellPadding = UDim2.new(0, 8, 0, 8),
        CellSize = UDim2.new(0, Style.Constants.ObjectViewportFrameSize, 0, Style.Constants.ObjectViewportFrameSize),

        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 2,
        SortOrder = Enum.SortOrder.LayoutOrder,
        StartCorner = Enum.StartCorner.TopLeft,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Size = UDim2.new(0, 310, 0, 420),
        Position = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,

        BackgroundColor3 = Color3.new(1, 1, 1)
    }, {
        UIPadding = Roact.createElement(Padding, {Style.Constants.MajorElementPadding}),

        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius),
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

                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),

            FieldUnitCategory = Roact.createElement(IconButton, {
                Text = "Field Unit",
                Image = "",
                LayoutOrder = 2,
                
                onActivated = function()

                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),

            RoadblockCategory = Roact.createElement(IconButton, {
                Text = "Roadblock",
                Image = "",
                LayoutOrder = 3,
                
                onActivated = function()

                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),

            SpecialCategory = Roact.createElement(IconButton, {
                Text = "Special",
                Image = "",
                LayoutOrder = 4,
                
                onActivated = function()

                end,

                ImageColor3 = Color3.new(0, 0, 0),
            }),
        }),

        SelectedObjectInfo = self.state.name and
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

                        Text = ShopPrices.ObjectPlacementPrices[objectType][selectedName],
                        Image = "rbxassetid://6837004068",

                        onActivated = function()
                            -- check for available funds first
                            PlacementFlow.Start(objectType, selectedName)

                            self:setState({
                                name = Roact.None,
                            })
                        end,

                        ImageColor3 = Color3.new(0, 0, 0),
                    }),

                    PersistentUpgradeButton = Roact.createElement(IconButton, {
                        AnchorPoint = Vector2.new(0.5, 1),
                        Size = UDim2.new(1, 0, 0.5, -Style.Constants.MinorElementPadding / 2),
                        Position = UDim2.new(0.5, 0, 1, 0),
                        LayoutOrder = 2,

                        Text = "",
                        Image = "rbxassetid://6837004663",

                        onActivated = function()

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

                        Text = selectedName .. " (" .. Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, selectedName) .. ")",
                        Font = Style.Constants.MainFont,
                        TextSize = 16,
                        TextStrokeTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,

                        TextColor3 = Color3.new(0, 0, 0)
                    }),

                    Stats = Roact.createElement("Frame", {
                        AnchorPoint = Vector2.new(0.5, 1),
                        Size = UDim2.new(1, 0, 1, -(16 + Style.Constants.MinorElementPadding)),
                        Position = UDim2.new(0.5, 0, 1, 0),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                    }, statsChildren)
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
        }, objectListChildren)
    })
end

return Inventory