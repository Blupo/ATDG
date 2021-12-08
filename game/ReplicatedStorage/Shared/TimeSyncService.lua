local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local TimeSyncService = require(ReplicatedStorage:WaitForChild("Nevermore"))("TimeSyncService")

TimeSyncService:Init()
return TimeSyncService