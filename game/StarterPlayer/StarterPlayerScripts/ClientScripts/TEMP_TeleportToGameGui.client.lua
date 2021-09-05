local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

---

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

---

local TeleportGui = Instance.new("ScreenGui")
TeleportGui.Name = script.Name
TeleportGui.ResetOnSpawn = false

local TeleportButton = Instance.new("TextButton")
TeleportButton.Name = "TeleportButton"
TeleportButton.AnchorPoint = Vector2.new(1, 0.5)
TeleportButton.Size = UDim2.new(0, 150, 0, 24)
TeleportButton.Position = UDim2.new(1, -16, 0.5, 0)
TeleportButton.BackgroundTransparency = 0
TeleportButton.BorderSizePixel = 0
TeleportButton.Text = "Teleport to Game"
TeleportButton.Font = Enum.Font.GothamBold
TeleportButton.TextSize = 16
TeleportButton.TextColor3 = Color3.new(0, 0, 0)
TeleportButton.BackgroundColor3 = Color3.new(1, 1, 1)
TeleportButton.Parent = TeleportGui

local RoundedCorners = Instance.new("UICorner")
RoundedCorners.CornerRadius = UDim.new(0, 6)
RoundedCorners.Parent = TeleportButton

TeleportButton.Activated:Connect(function()
    TeleportService:Teleport(6432648941)
end)

TeleportGui.Parent = PlayerGui