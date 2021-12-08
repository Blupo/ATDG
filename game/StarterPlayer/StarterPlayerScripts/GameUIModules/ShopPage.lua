local GameUIModules = script.Parent

local MainElementContainer = require(GameUIModules:WaitForChild("MainElementContainer"))
local PageSelector = require(GameUIModules:WaitForChild("PageSelector"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local SpecialShopSubpage = require(GameUIModules:WaitForChild("SpecialShopSubpage"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))
local UnitShopSubpage = require(GameUIModules:WaitForChild("UnitShopSubpage"))

---

local shopSubpages = {
    {
        Name = "Units",
        Image = Style.Images.UnitInventoryIcon,
        Color = Style.Colors.YellowProminentGradient,
        Page = UnitShopSubpage,
    },

    {
        Name = "Special",
        Image = Style.Images.SpecialInventoryIcon,
        Color = Style.Colors.PinkProminentGradient,
        Page = SpecialShopSubpage,
    }
}

---

local ShopPage = Roact.PureComponent:extend("ShopPage")

ShopPage.render = function()
    return Roact.createElement(MainElementContainer, {
        ScaleX = 0.6,
        ScaleY = 0.6,
        AspectRatio = 1.5,

        StrokeGradient = Style.Colors.OrangeProminentGradient,
    }, {
        Header = Roact.createElement(StandardComponents.TextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),

            Text = "Shop",
            TextSize = Style.Constants.PrimaryHeaderTextSize,
        }),

        PageSelector = Roact.createElement(PageSelector, {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, -(Style.Constants.PrimaryHeaderTextSize + Style.Constants.MajorElementPadding)),

            pages = shopSubpages,
        }),
    })
end

return ShopPage