local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

---

local setCoreKV = {
    ResetButtonCallback = false,
    PointsNotificationsActive = false,
}

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)

for k, v in pairs(setCoreKV) do
    local success
    
    repeat
        success = pcall(function()
            StarterGui:SetCore(k, v)
        end)
        
        RunService.Heartbeat:Wait()
    until success
end