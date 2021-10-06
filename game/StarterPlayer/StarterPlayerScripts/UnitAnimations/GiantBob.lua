local UnitAnimations = script.Parent
local SharedAnimations = UnitAnimations:WaitForChild("Shared")
local FaceUnit = require(SharedAnimations:WaitForChild("FaceUnit"))

return {
    OnHit = FaceUnit
}