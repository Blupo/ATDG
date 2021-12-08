-- TODO: revamp

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local SystemCoordinator = require(SharedModules:WaitForChild("SystemCoordinator"))

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Roact = require(GameUIModules:WaitForChild("Roact"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Unit = require(GameModules:WaitForChild("Unit"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local StatusEffectColors = require(PlayerModules:WaitForChild("StatusEffectColors"))

local StatusEffects = SystemCoordinator.waitForSystem("StatusEffects")

---

--[[
    props

    Adornee?
    Size?
    StudsOffsetWorldSpace?

    unitId: string
]]

local TowerUnitBillboard = Roact.PureComponent:extend("TowerUnitBillboard")

TowerUnitBillboard.init = function(self)
    self:setState({
        statusEffects = {},
    })
end

TowerUnitBillboard.didMount = function(self)
    local thisUnitId = self.props.unitId
    local thisUnit = Unit.fromId(self.props.unitId)
    if (not thisUnit) then return end

    self.effectApplied = StatusEffects.EffectApplied:Connect(function(unitId: string, effectName: string)
        if (unitId ~= thisUnitId) then return end

        local newStatusEffects = {
            [effectName] = true,
        }

        for effect in pairs(self.state.statusEffects) do
            newStatusEffects[effect] = true
        end

        self:setState({
           statusEffects = newStatusEffects 
        })
    end)

    self.effectRemoved = StatusEffects.EffectRemoved:Connect(function(unitId: string, effectName: string)
        if (unitId ~= thisUnitId) then return end

        local newStatusEffects = {}

        for effect in pairs(self.state.statusEffects) do
            if (effect ~= effectName) then
                newStatusEffects[effect] = true
            end
        end

        self:setState({
           statusEffects = newStatusEffects 
        })
    end)

    local statusEffectsArray = StatusEffects.GetUnitEffects(thisUnitId)
    local statusEffectsDictionary = {}

    for i = 1, #statusEffectsArray do
        statusEffectsDictionary[statusEffectsArray[i]] = true
    end

    self:setState({
        statusEffects = statusEffectsDictionary,
    })
end

TowerUnitBillboard.willUnmount = function(self)
    self.effectApplied:Disconnect()
    self.effectRemoved:Disconnect()
end

TowerUnitBillboard.render = function(self)
    local statusEffects = self.state.statusEffects

    local statusEffectsAlphabetSort = {}
    local statusEffectChildren = {}
    
    for effectName in pairs(statusEffects) do
        table.insert(statusEffectsAlphabetSort, effectName)
    end

    table.sort(statusEffectsAlphabetSort, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    for effectName in pairs(statusEffects) do
        statusEffectChildren[effectName] = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = table.find(statusEffectsAlphabetSort, effectName) or 0,
            
            BackgroundColor3 = StatusEffectColors[effectName] or Color3.new(0, 0, 0),
        })
    end

    statusEffectChildren.UIListLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0.05, 0),

        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    return Roact.createElement("BillboardGui", {
        Adornee = self.props.Adornee,
        Size = self.props.Size,
        StudsOffsetWorldSpace = self.props.StudsOffsetWorldSpace,
        LightInfluence = 0,
        ResetOnSpawn = false,
        ClipsDescendants = true,
    }, statusEffectChildren)
end

return TowerUnitBillboard