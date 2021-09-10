local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))
local UnitViewport = require(root:WaitForChild("UnitViewport"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))
local PlacementFlow

local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")

---

local HOTBAR_MAX_ITEMS = 5

local serverType = ServerMaster.GetServerType() or ServerMaster.ServerInitialised:Wait()

if (serverType == GameEnum.ServerType.Game) then
    PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))
end

---

local Hotbar = Roact.PureComponent:extend("Hotbar")

Hotbar.init = function(self)
    self:setState({
        hotbars = {
            [GameEnum.UnitType.TowerUnit] = {},
            [GameEnum.UnitType.FieldUnit] = {},
        },

        hotbarObjectType = GameEnum.UnitType.TowerUnit,
        hoverObjectName = nil,

        placementFlowOpen = false,
    })
end

Hotbar.didMount = function(self)
    if (serverType == GameEnum.ServerType.Game) then
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

    self.hotbarChanged = PlayerData.HotbarChanged:Connect(function(_, hotbarType: string, newHotbar: {[number]: string})
        local hotbarsCopy = CopyTable(self.state.hotbars)
        hotbarsCopy[hotbarType] = newHotbar

        self:setState({
            hotbars = hotbarsCopy
        })
    end)

    self:setState({
        hotbars = PlayerData.GetPlayerHotbars(LocalPlayer.UserId)
    })
end

Hotbar.willUnmount = function(self)
    if (self.placementFlowStarted) then
        self.placementFlowStarted:Disconnect()
    end

    if (self.placementFlowStopped) then
        self.placementFlowStopped:Disconnect()
    end

    self.hotbarChanged:Disconnect()
end

Hotbar.render = function(self)
    if (self.state.placementFlowOpen) then return nil end

    local hotbars = self.state.hotbars
    local hotbarObjectType = self.state.hotbarObjectType
    local hotbar = hotbars[hotbarObjectType]

    local hotbarListChildren = {}
    local attributesPreviewChildren = {}

    for i = 1, #hotbar do
        local objectName = hotbar[i]

        hotbarListChildren[objectName] = Roact.createElement(UnitViewport, {
            LayoutOrder = i,
            BackgroundColor3 = Color3.new(1, 1, 1),

            unitName = objectName,
            showHotkey = true,
            titleDisplayType = "PlacementPrice",

            onActivated = function()
                if (serverType == GameEnum.ServerType.Game) then
                    -- todo: check for available funds first

                    PlacementFlow.Start(GameEnum.ObjectType.Unit, objectName)
                elseif (serverType == GameEnum.ServerType.Lobby) then
                    local newHotbar = CopyTable(hotbar)
                    table.remove(newHotbar, i)

                    PlayerData.SetPlayerHotbar(LocalPlayer.UserId, hotbarObjectType, newHotbar)
                end
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
        local attributes = Unit.GetUnitBaseAttributes(self.state.hoverObjectName, 1)
        local previewAttributes = PreviewAttributes[hotbarObjectType]

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

        Size = UDim2.new(
            0, (Style.Constants.UnitViewportFrameSize * HOTBAR_MAX_ITEMS) + (Style.Constants.MinorElementPadding * (HOTBAR_MAX_ITEMS - 1)),
            0, Style.Constants.UnitViewportFrameSize + Style.Constants.MajorElementPadding + 32
        ),

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
            Size = UDim2.new(1, 0, 0, Style.Constants.UnitViewportFrameSize),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, hotbarListChildren)
    })
end

---

return Hotbar