local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

---

local Terrain = Workspace.Terrain

---

local tweenInfo = {
    In = TweenInfo.new(0.3, Enum.EasingStyle.Exponential),
    Out1 = TweenInfo.new(0.05, Enum.EasingStyle.Exponential),
    Out2 = TweenInfo.new(0.5, Enum.EasingStyle.Exponential),
}

---

return {
    OnHit = function(_, targetUnit)
        local targetUnitModel = targetUnit.Model
        local orientation, size = targetUnitModel:GetBoundingBox()

        local maxSizeAxis = math.max(size.X, size.Y, size.Z)
        local maxSize = Vector3.new(maxSizeAxis, maxSizeAxis, maxSizeAxis) * math.sqrt(2)

        local auraPart = Instance.new("Part")
        auraPart.Size = maxSize * 0.5
        auraPart.CFrame = orientation
        auraPart.Transparency = 1
        auraPart.Material = Enum.Material.ForceField
        auraPart.Shape = Enum.PartType.Ball
        auraPart.Color = Color3.new(0, 0, 0)
        auraPart.Anchored = true
        auraPart.CanCollide = false
        auraPart.CanTouch = false
        auraPart.CastShadow = false
        auraPart.Parent = Terrain

        local inTween = TweenService:Create(auraPart, tweenInfo.In, {
            Size = maxSize,
            Transparency = -3,
        })

        local outTween1 = TweenService:Create(auraPart, tweenInfo.Out1, {
            Size = Vector3.new(0.15, 0.15, 0.15),
            Transparency = -10,
        })

        local outTween2 = TweenService:Create(auraPart, tweenInfo.Out2, {
            Transparency = 1,
        })

        inTween:Play()
        inTween.Completed:Wait()
        task.wait(0.5)
        outTween1:Play()
        outTween1.Completed:Wait()
        task.wait(0.25)
        outTween2:Play()
        outTween2.Completed:Wait()
        auraPart:Destroy()
    end,
}