local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameModules = PlayerScripts:WaitForChild("GameModules")
local PlayerData = require(GameModules:WaitForChild("PlayerData"))
local Shop = require(GameModules:WaitForChild("Shop"))
local SpecialActions = require(GameModules:WaitForChild("SpecialActions"))

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Button = require(GameUIModules:WaitForChild("Button"))
local InventoryFrame = require(GameUIModules:WaitForChild("InventoryFrame"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local PlayerModules = PlayerScripts:WaitForChild("PlayerModules")
local GenerateSpecialActionLimitDescription = require(PlayerModules:WaitForChild("GenerateSpecialActionLimitDescription"))
local SpecialActionFlavourTexts = require(PlayerModules:WaitForChild("SpecialActionFlavourTexts"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))
local ShopPrices = require(SharedModules:WaitForChild("ShopPrices"))

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUICorner = StandardComponents.UICorner
local StandardUIListLayout = StandardComponents.UIListLayout
local StandardUIPadding = StandardComponents.UIPadding
local StandardUIGridLayout = StandardComponents.UIGridLayout

---

local actionPrices = ShopPrices.ItemPrices[GameEnum.ItemType.SpecialAction]
local actionPricesSorted = {}

for actionName, price in pairs(actionPrices) do
    table.insert(actionPricesSorted, {
        actionName = actionName,
        price = price
    })
end

table.sort(actionPricesSorted, function(a, b)
    return a.actionName < b.actionName
end)

---

local SpecialShopSubpage = Roact.PureComponent:extend("SpecialShopSubpage")

SpecialShopSubpage.init = function(self)
    self.loadingImage = Roact.createRef()
    self.pageListLength, self.updatePageListLength = Roact.createBinding(0)
    self.ticketListLength, self.updateTicketListLength = Roact.createBinding(0)
    self.actionListLength, self.updateActionListLength = Roact.createBinding(0)
    self.selectedActionSectionWidth, self.updateSelectedActionSectionWidth = Roact.createBinding(0)
    self.selectedActionDescriptionLength, self.updateSelectedActionDescriptionLength = Roact.createBinding(0)

    self:setState({
        ticketProducts = {},
        productLoadingStatus = "wait",
    })
end

SpecialShopSubpage.didMount = function(self)
    self.rotator = RunService.Heartbeat:Connect(function(step)
        local loadingImage = self.loadingImage:getValue()
        if (not loadingImage) then return end

        if (self.state.productLoadingStatus == "wait") then
            loadingImage.Rotation = (loadingImage.Rotation + (step * 60)) % 360  
        else
            loadingImage.Rotation = 0
        end
    end)

    self.inventoryChangedConnection = PlayerData.InventoryChanged:Connect(function(_, itemType: string, itemName: string, newAmount: number, _)
        if (itemType ~= GameEnum.ItemType.SpecialAction) then return end
        if (self.state.selectedAction ~= itemName) then return end

        self:setState({
            selectedActionCount = newAmount
        })
    end)

    local ticketProducts = Shop.GetProducts()[GameEnum.DevProductType.Ticket]
    local ticketProductsSorted = {}

    for ticketAmount, productId in pairs(ticketProducts) do
        local productInfo = MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)

        table.insert(ticketProductsSorted, {
            ticketAmount = ticketAmount,
            price = productInfo.PriceInRobux,
            productId = productId
        })
    end

    table.sort(ticketProductsSorted, function(a, b)
        return tonumber(a.ticketAmount) < tonumber(b.ticketAmount)
    end)

    self:setState({
        ticketProducts = ticketProductsSorted,
        productLoadingStatus = Roact.None,
    })

    self.rotator:Disconnect()
end

SpecialShopSubpage.willUnmount = function(self)
    self.inventoryChangedConnection:Disconnect()
end

SpecialShopSubpage.render = function(self)
    local selectedAction = self.state.selectedAction
    local ticketProducts = self.state.ticketProducts

    local selectedActionPrice
    local selectedActionPriceTextSize
    local selectedActionDescription

    local ticketListElements = {}
    local actionListElements = {}

    if (selectedAction) then
        local selectedActionUsageLimits = SpecialActions.GetActionData(selectedAction).Limits

        selectedActionPrice = Shop.GetItemPrice(GameEnum.ItemType.SpecialAction, selectedAction)
        selectedActionPrice = (selectedActionPrice ~= math.huge) and selectedActionPrice or "∞"
        selectedActionDescription = (SpecialActionFlavourTexts[selectedAction] or "") ..
            (selectedActionUsageLimits and ("\n\n" .. GenerateSpecialActionLimitDescription(selectedActionUsageLimits)) or "")

        selectedActionPriceTextSize = TextService:GetTextSize(selectedActionPrice, 16, Style.Constants.PrimaryFont, Vector2.new(math.huge, math.huge))
    end

    if (#ticketProducts < 1) then
        ticketListElements.LoadingIndicator = Roact.createElement("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Image = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = Style.Images.LoadingIcon,
                ImageColor3 = Color3.new(0, 0, 0),

                [Roact.Ref] = self.loadingImage,
            })
        })
    else
        for i = 1, #ticketProducts do
            local productInfo = ticketProducts[i]

            ticketListElements[productInfo.ticketAmount] = Roact.createElement(Button, {
                LayoutOrder = i,

                BackgroundColor3 = Color3.new(1, 1, 1),

                displayType = "Children",
                onActivated = function()
                    MarketplaceService:PromptProductPurchase(LocalPlayer, productInfo.productId, false)
                end,
            }, {
                UIPadding = Roact.createElement(StandardUIPadding),

                TicketAmountLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 1, -16),
                    Position = UDim2.new(0.5, 0, 0, 0),

                    Text = productInfo.ticketAmount,
                    TextSize = 32,
                    TextXAlignment = Enum.TextXAlignment.Center,
                }),

                PriceLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, 16),
                    Position = UDim2.new(0.5, 0, 1, 0),

                    Text = productInfo.price .. " R$",
                    TextXAlignment = Enum.TextXAlignment.Center,
                })
            })
        end
    end

    for i = 1, #actionPricesSorted do
        local priceInfo = actionPricesSorted[i]
        local actionName = priceInfo.actionName

        actionListElements[actionName] = Roact.createElement(InventoryFrame, {
            LayoutOrder = i,
            
            itemType = GameEnum.ItemType.SpecialAction,
            itemName = actionName,
            selected = (selectedAction == actionName),

            subtextDisplayType = "ItemCount",
            hoverSubtextDisplayType = "ItemName",

            onActivated = function()
                self:setState({
                    selectedAction = actionName,
                    selectedActionCount = PlayerData.GetPlayerInventoryItemCount(LocalPlayer.UserId, GameEnum.ItemType.SpecialAction, priceInfo.actionName)
                })
            end,
        })
    end

    ticketListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
        CellSize = UDim2.new(0, Style.Constants.InventoryFrameButtonSize, 0, Style.Constants.InventoryFrameButtonSize),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateTicketListLength(obj.AbsoluteContentSize.Y)
        end
    })

    actionListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
        CellSize = UDim2.new(
            0, Style.Constants.InventoryFrameButtonSize,
            0, Style.Constants.InventoryFrameButtonSize + Style.Constants.StandardButtonHeight + Style.Constants.MinorElementPadding
        ),

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateActionListLength(obj.AbsoluteContentSize.Y)
        end
    })

    return Roact.createFragment({
        SpecialList = Roact.createElement(StandardScrollingFrame, {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(selectedAction and UDim.new(0.7, -16) or UDim.new(1, 0), UDim.new(1, 0)),
            Position = UDim2.new(0, 0, 0.5, 0),

            CanvasSize = self.pageListLength:map(function(listLength)
                return UDim2.new(0, 0, 0, listLength)
            end),
        }, {
            TicketHeader = Roact.createElement(StandardTextLabel, {
                Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
                LayoutOrder = 0,

                Text = "Tickets",
                TextSize = Style.Constants.PrimaryHeaderTextSize,
                TextYAlignment = Enum.TextYAlignment.Top,
            }),

            TicketList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 1,

                Size = self.ticketListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, ticketListElements),

            ActionHeader = Roact.createElement(StandardTextLabel, {
                Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),
                LayoutOrder = 2,

                Text = "Special Actions",
                TextSize = Style.Constants.PrimaryHeaderTextSize,
                TextYAlignment = Enum.TextYAlignment.Top,
            }),

            ActionList = Roact.createElement("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 3,

                Size = self.actionListLength:map(function(listLength)
                    return UDim2.new(1, 0, 0, listLength)
                end),
            }, actionListElements),

            UIListLayout = Roact.createElement(StandardUIListLayout, {
                Padding = UDim.new(0, Style.Constants.MajorElementPadding),

                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,

                [Roact.Change.AbsoluteContentSize] = function(obj)
                    self.updatePageListLength(obj.AbsoluteContentSize.Y)
                end
            }),
        }),

        SelectedActionInfo = (selectedAction) and
            Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0.3, -Style.Constants.SpaciousElementPadding, 1, 0),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = Color3.new(1, 1, 1),

                [Roact.Change.AbsoluteSize] = function(obj)
                    self.updateSelectedActionSectionWidth(obj.AbsoluteSize.X)
                end
            }, {
                UICorner = Roact.createElement(StandardUICorner),
                UIPadding = Roact.createElement(StandardUIPadding),

                ActionImageLabel = Roact.createElement("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,

                    Image = Style.Images[selectedAction .. "SpecialActionItemIcon"],
                    ImageTransparency = 0.75,
                    ScaleType = Enum.ScaleType.Fit,

                    ImageColor3 = Color3.new(0, 0, 0),
                }),

                ActionNameLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),
                    Position = UDim2.new(0.5, 0, 0, 0),

                    Text = selectedAction,
                    TextSize = Style.Constants.SecondaryHeaderTextSize,
                    TextScaled = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),

                Description = Roact.createElement(StandardScrollingFrame, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, Style.Constants.SecondaryHeaderTextSize + Style.Constants.SpaciousElementPadding),

                    Size = UDim2.new(1, 0, 1, -(
                        Style.Constants.SecondaryHeaderTextSize +
                        Style.Constants.StandardTextSize +
                        Style.Constants.StandardButtonHeight +
                        (Style.Constants.SpaciousElementPadding * 3)
                    )),

                    CanvasSize = self.selectedActionDescriptionLength:map(function(length)
                        return UDim2.new(0, 0, 0, length)
                    end)
                }, {
                    DescriptionLabel = Roact.createElement(StandardTextLabel, {
                        AnchorPoint = Vector2.new(0, 0),
                        Position = UDim2.new(0, 0, 0, 0),

                        Text = selectedActionDescription,
                        Font = Style.Constants.SecondaryFont,
                        TextWrapped = true,
                        TextYAlignment = Enum.TextYAlignment.Top,

                        Size = self.selectedActionSectionWidth:map(function(width)
                            local selectedActionDescriptionTextSize = TextService:GetTextSize(
                                selectedActionDescription,
                                Style.Constants.StandardTextSize,
                                Style.Constants.SecondaryFont,
                                Vector2.new(width - Style.Constants.StandardScrollbarThickness - Style.Constants.SpaciousElementPadding, math.huge)
                            )

                            self.updateSelectedActionDescriptionLength(selectedActionDescriptionTextSize.Y)
                            return UDim2.new(1, -Style.Constants.SpaciousElementPadding, 0, selectedActionDescriptionTextSize.Y)
                        end),
                    }),
                }),

                OwnedLabel = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize),
                    Position = UDim2.new(0.5, 0, 1, -(Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding)),

                    Text = "Owned: " .. self.state.selectedActionCount,
                    TextXAlignment = Enum.TextXAlignment.Center,
                }),

                PurchaseButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardButtonHeight),
                    Position = UDim2.new(0.5, 0, 1, 0),

                    displayType = "Children",
                    onActivated = function()
                        Shop.PurchaseItem(LocalPlayer.UserId, GameEnum.ItemType.SpecialAction, selectedAction)
                    end,
                }, {
                    UIListLayout = Roact.createElement(StandardUIListLayout, {
                        Padding = UDim.new(0, Style.Constants.MinorElementPadding),

                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    }),

                    PriceLabel = Roact.createElement(StandardTextLabel, {
                        Size = UDim2.new(0, selectedActionPriceTextSize.X, 1, 0),
                        LayoutOrder = 0,

                        Text = selectedActionPrice,
                        TextYAlignment = Enum.TextYAlignment.Center,
                    }),

                    TicketIcon = Roact.createElement("ImageLabel", {
                        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 1,

                        Image = Style.Images.TicketsCurrencyIcon,
                        ImageColor3 = Color3.new(0, 0, 0)
                    })
                }),
            })
        or nil
    })
end

return SpecialShopSubpage