local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local Promise = require(SharedModules:WaitForChild("Promise"))

local GameUIModules = script.Parent
local Animator = require(GameUIModules:WaitForChild("Animator"))
local Otter = require(GameUIModules:WaitForChild("Otter"))
local Roact = require(GameUIModules:WaitForChild("Roact"))
local StandardComponents = require(GameUIModules:WaitForChild("StandardComponents"))
local Style = require(GameUIModules:WaitForChild("Style"))

---

local randomValueInRange = function(min: number, max: number): number
    return ((max - min) * math.random()) + min
end

local scheduleCallback = function(callback, interval)
    local delayPromise = Promise.delay(interval)
    
    delayPromise:andThen(callback)
    return delayPromise
end

---

local LoadingUI = Roact.PureComponent:extend("LoadingUI")

LoadingUI.init = function(self)
    self.animators = {}

    for i = 1, 4 do
        self.animators[i] = Animator.new({
            rotation = 0,
            transparency = 0.5,
        })
    end

    self.transparencyAnimator = Animator.new({
        transparency = 0,
    })

    self.doRotation = function()
        for _, animator in pairs(self.animators) do
            animator.Motor:setGoal({
                rotation = Otter.spring(randomValueInRange(-360, 360), {
                    frequency = randomValueInRange(0.1, 0.5)
                }),
            })
        end
    end

    self.doOutAnimation = function()
        for _, animator in pairs(self.animators) do
            animator.Motor:setGoal({
                transparency = Otter.spring(1)
            })
        end

        self.transparencyAnimator.Motor:setGoal({
            transparency = Otter.spring(1)
        })
    end

    self.scheduleRotation = function()
        self.rotationSchedulePromise = scheduleCallback(function()
            self.doRotation()
            self.scheduleRotation()
        end, 3)
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

LoadingUI.didMount = function(self)
    if (self.props.enabled) then
        self.doRotation()
        self.scheduleRotation()
    end
end

LoadingUI.willUnmount = function(self)
    if (self.rotationSchedulePromise) then
        self.rotationSchedulePromise:cancel()
    end

    for _, animator in pairs(self.animators) do
        animator.Disconnect()
        animator.Motor:destroy()
    end

    self.transparencyAnimator.Disconnect()
    self.transparencyAnimator.Motor:destroy()
end

LoadingUI.didUpdate = function(self, prevProps)
    local thisEnabled = self.props.enabled
    if (thisEnabled == prevProps.enabled) then return end

    if (thisEnabled) then
        self.doRotation()
    else
        if (self.rotationSchedulePromise) then
            self.rotationSchedulePromise:cancel()
            self.rotationSchedulePromise = nil
        end

        self.doOutAnimation()
    end
end

LoadingUI.render = function(self)
    local animationElements = {}

    for i = 1, 4 do
        local animatorBinding = self.animators[i].Binding

        animationElements[i] = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0,
            Size = UDim2.new(math.sqrt(1/2), 0, math.sqrt(1/2), 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),

            BackgroundTransparency = animatorBinding:map(function(values)
                return values.transparency
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

    return Roact.createElement("ScreenGui", {
        DisplayOrder = 10000,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
    }, {
        Background = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BorderSizePixel = 0,

            BackgroundTransparency = self.transparencyAnimator.Binding:map(function(values)
                return values.transparency
            end),

            BackgroundColor3 = Color3.new(0, 0, 0),
        }, {
            UIPadding = Roact.createElement(StandardComponents.UIPadding, { Style.Constants.MajorElementPadding }),

            LoadingText = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(0, 1),
                Size = UDim2.new(1, 0, 0, 48),
                Position = UDim2.new(0, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,

                Text = "Please wait...",
                Font = Style.Constants.PrimaryFont,
                TextSize = 48,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,

                TextTransparency = self.transparencyAnimator.Binding:map(function(values)
                    return values.transparency
                end),
                
                TextColor3 = Color3.new(1, 1, 1),
            }),

            AnimationFrame = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 15),
                Size = UDim2.new(0, 96, 0, 96),
                Position = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, animationElements)
        })
    })
end

return LoadingUI