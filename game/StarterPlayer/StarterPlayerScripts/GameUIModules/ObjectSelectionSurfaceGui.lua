local Players = game:GetService("Players")

---

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local GameUIModules = PlayerScripts:WaitForChild("GameUIModules")
local Animator = require(GameUIModules:WaitForChild("Animator"))
local Otter = require(GameUIModules:WaitForChild("Otter"))
local Roact = require(GameUIModules:WaitForChild("Roact"))

---

local randomValueInRange = function(min: number, max: number): number
    return ((max - min) * math.random()) + min
end

---

--[[
    props

        Adornee

        enabled: boolean
]]

local ObjectSelectionSurfaceGui = Roact.PureComponent:extend("ObjectSelectionSurfaceGui")

ObjectSelectionSurfaceGui.init = function(self)
    self.animators = {}

    for i = 1, 4 do
        self.animators[i] = Animator.new({
            rotation = randomValueInRange(-360, 360),
            size = 0,
            x = randomValueInRange(0.2, 0.8),
            y = randomValueInRange(0.2, 0.8),
        })
    end

    self.doInAnimation = function()
        for _, animator in pairs(self.animators) do
            animator.Motor:setGoal({
                rotation = Otter.spring(randomValueInRange(-360, 360), {
                    frequency = randomValueInRange(0.1, 0.5)
                }),

                size = Otter.spring(math.sqrt(1/2)),
                x = Otter.spring(0.5),
                y = Otter.spring(0.5)
            })
        end
    end

    self.doOutAnimation = function()
        for _, animator in pairs(self.animators) do
            animator.Motor:setGoal({
                rotation = Otter.spring(randomValueInRange(-360, 360)),
                size = Otter.spring(0),
                x = Otter.spring(randomValueInRange(0.2, 0.8)),
                y = Otter.spring(randomValueInRange(0.2, 0.8))
            })
        end
    end

    self:setState({
        animatorColors = {
            Color3.fromHSV(math.random(), 1, 1),
            Color3.fromHSV(math.random(), 1, 1),
            Color3.fromHSV(math.random(), 1, 1),
            Color3.fromHSV(math.random(), 1, 1),
        },
    })
end

ObjectSelectionSurfaceGui.didMount = function(self)
    if (self.props.enabled) then
        self.doInAnimation()
    end
end

ObjectSelectionSurfaceGui.didUpdate = function(self, prevProps)
    if (self.props.enabled == prevProps.enabled) then return end

    if (self.props.enabled) then
        self:setState({
            animatorColors = {
                Color3.fromHSV(math.random(), 1, 1),
                Color3.fromHSV(math.random(), 1, 1),
                Color3.fromHSV(math.random(), 1, 1),
                Color3.fromHSV(math.random(), 1, 1),
            },
        })

        self.doInAnimation()
    else
        self.doOutAnimation()
    end
end

ObjectSelectionSurfaceGui.willUnmount = function(self)
    for _, animator in pairs(self.animators) do
        animator.Disconnect()
        animator.Motor:destroy()
    end
end

ObjectSelectionSurfaceGui.render = function(self)
    local animatorElements = {}

    for i = 1, 4 do
        local animatorBinding = self.animators[i].Binding

        animatorElements[i] = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            BackgroundTransparency = 0.5,

            Position = animatorBinding:map(function(values)
                return UDim2.new(values.x, 0, values.y, 0)
            end),

            Size = animatorBinding:map(function(values)
                return UDim2.new(values.size, 0, values.size, 0)
            end),

            Rotation = animatorBinding:map(function(values)
                return values.rotation
            end),

            BackgroundColor3 = self.state.animatorColors[i]
        }, {
            UICorner = Roact.createElement("UICorner", {
                CornerRadius = UDim.new(0.12, 0)
            })
        })
    end

    return Roact.createElement("SurfaceGui", {
        Adornee = self.props.Adornee,
        PixelsPerStud = 100,
        LightInfluence = 1,
        ResetOnSpawn = false,
        ClipsDescendants = true,
        Face = Enum.NormalId.Top,
        SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
    }, animatorElements)
end

---

return ObjectSelectionSurfaceGui