local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Button = require(GameUIModules:WaitForChild("Button"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

local GameModules = PlayerScripts:WaitForChild("GameModules")
local Matchmaking = require(GameModules:WaitForChild("Matchmaking"))

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

local StandardScrollingFrame = StandardComponents.ScrollingFrame
local StandardTextLabel = StandardComponents.TextLabel
local StandardUIGridLayout = StandardComponents.UIGridLayout

---

local accessKeys = { "OpenAccess", "ClosedAccess", "FriendsOnly" }

local accessButtonTexts = {
    OpenAccess = "Open Access",
    ClosedAccess = "Closed Access",
    FriendsOnly = "Friends Only",
}

local difficultyDescriptions = {
    [GameEnum.Difficulty.Easy] = "Enemy Units are easier to deal with.",
    [GameEnum.Difficulty.Normal] = "",
    [GameEnum.Difficulty.Hard] = "Enemy Units are more difficult to deal with, and less Points are given at the start of each round.",
}

local difficultyLayoutOrders = {
    [GameEnum.Difficulty.Easy] = 0,
    [GameEnum.Difficulty.Normal] = 1,
    [GameEnum.Difficulty.Hard] = 2,
}

---

local Checkmark = function()
    return Roact.createElement("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, Style.Constants.StandardIconSize, 0, Style.Constants.StandardIconSize),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        Image = Style.Images.CheckmarkIcon,
        ImageColor3 = Style.Colors.ConfirmButtonColor,
    })
end

---

--[[
    props

        onCreateGame: (string, string, table)
        onCancel: ()
]]

local SimpleGameCreationPage = Roact.PureComponent:extend("SimpleGameCreationPage")

SimpleGameCreationPage.init = function(self)
    self.mapListLength, self.updateMapListLength = Roact.createBinding(0)
    self.hoveredDifficulty, self.updateHoveredDifficulty = Roact.createBinding(nil)

    self:setState({
        mapList = {}
    })
end

SimpleGameCreationPage.didMount = function(self)
    self:setState({
        mapList = Matchmaking.GetMaps()
    })
end

SimpleGameCreationPage.render = function(self)
    local mapList = self.state.mapList
    local selectedMap = self.state.selectedMap
    local selectedDifficulty = self.state.selectedDifficulty
    local selectedAccess = self.state.selectedAccess

    local mapListElements = {}
    local difficultyListElements = {}
    local accessListElements = {}

    for i = 1, #mapList do
        local mapName = mapList[i]

        mapListElements[mapName] = Roact.createElement(Button, {
            LayoutOrder = i,
            BackgroundColor3 = (selectedMap == mapName) and Style.Colors.SelectionColor or Style.Colors.StandardButtonColor,

            displayType = "Children",

            onActivated = function()
                self:setState({
                    selectedMap = (selectedMap == mapName) and Roact.None or mapName,
                })
            end,
        }, {
            MapImage = Roact.createElement("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, -Style.Constants.MajorElementPadding / 2, 1, -Style.Constants.MajorElementPadding / 2),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
                ScaleType = Enum.ScaleType.Crop,

                ImageColor3 = Color3.new(1, 1, 1)
            }, {
                UIGradient = Roact.createElement(StandardComponents.UIGradient),
            }),

            MapName = Roact.createElement(StandardTextLabel, {
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(1, -Style.Constants.MajorElementPadding, 0, -Style.Constants.MajorElementPadding),
                Position = UDim2.new(0.5, 0, 1, -Style.Constants.MajorElementPadding / 2),

                Text = mapName,
                TextStrokeTransparency = 0.5,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Bottom,

                TextColor3 = Color3.new(1, 1, 1),
                TextStrokeColor3 = Color3.new(0, 0, 0)
            })
        })
    end

    for difficulty in pairs(GameEnum.Difficulty) do
        difficultyListElements[difficulty] = (difficulty ~= GameEnum.Difficulty.Special) and
            Roact.createElement(Button, {
                LayoutOrder = difficultyLayoutOrders[difficulty],
                Text = difficulty,
        
                BackgroundColor3 = (selectedDifficulty == difficulty) and Style.Colors.SelectionColor or Style.Colors.StandardButtonColor,
                TextColor3 = (selectedDifficulty == difficulty) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),

                displayType = "Text",

                onMouseEnter = function()
                    self.updateHoveredDifficulty(difficulty)
                end,

                onMouseLeave = function()
                    self.updateHoveredDifficulty(nil)
                end,

                onActivated = function()
                    self:setState({
                        selectedDifficulty = (selectedDifficulty == difficulty) and Roact.None or difficulty,
                    })
                end
            })
        or nil
    end

    for i = 1, #accessKeys do
        local access = accessKeys[i]

        accessListElements[access] = Roact.createElement(Button, {
            LayoutOrder = i,
            Text = accessButtonTexts[access],
    
            BackgroundColor3 = (selectedAccess == access) and Style.Colors.SelectionColor or Style.Colors.StandardButtonColor,
            TextColor3 = (selectedAccess == access) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),

            displayType = "Text",
            onActivated = function()
                self:setState({
                    selectedAccess = access
                })
            end
        })
    end

    mapListElements.UIGridLayout = Roact.createElement(StandardUIGridLayout, {
        CellSize = UDim2.new(0.5, -Style.Constants.MajorElementPadding / 2, 0, 128),
        SortOrder = Enum.SortOrder.Name,

        [Roact.Change.AbsoluteContentSize] = function(obj)
            self.updateMapListLength(obj.AbsoluteContentSize.Y)
        end
    }, {
        UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
            AspectRatio = 1,
            DominantAxis = Enum.DominantAxis.Width,
        })
    })

    difficultyListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellSize = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.StandardButtonHeight),
    })

    accessListElements.UIGridLayout = Roact.createElement("UIGridLayout", {
        CellSize = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.StandardButtonHeight),
    })

    return Roact.createFragment({
        Header = Roact.createElement(StandardTextLabel, {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, Style.Constants.PrimaryHeaderTextSize),

            Text = "New Game",
            TextSize = Style.Constants.PrimaryHeaderTextSize,
        }),

        ConstructorContainer = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(1, 0, 1, -(Style.Constants.PrimaryHeaderTextSize + Style.Constants.SpaciousElementPadding)),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            MapList = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                Checkmark = (selectedMap) and Roact.createElement(Checkmark) or nil,

                Header = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),

                    Text = "Map List",
                    TextSize = Style.Constants.SecondaryHeaderTextSize,
                }),

                List = Roact.createElement(StandardScrollingFrame, {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    Size = UDim2.new(1, 0, 1, -(Style.Constants.SecondaryHeaderTextSize + Style.Constants.SpaciousElementPadding)),
                }, mapListElements)
            }),

            DifficultySelection = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),                
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0,
                    Style.Constants.SecondaryHeaderTextSize +
                    (Style.Constants.StandardButtonHeight * 2) +
                    (Style.Constants.StandardTextSize * 3) +
                    (Style.Constants.SpaciousElementPadding * 3)
                ),
            }, {
                Checkmark = (selectedDifficulty) and Roact.createElement(Checkmark) or nil,
                
                Header = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),

                    Text = "Difficulty",
                    TextSize = Style.Constants.SecondaryHeaderTextSize,
                }),

                Difficulties = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, Style.Constants.SecondaryHeaderTextSize + Style.Constants.SpaciousElementPadding),
                    Size = UDim2.new(1, 0, 0, (Style.Constants.StandardButtonHeight * 2) + Style.Constants.SpaciousElementPadding),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, difficultyListElements),

                DifficultyDescription = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.StandardTextSize * 3),

                    Text = self.hoveredDifficulty:map(function(difficulty)
                        if (difficulty) then
                            return difficultyDescriptions[difficulty]
                        else
                            return selectedDifficulty and difficultyDescriptions[selectedDifficulty] or ""
                        end
                    end),

                    Font = Style.Constants.SecondaryFont,
                    TextWrapped = true,
                    TextYAlignment = Enum.TextYAlignment.Top,
                })
            }),

            AccessSelection = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Position = UDim2.new(1, 0, 0,
                    Style.Constants.SecondaryHeaderTextSize +
                    (Style.Constants.StandardButtonHeight * 2) +
                    (Style.Constants.StandardTextSize * 3) +
                    (Style.Constants.SpaciousElementPadding * 3)
                ),

                Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0,
                    Style.Constants.SecondaryHeaderTextSize +
                    (Style.Constants.StandardButtonHeight * 2) +
                    (Style.Constants.SpaciousElementPadding * 2)
                ),
            }, {
                Checkmark = (selectedAccess) and Roact.createElement(Checkmark) or nil,

                Header = Roact.createElement(StandardTextLabel, {
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0, Style.Constants.SecondaryHeaderTextSize),

                    Text = "Access",
                    TextSize = Style.Constants.SecondaryHeaderTextSize,
                }),

                Rules = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new(0.5, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, (Style.Constants.StandardButtonHeight * 2) + Style.Constants.SpaciousElementPadding),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, accessListElements),
            }),

            Buttons = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, 0, 1, 0),
                Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 0, Style.Constants.StandardButtonHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, {
                CancelButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 1, 0),
                    Text = "Cancel",

                    displayType = "Text",
                    onActivated = self.props.onCancel,
                }),

                CreateButton = Roact.createElement(Button, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0.5, -Style.Constants.SpaciousElementPadding / 2, 1, 0),
                    Text = "Create Game",

                    BackgroundColor3 = Style.Colors.DialogButtonColor,
                    TextColor3 = Color3.new(1, 1, 1),

                    disabled = (not (selectedMap and selectedDifficulty and selectedAccess)),
                    displayType = "Text",

                    onActivated = function()
                        local accessRules

                        if (selectedAccess == "OpenAccess") then
                            accessRules = {
                                ApprovalType = GameEnum.GameAccessApprovalType.AutomaticApproval,
                                Ruleset = {},
                            }
                        elseif (selectedAccess == "ClosedAccess") then
                            accessRules = {
                                ApprovalType = GameEnum.GameAccessApprovalType.ManualApproval,
                                Ruleset = {},
                            }
                        elseif (selectedAccess == "FriendsOnly") then
                            accessRules = {
                                ApprovalType = GameEnum.GameAccessApprovalType.AutoRuleset,

                                Ruleset = {
                                    { RuleType = GameEnum.GameAccessRuleType.ApproveFriends, },
                                    { RuleType = GameEnum.GameAccessRuleType.Reject, }
                                },
                            }
                        end

                        self.props.onCreateGame(selectedMap, selectedDifficulty, accessRules)
                    end,
                })
            }),
        })
    })
end

return SimpleGameCreationPage