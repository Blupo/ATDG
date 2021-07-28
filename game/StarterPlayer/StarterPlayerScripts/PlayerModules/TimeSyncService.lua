local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TimeSyncService = require(Shared:WaitForChild("Nevermore"))("TimeSyncService")

TimeSyncService:Init()
return TimeSyncService