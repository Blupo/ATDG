local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent

local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))
local UnitViewport = require(root:WaitForChild("UnitViewport"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

---

local HOTBAR_ITEMS = 5 -- replace this later

local Hotbar = Roact.PureComponent:extend("Hotbar")

Hotbar.init = function(self)
    self:setState({
        hoverUnitName = nil,
    })
end

Hotbar.render = function(self)
    local unitListChildren = {}

    for i = 1, HOTBAR_ITEMS do
        unitListChildren[i] = Roact.createElement(UnitViewport, {
            -- todo
            unitName = "TestTowerUnit",
            showLevel = false,
            showHotkey = true,
            titleDisplayType = GameEnum.UnitViewportTitleType.PlacementPrice,

            onMouseEnter = function()
                -- todo
                self:setState({
                    hoverUnitName = "todo",
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

    unitListChildren["UIListLayout"] = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.Constants.MinorElementPadding),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(0, (Style.Constants.UnitViewportFrameSize * HOTBAR_ITEMS) + (Style.Constants.MinorElementPadding * (HOTBAR_ITEMS - 1)), 0, Style.Constants.UnitViewportFrameSize + Style.Constants.MajorElementPadding + 24),
        Position = UDim2.new(0.5, 0, 1, -(32 + Style.Constants.MajorElementPadding)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        StatsPreview = self.state.hoverUnitName and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 24),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.new(1, 1, 1),
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                })
            })
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