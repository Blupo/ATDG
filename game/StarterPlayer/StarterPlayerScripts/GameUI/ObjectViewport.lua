local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent
local PlayerScripts = root.Parent

local Padding = require(root:WaitForChild("Padding"))
local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")
-- local RoadblockModels = ReplicatedStorage:WaitForChild("RoadblocksModels")

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

local LocalPlayer = Players.LocalPlayer

---

--[[
    props

    objectType: ObjectType
    objectName: string

    infoLeftDisplay: string

    titleDisplayType: ObjectViewportTitleType
    onActivated: () -> nil
    onMouseEnter: () -> nil
    onMouseLeave: () -> nil

    hotkey: number?
    showLevel: boolean?
]]

local ObjectViewport = Roact.PureComponent:extend("ObjectViewport")

ObjectViewport.init = function(self)
    self.viewport = Roact.createRef()
    self.camera = Roact.createRef()

    self.initObjectModel = function()
        if (not (self.props.objectType and self.props.objectName)) then return end

        local objectModel

        if (self.props.objectType == GameEnum.ObjectType.Unit) then
            objectModel = UnitModels:FindFirstChild(self.props.objectName)
        else
            -- todo
            return
        end

        if (not objectModel) then return end

        objectModel = objectModel:Clone()
        objectModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))

        local primaryPart = objectModel.PrimaryPart
        local _, boundingBoxSize = objectModel:GetBoundingBox()

        local viewport = self.viewport:getValue()

        if (viewport) then
            objectModel.Parent = viewport
        end

        self:setState({
            objectModel = objectModel,

            -- todo: make this look better
            cameraCFrame = primaryPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -boundingBoxSize.Z) * CFrame.Angles(0, math.pi, 0))
        })
    end

    self:setState({
        cameraCFrame = CFrame.new(0, 0, 0)
    })
end

ObjectViewport.didMount = function(self)
    self.initObjectModel()
end

ObjectViewport.didUpdate = function(self, prevProps)
    if (self.props.objectName == prevProps.objectName) then return end
    self.initObjectModel()
end

ObjectViewport.willUnmount = function(self)
    if (self.state.objectModel) then
        self.state.objectModel:Destroy()
    end
end

ObjectViewport.render = function(self)
    local objectType = self.props.objectType
    local objectName = self.props.objectName
    local infoLeftDisplay = self.props.infoLeftDisplay

    -- check if the obj model exists

    local titleText
    local infoLeft

    if (self.props.titleDisplayType == GameEnum.ObjectViewportTitleType.PlacementPrice) then
        titleText = Shop.GetObjectPlacementPrice(objectType, objectName) or "?"
    elseif (self.props.titleDisplayType == GameEnum.ObjectViewportTitleType.ObjectName) then
        titleText = objectName
    else
        -- todo
        titleText = "?"
    end

    if (infoLeftDisplay == "Hotkey") then
        infoLeft = Roact.createElement("TextLabel", {
            AnchorPoint = Vector2.new(0, 0),
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,

            Text = self.props.hotkey,
            Font = Style.Constants.MainFont,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextSize = 16,
            TextStrokeTransparency = 0.5,

            TextColor3 = Color3.new(0, 0, 0),
            TextStrokeColor3 = Color3.new(1, 1, 1)
        })
    elseif (infoLeftDisplay == "HotbarButton") then
        -- todo
    end

    return Roact.createElement("TextButton", {
        AnchorPoint = self.props.AnchorPoint,
        Size = UDim2.new(0, Style.Constants.ObjectViewportFrameSize, 0, Style.Constants.ObjectViewportFrameSize),
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

        -- todo: hovering
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

        InfoLeft = infoLeft,

        Level = (self.props.showLevel and (objectType == GameEnum.ObjectType.Unit)) and
            Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ZIndex = 2,

                Text = Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, self.props.objectName) or "?",
                Font = Style.Constants.MainFont,
                TextSize = 16,

                BackgroundColor3 = Color3.new(1, 1, 1),
                TextColor3 = Color3.new(0, 0, 0)
            }, {
                UICorner = Roact.createElement("UICorner", {
                    CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
                }),
            })
        or nil
    })
end

---

return ObjectViewport