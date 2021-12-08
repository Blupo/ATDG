local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local MainElementContainer = require(GameUIModules:WaitForChild("MainElementContainer"))
local MenuButton = require(GameUIModules:WaitForChild("MenuButton"))
local PageSelector = require(GameUIModules:WaitForChild("PageSelector"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local SpecialInventorySubpage = require(GameUIModules:WaitForChild("SpecialInventorySubpage"))
local Style = require(GameUIModules:WaitForChild("Style"))
local UnitInventorySubpage = require(GameUIModules:WaitForChild("UnitInventorySubpage"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local PlacementFlow = require(PlayerModules:WaitForChild("PlacementFlow"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

local INVENTORY_WIDTH = 280
local INVENTORY_HEIGHT = 420

local inventorySubpages = {
    {
        Name = "TowerUnits",
        Image = Style.Images.UnitInventoryIcon,
        Color = Style.Colors.YellowProminentGradient,
        Page = UnitInventorySubpage,

        PageProps = {
            unitType = GameEnum.UnitType.TowerUnit,
        }
    },

    {
        Name = "Special",
        Image = Style.Images.SpecialInventoryIcon,
        Color = Style.Colors.PinkProminentGradient,
        Page = SpecialInventorySubpage,
    }
}

---

local MainInventory = Roact.PureComponent:extend("MainInventory")

MainInventory.init = function(self)
    self:setState({
        enabled = false,
        overrideEnabled = false,
    })
end

MainInventory.didMount = function(self)
    self.placementFlowStarted = PlacementFlow.Started:Connect(function()
        self:setState({
            overrideEnabled = true,
        })
    end)

    self.placementFlowStopped = PlacementFlow.Stopped:Connect(function()
        self:setState({
            overrideEnabled = false,
        })
    end)
end

MainInventory.willUnmount = function(self)
    self.placementFlowStarted:Disconnect()
    self.placementFlowStopped:Disconnect()
end

MainInventory.render = function(self)
    local enabled = self.state.enabled
    local overrideEnabled = self.state.overrideEnabled

    if (overrideEnabled) then
        enabled = false
    end

    return Roact.createElement(MainElementContainer, {
        AnchorPoint = Vector2.new(enabled and 1 or 0, 1),
        Size = UDim2.new(0, INVENTORY_WIDTH, 0, INVENTORY_HEIGHT),
        Padding = Style.Constants.SpaciousElementPadding,
        
        Position = UDim2.new(
            1, (not enabled) and Style.Constants.ProminentBorderWidth or -(Style.Constants.ProminentBorderWidth + Style.Constants.MajorElementPadding),
            1, -(Style.Constants.MajorElementPadding + Style.Constants.ProminentBorderWidth)
        ),

        StrokeGradient = Style.Colors.RedProminentGradient,
    }, {
        Toggle = Roact.createElement(MenuButton, {
            AnchorPoint = Vector2.new(0, enabled and 0 or 1),

            Position = UDim2.new(
                0, -(Style.Constants.SpaciousElementPadding + Style.Constants.MajorElementPadding + Style.Constants.MenuButtonSize + Style.Constants.ProminentBorderWidth),
                enabled and 0 or 1, (enabled and -1 or 1) * (Style.Constants.SpaciousElementPadding + Style.Constants.ProminentBorderWidth)
            ),

            Image = Style.Images.InventoryPageMenuButtonIcon,
            Color = Style.Colors.RedProminentGradient,

            onActivated = function()
                if (overrideEnabled) then return end

                self:setState({
                    enabled = (not enabled)
                })
            end
        }),

        PageSelector = Roact.createElement(PageSelector, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),

            pages = inventorySubpages,
        })
    })
end

return MainInventory