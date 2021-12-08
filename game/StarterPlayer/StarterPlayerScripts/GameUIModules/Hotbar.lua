local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Unit = require(GameModules:WaitForChild("Unit"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local StatListItem = require(GameUIModules:WaitForChild("StatListItem"))
local Style = require(GameUIModules:WaitForChild("Style"))
local UnitFrame = require(GameUIModules:WaitForChild("UnitFrame"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local FormatAttribute = require(PlayerModules:WaitForChild("FormatAttribute"))
local PreviewAttributes = require(PlayerModules:WaitForChild("PreviewAttributes"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding

---

local KEYS = { "One", "Two", "Three", "Four", "Five" }

local PlacementFlow
local ServerMaster = SystemCoordinator.waitForSystem("ServerMaster")

local serverType = ServerMaster.GetServerType() or ServerMaster.ServerInitialised:Wait()
local serverIsGame = (serverType == GameEnum.ServerType.Game)

if (serverIsGame) then
    PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))
end

---

local Hotbar = Roact.PureComponent:extend("Hotbar")

Hotbar.init = function(self)
    if (serverIsGame) then
        self.unbindHotkeys = function()
            for i = 1, #KEYS do
                ContextActionService:UnbindAction("Hotbar " .. i)
            end
        end

        self.bindHotkeys = function(hotbar)
            hotbar = hotbar or self.state.hotbars[self.state.hotbarObjectType]

            for i = 1, #KEYS do
                local unit = hotbar[i]
                
                if (unit) then
                    ContextActionService:BindAction("Hotbar " .. i, function(_, inputState)
                        if (inputState ~= Enum.UserInputState.Begin) then return end
                        if (self.state.placementFlowOpen) then return end
            
                        PlacementFlow.Start(unit)
                    end, false, Enum.KeyCode[KEYS[i]])
                end
            end
        end

        self.rebindHotkeys = function()
            self.unbindHotkeys()
            self.bindHotkeys()
        end
    end

    self:setState({
        hotbars = {
            [GameEnum.UnitType.TowerUnit] = {},
            [GameEnum.UnitType.FieldUnit] = {},
        },

        hotbarObjectType = GameEnum.UnitType.TowerUnit,
        placementFlowOpen = false,
    })
end

Hotbar.didMount = function(self)
    if (serverIsGame) then
        self.placementFlowStarted = PlacementFlow.Started:Connect(function()
            self:setState({
                placementFlowOpen = true,
            })

            self.unbindHotkeys()
        end)

        self.placementFlowStopped = PlacementFlow.Stopped:Connect(function()
            self:setState({
                placementFlowOpen = false,
            })

            self.bindHotkeys()
        end)
    end

    self.hotbarChanged = PlayerData.HotbarChanged:Connect(function(_, hotbarType: string, newHotbar: {[number]: string})
        local hotbarsCopy = CopyTable(self.state.hotbars)
        hotbarsCopy[hotbarType] = newHotbar

        self:setState({
            hotbars = hotbarsCopy,
            hoveredObject = Roact.None,
        })

        if (serverIsGame) then
            self.rebindHotkeys()
        end
    end)

    local hotbars = PlayerData.GetPlayerHotbars(LocalPlayer.UserId)

    self:setState({
        hotbars = hotbars
    })

    if (serverIsGame) then
        self.bindHotkeys(hotbars[self.state.hotbarObjectType])
    end
end

Hotbar.willUnmount = function(self)
    if (self.placementFlowStarted) then
        self.placementFlowStarted:Disconnect()
    end

    if (self.placementFlowStopped) then
        self.placementFlowStopped:Disconnect()
    end

    self.hotbarChanged:Disconnect()

    if (serverIsGame) then
        self.unbindHotkeys()
    end
end

Hotbar.willUpdate = function(self, _, prevState)
    if (serverIsGame and (self.state.hotbarObjectType ~= prevState.hotbarObjectType)) then
        self.rebindHotkeys()
    end
end

Hotbar.render = function(self)
    if (self.state.placementFlowOpen) then return end

    local hotbars = self.state.hotbars
    local hotbarObjectType = self.state.hotbarObjectType
    local hotbar = hotbars[hotbarObjectType]

    local numHotbarItems = #hotbar
    local frameWidth = (Style.Constants.InventoryFrameButtonSize * numHotbarItems) + (Style.Constants.MajorElementPadding * (numHotbarItems - 1))
    local hoveredObject = self.state.hoveredObject

    local hotbarListElements = {}
    local hoveredUnitAttributeListElements = {}

    for i = 1, numHotbarItems do
        local objectName = hotbar[i]

        hotbarListElements[objectName] = Roact.createElement(UnitFrame, {
            LayoutOrder = i,

            unitName = objectName,
            subtextDisplayType = "UnitName",
            hoverSubtextDisplayType = "PlacementCost",

            onActivated = function()
                if (serverType == GameEnum.ServerType.Game) then
                    -- TODO: check for available funds first

                    PlacementFlow.Start(objectName)
                elseif (serverType == GameEnum.ServerType.Lobby) then
                    local newHotbar = CopyTable(hotbar)
                    table.remove(newHotbar, i)

                    PlayerData.SetPlayerHotbar(LocalPlayer.UserId, hotbarObjectType, newHotbar)
                end
            end,

            onMouseEnter = function()
                self:setState({
                    hoveredObject = objectName
                })
            end,

            onMouseLeave = function()
                self:setState({
                    hoveredObject = Roact.None
                })
            end,
        })
    end

    hotbarListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),
        FillDirection = Enum.FillDirection.Horizontal,
    })

    if (hoveredObject) then
        local attributes = Unit.GetUnitBaseAttributes(hoveredObject, 1)
        local previewAttributes = PreviewAttributes[hotbarObjectType]
        local numPreviewAttributes = #previewAttributes

        for i = 1, #previewAttributes do
            local attribute = previewAttributes[i]
            local attributeValue = FormatAttribute(attribute, attributes[attribute])

            hoveredUnitAttributeListElements[i] = Roact.createElement(StatListItem, {
                Size = UDim2.new(1 / numPreviewAttributes, -Style.Constants.SpaciousElementPadding + (Style.Constants.SpaciousElementPadding / numPreviewAttributes), 1, 0),
                LayoutOrder = i,

                Text = attributeValue,
                TextXAlignment = Enum.TextXAlignment.Center,
                Image = Style.Images[attribute .. "AttributeIcon"],

                ImageColor3 = Style.Colors[attribute .. "AttributeIconColor"]
            })
        end

        hoveredUnitAttributeListElements.UIPadding = Roact.createElement(StandardUIPadding)
        hoveredUnitAttributeListElements.UICorner = Roact.createElement(StandardUICorner)

        hoveredUnitAttributeListElements.UIListLayout = Roact.createElement(StandardUIListLayout, {
            FillDirection = Enum.FillDirection.Horizontal,
        })
    end

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -(32 + Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding + Style.Constants.MajorElementPadding)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Size = UDim2.new(1, 0, 0,
            Style.Constants.InventoryFrameButtonSize +
            Style.Constants.StandardButtonHeight +
            Style.Constants.StandardIconSize +
            Style.Constants.MinorElementPadding +
            (Style.Constants.SpaciousElementPadding * 2)
        ),
    }, {
        HotbarList = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(0, frameWidth, 0, Style.Constants.InventoryFrameButtonSize + Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
        }, hotbarListElements),

        HoveredUnitInfo = (hoveredObject) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BorderSizePixel = 0,

                Size = UDim2.new(
                    0, (Style.Constants.InventoryFrameButtonSize * 5) + (Style.Constants.MajorElementPadding * 4),
                    0, Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding
                ),

                BackgroundColor3 = Color3.new(1, 1, 1),
            }, hoveredUnitAttributeListElements)
        or nil,
    })
end

return Hotbar