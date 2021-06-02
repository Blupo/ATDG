local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent
local PlayerScripts = root.Parent

local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))
local UnitViewport = require(root:WaitForChild("UnitViewport"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

---

local HOTBAR_ITEMS = 5 -- replace this later

local attr = {"DMG", "RANGE", "CD", "PathType"}

local Hotbar = Roact.PureComponent:extend("Hotbar")

Hotbar.init = function(self)
    self:setState({
        hoverUnitName = nil,
    })
end

Hotbar.render = function(self)
    local unitListChildren = {}
    local statPreviewChildren = {}

    for i = 1, HOTBAR_ITEMS do
        unitListChildren[i] = Roact.createElement(UnitViewport, {
            LayoutOrder = i,

            -- todo
            unitName = "TestTowerUnit",
            showLevel = false,
            showHotkey = true,
            titleDisplayType = GameEnum.UnitViewportTitleType.PlacementPrice,

            onActivated = function()
                print("e")
            end,

            onMouseEnter = function()
                -- todo
                self:setState({
                    hoverUnitName = "TestTowerUnit",
                })
            end,

            onMouseLeave = function()
                -- todo
                self:setState({
                    hoverUnitName = Roact.None,
                })
            end
        })
    end

    if (self.state.hoverUnitName) then
        -- todo: distinguish between tower/field/roadblock
        local hoverUnitAttributes = Unit.GetUnitBaseAttributes(self.state.hoverUnitName, 1)

        for i = 1, 4 do
            statPreviewChildren[i] = Roact.createElement("Frame", {
                Size = UDim2.new(0, 80, 1, 0),
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
        
                    Text = hoverUnitAttributes[attr[i]],
                    Font = Enum.Font.GothamBold,
                    TextSize = 16,
                    TextStrokeTransparency = 1,

                    TextColor3 = Color3.new(0, 0, 0)
                })
            })
        end

        statPreviewChildren["UICorner"] = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
        })

        statPreviewChildren["UIListLayout"] = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.Constants.MajorElementPadding),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })
    end

    unitListChildren["UIListLayout"] = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.Constants.MinorElementPadding),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(0, (Style.Constants.UnitViewportFrameSize * HOTBAR_ITEMS) + (Style.Constants.MinorElementPadding * (HOTBAR_ITEMS - 1)), 0, Style.Constants.UnitViewportFrameSize + Style.Constants.MajorElementPadding + 32),
        Position = UDim2.new(0.5, 0, 1, -(32 + Style.Constants.MajorElementPadding)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        StatsPreview = self.state.hoverUnitName and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.new(1, 1, 1),
            }, statPreviewChildren)
        or nil,

        UnitList = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0, Style.Constants.UnitViewportFrameSize),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, unitListChildren)
    })
end

---

return Hotbar