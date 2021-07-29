local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	TestTowerUnit = GameEnum.SurfaceType.Terrain,
	TestHeavyTowerUnit = GameEnum.SurfaceType.Terrain,
	TestAoETowerUnit = GameEnum.SurfaceType.Terrain,
}