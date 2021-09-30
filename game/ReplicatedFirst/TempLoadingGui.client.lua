local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

---

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

---

local tempLoadingGui = Instance.new("ScreenGui")
tempLoadingGui.Name = "TempLoadingGui"
tempLoadingGui.DisplayOrder = 9999
tempLoadingGui.IgnoreGuiInset = true
tempLoadingGui.ResetOnSpawn = false

local bkgFrame = Instance.new("Frame")
bkgFrame.Size = UDim2.new(1, 0, 1, 0)
bkgFrame.BorderSizePixel = 0
bkgFrame.BackgroundColor3 = Color3.new(0, 0, 0)
bkgFrame.Parent = tempLoadingGui

---

tempLoadingGui.Parent = PlayerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

if (not game:IsLoaded()) then
    game.Loaded:Wait()
end

PlayerGui:WaitForChild("LoadingGui")
tempLoadingGui:Destroy()