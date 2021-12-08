local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local UnitModels = ReplicatedStorage:WaitForChild("UnitModels")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Shop = require(GameModules:WaitForChild("Shop"))
local Unit = require(GameModules:WaitForChild("Unit"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local InventoryListFrame = require(GameUIModules:WaitForChild("InventoryListFrame"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))
local ViewportModel = require(GameUIModules:WaitForChild("ViewportModel"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

local getUnitText = function(unitName, textType)
    if (textType == "UnitName") then
        return Unit.GetUnitDisplayName(unitName)
    elseif (textType == "GrantCost") then
        return Shop.GetObjectGrantPrice(GameEnum.ObjectType.Unit, unitName)
    elseif (textType == "PlacementCost") then
        return Shop.GetObjectPlacementPrice(GameEnum.ObjectType.Unit, unitName)
    elseif (textType == "PersistentUpgradeLevel") then
        return Unit.GetUnitPersistentUpgradeLevel(LocalPlayer.UserId, unitName)
    end
end

---

--[[
    props

        AnchorPoint?
        Position?
        LayoutOrder?

        unitName: string
        selected: boolean?
        subtextDisplayType: string<UnitName | GrantCost | PlacementCost | PersistentUpgradeLevel>
        hoverSubtextDisplayType: string<UnitName | GrantCost | PlacementCost | PersistentUpgradeLevel>?

        onActivated: ()
        onMouseEnter: ()?
        onMouseLeave: ()?
]]

local UnitFrame = Roact.PureComponent:extend("UnitFrame")

UnitFrame.init = function(self)
    self.viewportFrame = Roact.createRef()
    self.viewportCamera = Roact.createRef()
    self.viewportCameraCFrame, self.updateViewportCameraCFrame = Roact.createBinding(CFrame.new(0, 0, 0))

    self.initObjectModel = function()
        local unitName = self.props.unitName
        if (not unitName) then return end

        local objectModel = UnitModels:FindFirstChild(unitName)
        if (not objectModel) then return end

        objectModel = objectModel:Clone()
        objectModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))

        local viewport = self.viewportFrame:getValue()
        if (not viewport) then return end

        self.unitModel = objectModel
        objectModel.Parent = viewport
    end
end

UnitFrame.didMount = function(self)
    local viewportModel = ViewportModel.new(self.viewportFrame:getValue(), self.viewportCamera:getValue())

    self.initObjectModel()
    viewportModel:Calibrate()

    local unitModel = self.unitModel

    if (unitModel) then
        viewportModel:SetModel(unitModel)

        self.updateViewportCameraCFrame(CFrame.new(0, 0, -viewportModel:GetFitDistance()) * CFrame.Angles(math.pi, 0, math.pi))
    end

    self.viewportModel = viewportModel
end

UnitFrame.didUpdate = function(self, prevProps)
    local unitName = self.props.unitName
    if (unitName == prevProps.unitName) then return end

    local oldUnitModel = self.unitModel

    if (oldUnitModel) then
        oldUnitModel:Destroy()
        self.unitModel = nil
    end

    self.initObjectModel()

    local unitModel = self.unitModel
    local viewportModel = self.viewportModel

    if (unitModel) then
        viewportModel:SetModel(unitModel)
        self.updateViewportCameraCFrame(CFrame.new(0, 0, -viewportModel:GetFitDistance()) * CFrame.Angles(math.pi, 0, math.pi))
    end
end

UnitFrame.willUnmount = function(self)
    if (self.unitModel) then
        self.unitModel:Destroy()
        self.unitModel = nil
    end
end

UnitFrame.render = function(self)
    local unitName = self.props.unitName

    return Roact.createElement(InventoryListFrame, {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,

        subtext = getUnitText(unitName, self.props.subtextDisplayType),
        hoverSubtext = self.props.hoverSubtextDisplayType and getUnitText(unitName, self.props.hoverSubtextDisplayType) or nil,
        selected = self.props.selected,

        onActivated = self.props.onActivated,
        onMouseEnter = self.props.onMouseEnter,
        onMouseLeave = self.props.onMouseLeave,
    }, {
        ViewportFrame = Roact.createElement("ViewportFrame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, -Style.Constants.SpaciousElementPadding, 1, -Style.Constants.SpaciousElementPadding),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LightDirection = Vector3.new(0, 0, 0),
            CurrentCamera = self.viewportCamera,

            Ambient = Color3.new(1, 1, 1),
            LightColor = Color3.new(1, 1, 1),

            [Roact.Ref] = self.viewportFrame,
        }, {
            Camera = Roact.createElement("Camera", {
                CFrame = self.viewportCameraCFrame,

                [Roact.Ref] = self.viewportCamera,
            }),
        })
    })
end

return UnitFrame