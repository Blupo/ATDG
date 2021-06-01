-- stylish!

local ContentProvider = game:GetService("ContentProvider")

---

local Style = {
    Constants = {
        StandardCornerRadius = 12,
        SmallCornerRadius = 6,

        UnitViewportFrameSize = 80,
        ButtonIconPaddingRight = 4,
        MajorElementPadding = 16,
        MinorElementPadding = 8,

        TextStrokeTransparency = 0.5,

        MainFont = Enum.Font.GothamBold,
        StateFont = Enum.Font.FredokaOne,
    },

    Images = {

    },

    Colors = {

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