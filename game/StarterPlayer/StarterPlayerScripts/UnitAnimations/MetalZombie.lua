local UnitAnimations = script.Parent
local SharedAnimations = UnitAnimations:WaitForChild("Shared")

return require(SharedAnimations:WaitForChild("ZombieAnimations"))