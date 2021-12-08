local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local SpecialActions = require(GameModules:WaitForChild("SpecialActions"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Button = require(GameUIModules:WaitForChild("Button"))
local InventoryFrame = require(GameUIModules:WaitForChild("InventoryFrame"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local CopyTable = require(SharedModules:WaitForChild("CopyTable"))
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local TimeSyncService = require(SharedModules:WaitForChild("TimeSyncService"))

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIPadding = StandardComponents.UIPadding
local StandardUIGridLayout = StandardComponents.UIGridLayout

---

local actions = SpecialActions.GetActions()
local syncedClock = TimeSyncService:GetSyncedClock()

local initActionInventory = {}

for action in pairs(actions) do
    initActionInventory[action] = 0
end

---

local SpecialInventorySubpage = Roact.PureComponent:extend("SpecialInventorySubpage")

SpecialInventorySubpage.init = function(self)
    self.listLength, self.updateListLength = Roact.createBinding(0)
    self.selectedActionUsageCooldown, self.updateSelectedActionUsageCooldown = Roact.createBinding(0)

    self:setState({
        actionInventory = {},
    })
end

SpecialInventorySubpage.didMount = function(self)
    self.inventoryChanged = PlayerData.InventoryChanged:Connect(function(_, itemType: string, itemName: string, newAmount: number)
        if (itemType ~= GameEnum.ItemType.SpecialAction) then return end

        local newInventory = CopyTable(self.state.actionInventory)
        newInventory[itemName] = newAmount

        self:setState({
            actionInventory = newInventory
        })
    end)

    self.specialActionUsed = SpecialActions.ActionUsed:Connect(function(userId: number, actionName: string, cooldownExpires: number, usageCount: number)
        if (userId ~= LocalPlayer.UserId) then return end
        if (actionName ~= self.state.selectedAction) then return end

        self:setState({
            selectedActionUsageCount = usageCount,
            selectedActionUsageCooldownExpiry = cooldownExpires,
        })
    end)

    self.cooldownTimer = RunService.Heartbeat:Connect(function()
        if (not self.state.selectedAction) then return end

        local cooldownExpiry = self.state.selectedActionUsageCooldownExpiry
        local now = syncedClock:GetTime()
        if ((now >= cooldownExpiry) and (self.selectedActionUsageCooldown:getValue() <= 0)) then return end

        self.updateSelectedActionUsageCooldown(math.max(cooldownExpiry - now, 0))
    end)

    local actionInventory = CopyTable(initActionInventory)
    local actualActionInventory = PlayerData.GetPlayerInventory(LocalPlayer.UserId)[GameEnum.ItemType.SpecialAction]

    for action, inventory in pairs(actualActionInventory) do
        actionInventory[action] = inventory
    end

    self:setState({
        actionInventory = actionInventory
    })
end

SpecialInventorySubpage.willUnmount = function(self)
    self.inventoryChanged:Disconnect()
    self.specialActionUsed:Disconnect()
    self.cooldownTimer:Disconnect()
end

SpecialInventorySubpage.render = function(self)
    local actionInventory = self.state.actionInventory
    local selectedAction = self.state.selectedAction

    local selectedActionInventoryCount
    local selectedActionMaxUses
    local selectedActionRemainingUses

    local actionListElements = {}

    if (selectedAction) then
        local selectedActionLimits = SpecialActions.GetActionData(selectedAction)
        
        selectedActionInventoryCount = actionInventory[selectedAction] or 0
        selectedActionMaxUses = selectedActionLimits[GameEnum.SpecialActionLimitType.PlayerLimit] or math.huge
        selectedActionRemainingUses = selectedActionMaxUses - self.state.selectedActionUsageCount
    end

    for action in pairs(actionInventory) do
        local selected = (action == selectedAction)

        actionListElements[action] = Roact.createElement(InventoryFrame, {
            itemType = GameEnum.ItemType.SpecialAction,
            itemName = action,
            subtextDisplayType = "ItemName",
            selected = selected,

            onActivated = function()
                self:setState({
                    selectedAction = selected and Roact.None or action,
                    selectedActionUsageCount = selected and Roact.None or SpecialActions.GetPlayerActionUsageCount(LocalPlayer.UserId, action),
                    selectedActionUsageCooldownExpiry = selected and Roact.None or SpecialActions.GetPlayerActionCooldownExpiry(LocalPlayer.UserId, action),
                })
            end,
        })
    end

    actionListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
        CellSize = UDim2.new(
            0, Style.Constants.InventoryFrameButtonSize,
            0, Style.Constants.InventoryFrameButtonSize + Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding
        ),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createFragment({
        ActionList = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),

            Size = UDim2.new(1, 0, 1, (not selectedAction) and 0 or -(
                Style.Constants.StandardTextSize +
                Style.Constants.StandardButtonHeight +
                Style.Constants.StandardIconSize +
                (Style.Constants.SpaciousElementPadding * 4)
            )),

            CanvasSize = self.listLength:map(function(listLength)
                return UDim2.new(0, 0, 0, listLength)
            end),
        }, actionListElements),

        SelectedActionInfo = (selectedAction) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                Size = UDim2.new(1, 0, 0,
                    Style.Constants.StandardTextSize +
                    Style.Constants.StandardButtonHeight +
                    (Style.Constants.StandardIconSize * 2) +
                    (Style.Constants.SpaciousElementPadding * 5)
                ),

                BackgroundColor3 = Color3.new(1, 1, 1),
            }, {
                UICorner = Roact.createElement(StandardUICorner),
                UIPadding = Roact.createElement(StandardUIPadding),

                SelectedAction = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                    Position = UDim2.new(0.5, 0, 0, 0),

                    Text = selectedAction,
                    TextScaled = true,
                    TextYAlignment = Enum.TextYAlignment.Top,
                }),

                UsesReadout = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardIconSize),
                    Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardTextSize + Style.Constants.SpaciousElementPadding),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                }, {
                    Icon = Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,

                        Image = Style.Images.BackpackIcon,
                        ImageColor3 = Style.Colors.RedProminentGradient.Keypoints[1].Value,
                    }),

                    Label = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(1, -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding), 0, Style.Constants.StandardTextSize),
                        Position = UDim2.new(1, 0, 0.5, 0),

                        Text = "Uses",
                    }),

                    Value = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(1, -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding), 0, Style.Constants.StandardTextSize),
                        Position = UDim2.new(1, 0, 0.5, 0),

                        Font = Style.Constants.SecondaryFont,
                        TextXAlignment = Enum.TextXAlignment.Right,

                        Text = string.format(
                            "%s/%s/%s",
                            (selectedActionRemainingUses ~= math.huge) and selectedActionRemainingUses or "∞",
                            (selectedActionMaxUses ~= math.huge) and selectedActionMaxUses or "∞",
                            selectedActionInventoryCount
                        ),
                    }),
                }),

                CooldownReadout = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardIconSize),
                    Position = UDim2.new(0.5, 0, 0, Style.Constants.StandardTextSize + Style.Constants.StandardIconSize + (Style.Constants.SpaciousElementPadding * 2)),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                }, {
                    Icon = Roact.createElement("ImageLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,

                        Image = Style.Images.CDAttributeIcon,
                        ImageColor3 = Style.Colors.CDAttributeIconColor,
                    }),

                    Label = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(1, -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding), 0, Style.Constants.StandardTextSize),
                        Position = UDim2.new(1, 0, 0.5, 0),

                        Text = "Cooldown",
                    }),

                    Value = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(1, -(Style.Constants.StandardIconSize + Style.Constants.SpaciousElementPadding), 0, Style.Constants.StandardTextSize),
                        Position = UDim2.new(1, 0, 0.5, 0),

                        Font = Enum.Font.Code,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        
                        Text = self.selectedActionUsageCooldown:map(function(cooldown)
                            return (cooldown > 0) and string.format("%.03f", cooldown) or "Ready"
                        end),
                    }),
                }),

                UseButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    Text = "Use " .. selectedAction,

                    disabled = ((selectedActionInventoryCount <= 0) or (selectedActionRemainingUses <= 0)),
                    displayType = "Text",

                    onActivated = function()
                        SpecialActions.UseAction(LocalPlayer.UserId, selectedAction)
                    end
                })
            })
        or nil
    })
end

return SpecialInventorySubpage