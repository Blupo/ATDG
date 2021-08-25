-- stylish!

local ContentProvider = game:GetService("ContentProvider")

---

local Style = {
    Constants = {
        StandardCornerRadius = 12,
        SmallCornerRadius = 6,

        ObjectViewportFrameSize = 80,
        ButtonIconPaddingRight = 4,
        MajorElementPadding = 16,
        MinorElementPadding = 8,

        TextStrokeTransparency = 0.5,

        MainFont = Enum.Font.GothamBold,
        StateFont = Enum.Font.FredokaOne,
    },

    Images = {
        -- temp icons
        RANGEAttributeIcon = "rbxassetid://6877296872",
        SPDAttributeIcon = "rbxassetid://6869244717",
        CDAttributeIcon = "rbxassetid://6869243794",
        PathTypeAttributeIcon = "rbxassetid://6869214399",
        DEFAttributeIcon = "rbxassetid://6869202551",
        MaxHPAttributeIcon = "rbxassetid://6711444602",
        DMGAttributeIcon = "rbxassetid://6967009882",

        InventoryIcon = "rbxassetid://6967724371",
        --
    },

    Colors = {
        -- temp colors
        RANGEAttributeIconColor = Color3.fromRGB(0, 170, 255),
        DEFAttributeIconColor = Color3.fromRGB(0, 170, 255),

        SPDAttributeIconColor = Color3.fromRGB(255, 170, 0),
        CDAttributeIconColor = Color3.fromRGB(255, 170, 0),

        MaxHPAttributeIconColor = Color3.new(1, 0, 0),
        DMGAttributeIconColor = Color3.new(1, 0, 0),

        PathTypeAttributeIconColor = Color3.fromRGB(0, 170, 0),
        --
    }
}

---

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