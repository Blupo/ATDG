local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Padding = require(GameUIModules:WaitForChild("Padding"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

---

--[[
    props

    unitName: string

    showHotkey: boolean
    titleDisplayType: string<PlacementPrice|UnitName>
    rightInfoDisplayType: string<Level|Unlocked>?

    onActivated: () -> nil
    onMouseEnter: () -> nil
    onMouseLeave: () -> nil

    AnchorPoint?
    Position?
    LayoutOrder?
    BackgroundColor3?
]]

local UnitViewport = Roact.PureComponent:extend("UnitViewport")

UnitViewport.init = function(self)
    self.viewport = Roact.createRef()
    self.camera = Roact.createRef()

    self.initObjectModel = function()
        local unitName = self.props.unitName
        if (not unitName) then return end

        local objectModel = UnitModels:FindFirstChild(unitName)
        if (not objectModel) then return end

        objectModel = objectModel:Clone()
        objectModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))

        local orientation, boundingBoxSize = objectModel:GetBoundingBox()
        local viewport = self.viewport:getValue()

        if (viewport) then
            objectModel.Parent = viewport
        end

        self:setState({
            objectModel = objectModel,

            -- todo: make this look better
            cameraCFrame = orientation:ToWorldSpace(CFrame.new(0, 0, -math.max(boundingBoxSize.X, boundingBoxSize.Y)) * CFrame.Angles(0, math.pi, 0))
        })
    end

    self:setState({
        cameraCFrame = CFrame.new(0, 0, 0),

        unitLevel = 1,
        unitUnlocked = false,
    })
end

UnitViewport.didMount = function(self)
    self.unitLevelChanged = Unit.UnitPersistentUpgraded:Connect(function(_, unitName: string, newLevel: number)
        if (unitName ~= self.props.unitName) then return end

        self:setState({
            unitLevel = newLevel,
        })
    end)

    self.unitGranted = PlayerData.ObjectGranted:Connect(function(_, objectType: string, objectName: string)
        if (objectType ~= GameEnum.ObjectType.Unit) then return end
        if (objectName ~= self.props.unitName) then return end

        self:setState({
            unitUnlocked = true,
        })
    end)

    self.hotbarChanged = PlayerData.HotbarChanged:Connect(function(_, hotbarType: string, newHotbar: {[number]: string})
        local unitName = self.props.unitName
        local unitType = Unit.GetUnitType(unitName)
        if (hotbarType ~= unitType) then return end

        self:setState({
            hotbarKey = table.find(newHotbar, unitName) or Roact.None,
        })
    end)

    self.initObjectModel()
    
    local initUnitName = self.props.unitName
    local initUnitType = Unit.GetUnitType(initUnitName)
    local playerHotbar = PlayerData.GetPlayerHotbar(LocalPlayer.UserId, initUnitType)

    self:setState({
        unitLevel = Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, self.props.unitName),
        unitUnlocked = PlayerData.PlayerHasObjectGrant(LocalPlayer.UserId, GameEnum.ObjectType.Unit, self.props.unitName),
        hotbarKey = playerHotbar and table.find(playerHotbar, initUnitName) or nil,
    })
end

UnitViewport.didUpdate = function(self, prevProps)
    local unitName = self.props.unitName
    if (unitName == prevProps.unitName) then return end

    local unitType = Unit.GetUnitType(unitName)
    local playerHotbar = PlayerData.GetPlayerHotbar(LocalPlayer.UserId, unitType)

    self:setState({
        unitLevel = Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, self.props.unitName),
        unitUnlocked = PlayerData.PlayerHasObjectGrant(LocalPlayer.UserId, GameEnum.ObjectType.Unit, self.props.unitName),
        hotbarKey = playerHotbar and table.find(playerHotbar, unitName) or Roact.None,
    })

    self.initObjectModel()
end

UnitViewport.willUnmount = function(self)
    if (self.state.objectModel) then
        self.state.objectModel:Destroy()
    end

    self.unitLevelChanged:Disconnect()
    self.unitGranted:Disconnect()
    self.hotbarChanged:Disconnect()
end

UnitViewport.render = function(self)
    local unitName = self.props.unitName
    local showHotkey = self.props.showHotkey
    local rightInfoDisplayType = self.props.rightInfoDisplayType
    local titleDisplayType = self.props.titleDisplayType

    local titleText
    local rightInfoDisplay

    if (titleDisplayType == "PlacementPrice") then
        titleText = Shop.GetObjectPlacementPrice(GameEnum.ObjectType.Unit, unitName) or "?"
    elseif (titleDisplayType == "UnitName") then
        titleText = Unit.GetUnitDisplayName(unitName)
    else
        titleText = ""
    end

    if (rightInfoDisplayType == "Level") then
        rightInfoDisplay = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 2,

            Text = self.state.unitLevel,
            Font = Style.Constants.MainFont,
            TextSize = 16,

            BackgroundColor3 = Color3.new(1, 1, 1),
            TextColor3 = Color3.new(0, 0, 0)
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
            }),
        })
    elseif (rightInfoDisplayType == "Unlocked") then
        rightInfoDisplay = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,

            Image = self.state.unitUnlocked and "rbxassetid://6409085199" or "rbxassetid://6409084245",
            ImageColor3 = Color3.new(0, 0, 0)
        })
    end

    return Roact.createElement("TextButton", {
        AnchorPoint = self.props.AnchorPoint,
        Size = UDim2.new(0, Style.Constants.UnitViewportFrameSize, 0, Style.Constants.UnitViewportFrameSize),
        Position = self.props.Position,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = self.props.LayoutOrder,

        Text = "",
        TextTransparency = 1,
        TextStrokeTransparency = 1,

        BackgroundColor3 = self.props.BackgroundColor3 or Color3.new(0.85, 0.85, 0.85),

        [Roact.Event.Activated] = function()
            self.props.onActivated()
        end,
        
        [Roact.Event.MouseEnter] = function()
            if (not self.props.onMouseEnter) then return end

            self.props.onMouseEnter()
        end,

        [Roact.Event.MouseLeave] = function()
            if (not self.props.onMouseLeave) then return end

            self.props.onMouseLeave()
        end,
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
        }),

        UIPadding = Roact.createElement(Padding, {4}),
        
        Viewport = Roact.createElement("ViewportFrame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LightDirection = Vector3.new(0, 0, 0),
            CurrentCamera = self.camera,

            Ambient = Color3.new(1, 1, 1),
            LightColor = Color3.new(1, 1, 1),

            [Roact.Ref] = self.viewport,
        }, {
            Camera = Roact.createElement("Camera", {
                CFrame = self.state.cameraCFrame,

                [Roact.Ref] = self.camera,
            }),
        }),

        Title = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 1),
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,

            Text = titleText,
            Font = Style.Constants.MainFont,
            TextScaled = true,
            TextStrokeTransparency = 0.5,

            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1)
        }),

        Hotkey = (showHotkey) and
            Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,

                Text = self.state.hotbarKey or "",
                Font = Style.Constants.MainFont,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextSize = 16,
                TextStrokeTransparency = 0.5,

                TextColor3 = Color3.new(0, 0, 0),
                TextStrokeColor3 = Color3.new(1, 1, 1)
            })
        or nil,

        RightInfoDisplay = rightInfoDisplay,
    })
end

---

return UnitViewport