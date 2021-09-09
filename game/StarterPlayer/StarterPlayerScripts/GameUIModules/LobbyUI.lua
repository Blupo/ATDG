local root = script.Parent

local Padding = require(root:WaitForChild("Padding"))
local Roact = require(root:WaitForChild("Roact"))
local Style = require(root:WaitForChild("Style"))

local CurrencyBar = require(root:WaitForChild("CurrencyBar"))
local InventoryMenu = require(root:WaitForChild("InventoryMenu"))
local PlayMenu = require(root:WaitForChild("PlayMenu"))
local ShopMenu = require(root:WaitForChild("ShopMenu"))

---

local menuItems = {
    {
        name = "Play",
        image = "rbxassetid://3458452392",
        element = PlayMenu,
    },

    {
        name = "Shop",
        image = "rbxassetid://7198417722",
        element = ShopMenu,
    },

    --[[
    {
        name = "Inventory",
        image = "rbxassetid://313069079",
        element = InventoryMenu,
    }
    --]]
}

---

local LobbyUI = Roact.PureComponent:extend("LobbyUI")

LobbyUI.render = function(self)
    local selected = self.state.selected
    local menuElements = {}

    for i = 1, #menuItems do
        local menuItem = menuItems[i]

        menuElements[menuItem.name] = Roact.createElement("TextButton", {
            Size = UDim2.new(0, 100, 0, 100),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            LayoutOrder = i,

            Text = "",
            TextTransparency = 1,

            BackgroundColor3 = Color3.new(1, 1, 1),

            [Roact.Event.Activated] = function()
                self:setState({
                    selected = (selected ~= i) and i or Roact.None
                })
            end,
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0, Style.Constants.StandardCornerRadius)
            }),

            Padding = Roact.createElement(Padding, { Style.Constants.MinorElementPadding }),

            ItemLabel = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0.5, 1),
                Size = UDim2.new(1, 0, 0, 16),
                Position = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = menuItem.name,
                Font = Style.Constants.MainFont,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                
                TextColor3 = Color3.new(0, 0, 0),
            }),

            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, -16, 1, -16),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = menuItem.image,
                ImageColor3 = Color3.fromRGB(40, 40, 40),
            })
        })
    end

    menuElements.UIListLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, Style.Constants.MajorElementPadding),

        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    return Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, {
        Padding = Roact.createElement(Padding, { Style.Constants.MajorElementPadding }),
        CurrencyBar = Roact.createElement(CurrencyBar),

        Menu = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 100, 1, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, menuElements),

        SelectedPageMenu = selected and
            Roact.createElement(menuItems[selected].element)
        or nil,
    })
end

return LobbyUI