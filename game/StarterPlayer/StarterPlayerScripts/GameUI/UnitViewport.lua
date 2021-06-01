local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local root = script.Parent
local PlayerScripts = root.Parent

local Padding = require(root:WaitForChild("Padding"))
local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")
local SharedModules = ReplicatedStorage:WaitForChild("Shared")

local GameEnum = require(SharedModules:WaitForChild("GameEnums"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))

---

--[[
    props

    unitName: string
    titleDisplayType: UnitViewportTitleType
    showLevel: boolean?
    onMouseEnter: () -> nil
    onMouseLeave: () -> nil
]]

local UnitViewport = Roact.PureComponent:extend("UnitViewport")

UnitViewport.init = function(self)
    self.viewport = Roact.createRef()
    self.camera = Roact.createRef()

    self.initUnitModel = function()
        if (not self.props.unitName) then return end

        local unitModel = UnitModels:FindFirstChild(self.props.unitName)
        if (not unitModel) then return end

        unitModel = unitModel:Clone()
        unitModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))

        local primaryPart = unitModel.PrimaryPart
        local _, boundingBoxSize = unitModel:GetBoundingBox()

        local viewport = self.viewport:getValue()

        if (viewport) then
            unitModel.Parent = viewport
        end

        self:setState({
            unitModel = unitModel,

            -- todo: make this look better
            cameraCFrame = primaryPart.CFrame:ToWorldSpace(CFrame.new(0, 0, -boundingBoxSize.Z) * CFrame.Angles(0, math.pi, 0))
        })
    end

    self:setState({
        cameraCFrame = CFrame.new(0, 0, 0)
    })
end

UnitViewport.didMount = function(self)
    self.initUnitModel()
end

UnitViewport.didUpdate = function(self, prevProps)
    if (self.props.unitName == prevProps.unitName) then return end
    self.initUnitModel()
end

UnitViewport.willUnmount = function(self)
    if (self.state.unitModel) then
        self.state.unitModel:Destroy()
    end
end

UnitViewport.render = function(self)
    -- verify that the model exists first
    local unitName = self.props.unitName
    if (not unitName) then return end

    local unitModel = UnitModels:FindFirstChild(unitName)
    if (not unitModel) then return nil end

    local titleText

    if (self.props.titleDisplayType == GameEnum.UnitViewportTitleType.PlacementPrice) then
        titleText = ShopPrices.ObjectPlacementPrices[GameEnum.ObjectType.Unit][unitName] or "?"
    elseif (self.props.titleDisplayType == GameEnum.UnitViewportTitleType.UnitName) then
        titleText = unitName
    else
        -- todo
        titleText = "?"
    end

    return Roact.createElement("TextButton", {
        AnchorPoint = self.props.AnchorPoint,
        Size = UDim2.new(0, Style.Constants.UnitViewportFrameSize, 0, Style.Constants.UnitViewportFrameSize),
        Position = self.props.Position,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,

        Text = "",
        TextTransparency = 1,
        TextStrokeTransparency = 1,

        BackgroundColor3 = Color3.new(1, 1, 1),

        [Roact.Event.MouseEnter] = function(_)
            self.props.onMouseEnter()
        end,

        [Roact.Event.MouseLeave] = function(_)
            self.props.onMouseLeave()
        end
    }, {
        UICorner = Roact.createElement("UICorner", {
            CornerRadius = UDim.new(0, Style.Constants.SmallCornerRadius)
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

        Hotkey = self.props.showHotkey and
            Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 0),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,

                Text = "#",
                Font = Style.Constants.MainFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextSize = 16,
                TextStrokeTransparency = 0.5,

                TextColor3 = Color3.new(0, 0, 0),
                TextStrokeColor3 = Color3.new(1, 1, 1)
            })
        or nil,

        Level = self.props.showLevel and
            Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ZIndex = 2,

                Text = "#",
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

return UnitViewport