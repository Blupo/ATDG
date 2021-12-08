-- TODO: hook event for item count changing

local Players = game:GetService("Players")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local InventoryListFrame = require(GameUIModules:WaitForChild("InventoryListFrame"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

local getItemText = function(itemType, itemName, displayType)
    if (displayType == "ItemName") then
        return itemName
    elseif (displayType == "ItemCost") then
        return Shop.GetItemPrice(itemType, itemName)
    elseif (displayType == "ItemCount") then
        return PlayerData.GetPlayerInventoryItemCount(LocalPlayer.UserId, itemType, itemName)
    end
end

---

--[[
    props

        AnchorPoint?
        Position?
        LayoutOrder?

        itemType: string
        itemName: string
        selected: boolean?
        subtextDisplayType: string<ItemName | ItemCost | ItemCount>
        hoverSubtextDisplayType: string<ItemName | ItemCost | ItemCount>?

        onActivated: ()
        onMouseEnter: ()?
        onMouseLeave: ()?
]]

local InventoryFrame = Roact.PureComponent:extend("InventoryFrame")

InventoryFrame.render = function(self)
    local itemType = self.props.itemType
    local itemName = self.props.itemName

    return Roact.createElement(InventoryListFrame, {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        LayoutOrder = self.props.LayoutOrder,

        subtext = getItemText(itemType, itemName, self.props.subtextDisplayType),
        hoverSubtext = self.props.hoverSubtextDisplayType and getItemText(itemType, itemName, self.props.hoverSubtextDisplayType) or nil,
        selected = self.props.selected,

        onActivated = self.props.onActivated,
        onMouseEnter = self.props.onMouseEnter,
        onMouseLeave = self.props.onMouseLeave,
    }, {
        Icon = Roact.createElement("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -Style.Constants.MajorElementPadding, 1, -Style.Constants.MajorElementPadding),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,

            Image = Style.Images[itemName .. itemType .. "ItemIcon"],
            ImageColor3 = Color3.new(0, 0, 0),
        })
    })
end

return InventoryFrame