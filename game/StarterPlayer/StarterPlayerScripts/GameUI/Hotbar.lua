local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local ObjectViewport = require(root:WaitForChild("ObjectViewport"))
local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

---

local Hotbar = Roact.PureComponent:extend("Hotbar")

Hotbar.init = function(self)
    self:setState({
        hotbars = {
            [GameEnum.UnitType.TowerUnit] = {},
            [GameEnum.UnitType.FieldUnit] = {},
            [GameEnum.ObjectType.Roadblock] = {},
        },

        hotbarObjectType = GameEnum.UnitType.TowerUnit,
        hoverObjectName = nil,

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

    self.hotbarChanged = PlayerData.HotbarChanged:Connect(function(_, objectType, newHotbar)
        local hotbarsCopy = CopyTable(self.state.hotbars)
        hotbarsCopy[objectType] = newHotbar

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
    local hotbarObjectType = self.state.hotbarObjectType
    local objectType = (hotbarObjectType == GameEnum.ObjectType.Roadblock) and GameEnum.ObjectType.Roadblock or GameEnum.ObjectType.Unit
        
    local hotbarListChildren = {}
    local attributesPreviewChildren = {}

    local hotbar = hotbars[hotbarObjectType]
    local hotbarItemCount = #hotbar

    for i = 1, hotbarItemCount do
        local objectName = hotbar[i]

        hotbarListChildren[i] = Roact.createElement(ObjectViewport, {
            LayoutOrder = i,
            BackgroundColor3 = Color3.new(1, 1, 1),

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

            onMouseEnter = function()
                self:setState({
                    hoverObjectName = objectName
                })
            end,

            onMouseLeave = function()
                self:setState({
                    hoverObjectName = Roact.None
                })
            end,
        })
    end

    if (self.state.hoverObjectName) then
        -- todo: roadblocks
        local attributes = Unit.GetUnitBaseAttributes(self.state.hoverObjectName, 1)
        local previewAttributes = PreviewAttributes[hotbarObjectType]

        for i = 1, #previewAttributes do
            local attribute = previewAttributes[i]
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

            attributesPreviewChildren[i] = Roact.createElement("Frame", {
                Size = UDim2.new(0, 80, 1, 0),
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

        attributesPreviewChildren.UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
        })

        attributesPreviewChildren.UIListLayout = Roact.createElement("UIListLayout", {
            Padding = UDim.new(0, Style.Constants.MajorElementPadding),
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })
    end

    hotbarListChildren.UIListLayout = Roact.createElement("UIListLayout", {
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
        AttributesPreview = self.state.hoverObjectName and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, 0, 0, 32),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.new(1, 1, 1),
            }, attributesPreviewChildren)
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