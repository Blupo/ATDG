local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))

---

return {
	TestTowerUnit = GameEnums.SurfaceType.Terrain,
	TestHeavyTowerUnit = GameEnums.SurfaceType.Terrain,
}