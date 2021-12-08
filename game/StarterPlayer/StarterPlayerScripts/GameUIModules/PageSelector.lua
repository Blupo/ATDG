local GameUIModules = script.Parent

local Button = require(GameUIModules:WaitForChild("Button"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

--[[
    props

        AnchorPoint?
        Position?
        Size?

        pages: array<{
            Name: string,
            Image: string,

            ImageColor3: Color3?,
            Color: ColorSequence,

            Page: Roact.Component,
            PageProps: dictionary<string, any>?
        }>,
]]

local PageSelector = Roact.PureComponent:extend("PageSelector")

PageSelector.init = function(self)
    self:setState({
        currentPage = 1,
    })
end

PageSelector.render = function(self)
    local pages = self.props.pages

    local currentPageIndex = self.state.currentPage
    local currentPage = pages[currentPageIndex]
    local currentPageColorKeypoints = currentPage.Color.Keypoints

    local selectorElements = {
        UIListLayout = Roact.createElement(StandardComponents.UIListLayout, {
            FillDirection = Enum.FillDirection.Horizontal,
        }),
    }

    for i = 1, #pages do
        local category = pages[i]
        local categoryColor = category.Color
        local categoryColorKeypoints = categoryColor.Keypoints

        selectorElements[category.Name] = Roact.createElement(Button, {
            Size = UDim2.new(1 / #pages, -Style.Constants.SpaciousElementPadding + (Style.Constants.SpaciousElementPadding / #pages), 1, 0),
            LayoutOrder = i,

            BackgroundColor3 = Color3.new(1, 1, 1),
            Color = category.Color,

            displayType = "Children",

            onActivated = function()
                self:setState({
                    currentPage = i,
                })
            end,
        }, {
            Icon = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Size = UDim2.new(
                    0, Style.Constants.StandardIconSize + Style.Constants.MinorElementPadding,
                    0, Style.Constants.StandardIconSize + Style.Constants.MinorElementPadding
                ),

                Image = category.Image,
                ScaleType = Enum.ScaleType.Fit,

                ImageColor3 = category.ImageColor3 or Color3.new(1, 1, 1),
            }),

            Tab = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, -Style.Constants.MajorElementPadding, 0, Style.Constants.SpaciousElementPadding),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,

                BackgroundColor3 = categoryColorKeypoints[#categoryColorKeypoints].Value,
            })
        })
    end

    return Roact.createElement("Frame", {
        AnchorPoint = self.props.AnchorPoint,
        Position = self.props.Position,
        Size = self.props.Size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Selector = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.LargeButtonHeight),

            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, selectorElements),

        Page = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, -(Style.Constants.LargeButtonHeight + Style.Constants.SpaciousElementPadding)),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,

            BackgroundColor3 = currentPageColorKeypoints[#currentPageColorKeypoints].Value,
        }, {
            UICorner = Roact.createElement(StandardComponents.UICorner),
            UIPadding = Roact.createElement(StandardComponents.UIPadding),
            Subpage = Roact.createElement(currentPage.Page, currentPage.PageProps),
        })
    })
end

return PageSelector