local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnums"))

---

return {
    [GameEnum.ItemType.SpecialAction] = {
        TEST_SpecialAction = math.huge,
    }
}