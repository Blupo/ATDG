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
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))

---

local Inventory = Roact.Component:extend("Inventory")

Inventory.init = function(self)
    
end

Inventory.render = function(self)
    local stat

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

        SelectedObjectInfo = Roact.createElement("Frame", {
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

                    Text = "",
                    Image = "rbxassetid://6837004068",

                    onActivated = function()

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

                    Text = "Object Name (LVL)",
                    Font = Style.Constants.MainFont,
                    TextSize = 16,
                    TextStrokeTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,

                    TextColor3 = Color3.new(0, 0, 0)
                }),

                Stats = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, -(16 + Style.Constants.MinorElementPadding)),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, {
                    UIGridLayout = Roact.createElement("UIGridLayout", {
                        CellPadding = UDim2.new(0, 4, 0, 4),
                        CellSize = UDim2.new(0.5, -2, 0.5, -2),

                        FillDirection = Enum.FillDirection.Horizontal,
                        FillDirectionMaxCells = 2,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        StartCorner = Enum.StartCorner.TopLeft,
                        HorizontalAlignment = Enum.HorizontalAlignment.Left,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                    }),


                })
            })
        }),

        ObjectList = Roact.createElement("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, -((72 * 2) + (Style.Constants.MajorElementPadding * 2))),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            UIGridLayout = Roact.createElement("UIGridLayout", {
                CellPadding = UDim2.new(0, 8, 0, 8),
                CellSize = UDim2.new(0, Style.Constants.ObjectViewportFrameSize, 0, Style.Constants.ObjectViewportFrameSize),

                FillDirection = Enum.FillDirection.Horizontal,
                FillDirectionMaxCells = 2,
                SortOrder = Enum.SortOrder.LayoutOrder,
                StartCorner = Enum.StartCorner.TopLeft,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            })
        })
    })
end

return Inventory