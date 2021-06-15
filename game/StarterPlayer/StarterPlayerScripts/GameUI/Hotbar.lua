local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent
local PlayerScripts = root.Parent

local ObjectViewport = require(root:WaitForChild("ObjectViewport"))
local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlacementFlow = require(GameModules:WaitForChild("PlacementFlow"))
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Unit = require(GameModules:WaitForChild("Unit"))

local LocalPlayer = Players.LocalPlayer

---

local HOTBAR_ATTRIBUTES = {
    [GameEnum.ObjectType.Unit] = {
        [GameEnum.UnitType.TowerUnit] = {"DMG", "RANGE", "CD", "PathType"},
        [GameEnum.UnitType.FieldUnit] = {"HP", "DEF", "SPD", "PathType"}
    },

    [GameEnum.ObjectType.Roadblock] = {} -- todo
}

local attr = {"DMG", "RANGE", "CD", "PathType"}

local Hotbar = Roact.PureComponent:extend("Hotbar")

Hotbar.init = function(self)
    self:setState({
        hotbars = {
            [GameEnum.ObjectType.Unit] = {
                [GameEnum.UnitType.TowerUnit] = {},
                [GameEnum.UnitType.FieldUnit] = {},
            },

            [GameEnum.ObjectType.Roadblock] = {},
        },

        hotbarObjectType = GameEnum.ObjectType.Unit,
        hotbarObjectSubtype = GameEnum.UnitType.TowerUnit,

        hoverUnitName = nil,
        placementFlowOpen = false,
    })
end

Hotbar.didMount = function(self)
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

    self.hotbarChanged = PlayerData.HotbarChanged:Connect(function(_, objectType, subType, newHotbar)
        local hotbarsCopy = CopyTable(self.state.hotbars)

        if (subType) then
            hotbarsCopy[objectType][subType] = newHotbar
        else
            hotbarsCopy[objectType] = newHotbar
        end

        self:setState({
            hotbars = hotbarsCopy
        })
    end)

    self:setState({
        hotbars = PlayerData.GetPlayerHotbars(LocalPlayer.UserId)
    })
end

Hotbar.willUnmount = function(self)
    self.placementFlowStarted:Disconnect()
    self.placementFlowStopped:Disconnect()
end

Hotbar.render = function(self)
    if (self.state.placementFlowOpen) then return nil end

    local hotbars = self.state.hotbars
    local objectType = self.state.hotbarObjectType
    local subType = self.state.hotbarObjectSubtype
        
    local hotbarListChildren = {}
    local statPreviewChildren = {}

    local hotbar
    local hotbarItemCount

    if (subType) then
        hotbar = hotbars[objectType][subType]
    else
        hotbar = hotbars[objectType]
    end

    hotbarItemCount = #hotbar

    for i = 1, hotbarItemCount do
        local objectName = hotbar[i]

        hotbarListChildren[i] = Roact.createElement(ObjectViewport, {
            LayoutOrder = i,

            -- todo
            objectType = objectType,
            objectName = objectName,

            infoLeftDisplay = "Hotkey",
            hotkey = i,

            showLevel = false,
            titleDisplayType = GameEnum.ObjectViewportTitleType.PlacementPrice,

            onActivated = function()
                -- check for available funds first
                
                PlacementFlow.Start(objectType, objectName)
            end,

            onMouseEnter = function() end,
            onMouseLeave = function() end
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
                    Font = Style.Constants.MainFont,
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

    hotbarListChildren["UIListLayout"] = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.Constants.MinorElementPadding),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(0, (Style.Constants.ObjectViewportFrameSize * hotbarItemCount) + (Style.Constants.MinorElementPadding * (hotbarItemCount - 1)), 0, Style.Constants.ObjectViewportFrameSize + Style.Constants.MajorElementPadding + 32),
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

        HotbarList = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0, Style.Constants.ObjectViewportFrameSize),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, hotbarListChildren)
    })
end

---

return Hotbar