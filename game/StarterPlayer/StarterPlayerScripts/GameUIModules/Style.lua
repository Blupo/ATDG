local ContentProvider = game:GetService("ContentProvider")

---

type Style = {
    Constants: {[string]: any},
    Images: {[string]: string},
    Colors: {[string]: Color3 | ColorSequence}
}

local Style: Style = {
    Constants = {
        StandardCornerRadius = 6,
        LargeCornerRadius = 12,

        MajorElementPadding = 16,
        SpaciousElementPadding = 8,
        MinorElementPadding = 4,

        StandardTextSize = 16,
        SecondaryHeaderTextSize = 24,
        PrimaryHeaderTextSize = 40,

        PrimaryFont = Enum.Font.GothamBold,
        SecondaryFont = Enum.Font.Gotham,
        GameStateFont = Enum.Font.FredokaOne,

        InventoryFrameButtonSize = 70,
        MenuButtonSize = 70,
        StandardGradientRotation = 90,
        StandardTextStrokeTransparency = 0.5,
        StandardScrollbarThickness = 12,
        StandardIconSize = 24,

        StandardBorderWidth = 4,
        ProminentBorderWidth = 8,
    },

    Images = {
        -- Attribute icons
        RANGEAttributeIcon = "rbxassetid://6877296872",
        SPDAttributeIcon = "rbxassetid://6869244717",
        CDAttributeIcon = "rbxassetid://6869243794",
        PathTypeAttributeIcon = "rbxassetid://6869214399",
        DEFAttributeIcon = "rbxassetid://6869202551",
        MaxHPAttributeIcon = "rbxassetid://6711444602",
        DMGAttributeIcon = "rbxassetid://6967009882",

        -- Unit shop icons
        UpgradeUnitIcon = "rbxassetid://7539734507",
        SellUnitIcon = "rbxassetid://7198417722",
        PlaceUnitIcon = "rbxassetid://7539733428",

        -- Currency icons
        TicketsCurrencyIcon = "rbxassetid://327284812",
        PointsCurrencyIcon = "rbxassetid://7539615442",

        -- Menu button icons
        GamesPageMenuButtonIcon = "rbxassetid://7728468344",
        ShopPageMenuButtonIcon = "rbxassetid://7198417722",
        InventoryPageMenuButtonIcon = "rbxassetid://6967724371",

        -- Inventory icons
        UnitInventoryIcon = "rbxassetid://466999179",
        SpecialInventoryIcon = "rbxassetid://7447693659",

        -- Unit type icons
        TowerUnitIcon = "rbxassetid://6869202551",
        FieldUnitIcon = "rbxassetid://6869244717",

        -- Stat icons
        TimePlayedStatIcon = "rbxassetid://6869243794",
        TotalDMGStatIcon = "rbxassetid://6967009882",
        UnitAbilityIcon = "rbxassetid://322991119",

        -- Targeting icons
        FirstTargetingIcon = "rbxassetid://8191146567",
        LastTargetingIcon = "rbxassetid://8191146131",
        ClosestTargetingIcon = "rbxassetid://8191147800",
        FarthestTargetingIcon = "rbxassetid://8191147250",
        StrongestTargetingIcon = "rbxassetid://6711444602",
        FastestTargetingIcon = "rbxassetid://6869244717",
        RandomTargetingIcon = "rbxassetid://8191145488",

        -- Special Action icons
        Expel_TESTSpecialActionItemIcon = "rbxassetid://2639289153", -- TEMP
        Boom_TESTSpecialActionItemIcon = "rbxassetid://6967009882", -- TEMP
        ReviveSpecialActionItemIcon = "rbxassetid://6711444602",

        -- Shop hotbar button
        StarFilledIcon = "rbxassetid://7447693659",
        StarOutlineIcon = "rbxassetid://7447694738",

        -- Misc.
        CheckmarkIcon = "rbxassetid://1469818624",
        LoadingIcon = "rbxassetid://6973265105",
        StatComparisonIcon = "rbxassetid://2089572676",
        CloseIcon = "rbxassetid://313526779",
        FocusIcon = "rbxassetid://8192654831",
        AddIcon = "rbxassetid://919844482",
        RemoveIcon = "rbxassetid://6213137847",
        BackpackIcon = "rbxassetid://7728563013",
    },

    Colors = {
        -- Attribute icon colors (TEMP)
        RANGEAttributeIconColor = Color3.fromRGB(0, 170, 255),
        DEFAttributeIconColor = Color3.fromRGB(0, 170, 255),
        SPDAttributeIconColor = Color3.fromRGB(255, 170, 0),
        CDAttributeIconColor = Color3.fromRGB(255, 170, 0),
        MaxHPAttributeIconColor = Color3.new(1, 0, 0),
        DMGAttributeIconColor = Color3.new(1, 0, 0),
        PathTypeAttributeIconColor = Color3.fromRGB(0, 170, 0),

        -- Button colors
        StandardGradient = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(227, 227, 227)),
        FlatGradient = ColorSequence.new(Color3.new(1, 1, 1)),
        StandardButtonColor = Color3.fromRGB(230, 230, 230),
        DestructiveButtonColor = Color3.new(1, 0, 0),
        ConfirmButtonColor = Color3.fromRGB(0, 170, 0),
        DialogButtonColor = Color3.fromRGB(0, 170, 255),
        SelectionColor = Color3.fromRGB(0, 170, 255),
        HotbarButtonColor = Color3.new(1, 1, 0),

        -- Gradients
        YellowProminentGradient = ColorSequence.new(Color3.fromRGB(255, 215, 127), Color3.fromRGB(255, 175, 0)),
        OrangeProminentGradient = ColorSequence.new(Color3.fromRGB(255, 170, 127), Color3.fromRGB(255, 85, 0)),
        RedProminentGradient = ColorSequence.new(Color3.fromRGB(255, 198, 194), Color3.fromRGB(190, 104, 98)),
        PinkProminentGradient = ColorSequence.new(Color3.fromRGB(255, 220, 255), Color3.fromRGB(255, 180, 255)),

        -- Currency icon colors
        TicketsCurrencyColor = Color3.fromRGB(203, 158, 112),
        PointsCurrencyColor = Color3.fromRGB(0, 113, 106),

        -- Unit type icon colors
        TowerUnitIconColor = Color3.fromRGB(0, 170, 255),
        FieldUnitIconColor = Color3.fromRGB(255, 170, 0),

        -- Stat icon colors
        TimePlayedStatColor = Color3.fromRGB(255, 170, 0),
        TotalDMGStatColor = Color3.new(1, 0, 0),
    }
}

---

Style.Constants.StandardButtonHeight = Style.Constants.StandardTextSize + Style.Constants.SpaciousElementPadding
Style.Constants.LargeButtonHeight = Style.Constants.StandardButtonHeight + Style.Constants.SpaciousElementPadding

do
    local preloadImageLabels = {}
    
    for _, image in pairs(Style.Images) do
        local newImageLabel = Instance.new("ImageLabel")

        newImageLabel.Image = image
        table.insert(preloadImageLabels, newImageLabel)
    end

    ContentProvider:PreloadAsync(preloadImageLabels)
end

return Style