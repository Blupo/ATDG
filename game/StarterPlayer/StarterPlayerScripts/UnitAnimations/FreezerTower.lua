-- TODO: Replace placeholder animations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local Promise = require(SharedModules:WaitForChild("Promise"))

---

local TWEEN_INFO = TweenInfo.new(0.75, Enum.EasingStyle.Quint)

local animationPromises = {}

---

return {
    OnAdded = function(unit)
        local unitModel = unit.Model
        local Crystal = unitModel:FindFirstChild("Crystal")

        local snowflakeBillboard = Instance.new("BillboardGui")
        snowflakeBillboard.Name = "SnowflakeBillboard"
        snowflakeBillboard.Size = UDim2.new(0, 0, 0, 0)
        snowflakeBillboard.Brightness = 1
        snowflakeBillboard.LightInfluence = 0

        local snowflake = Instance.new("ImageLabel")
        snowflake.Name = "Snowflake"
        snowflake.Size = UDim2.new(1, 0, 1, 0)
        snowflake.BackgroundTransparency = 1
        snowflake.Image = "rbxassetid://335025564"
        snowflake.ImageColor3 = Color3.fromRGB(110, 153, 202)
        snowflake.ImageTransparency = 0.75

        snowflake.Parent = snowflakeBillboard
        snowflakeBillboard.Parent = Crystal
    end,

    OnRemoving = function(unit)
        local unitId = unit.Id
        local animationPromise = animationPromises[unitId]

        if (animationPromise) then
            animationPromise:cancel()
            animationPromises[unitId] = nil
        end
    end,

    OnFired = function(unit)
        local unitId = unit.Id

        local Crystal = unit.Model:FindFirstChild("Crystal")
        local SnowflakeBillboard = Crystal:FindFirstChild("SnowflakeBillboard")
        if (not SnowflakeBillboard) then return end
        
        local Snowflake = SnowflakeBillboard:FindFirstChild("Snowflake")

        if (animationPromises[unitId]) then
            animationPromises[unitId]:cancel()
            animationPromises[unitId] = nil
        end

        local range = unit:GetAttribute("RANGE")

        local billboardTween = TweenService:Create(SnowflakeBillboard, TWEEN_INFO, {
            Size = UDim2.new(range * 2, 0, range * 2, 0)
        })

        local snowflakeTween = TweenService:Create(Snowflake, TWEEN_INFO, {
            ImageTransparency = 1,
        })

        local animationPromise = Promise.new(function(resolve, _, onCancel)
            onCancel(function()
                billboardTween:Cancel()
                snowflakeTween:Cancel()
            end)

            billboardTween:Play()
            task.wait(TWEEN_INFO.Time / 2)
            snowflakeTween:Play()
            snowflakeTween.Completed:Wait()

            resolve()
        end)
        
        animationPromise:finally(function()
            SnowflakeBillboard.Size = UDim2.new(0, 0, 0, 0)
            Snowflake.ImageTransparency = 0.75

            billboardTween:Destroy()
            snowflakeTween:Destroy()
            animationPromises[unitId] = nil
        end)

        animationPromises[unitId] = animationPromise
    end,
}