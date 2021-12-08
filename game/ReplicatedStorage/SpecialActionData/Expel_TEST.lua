local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    DisplayName = "Expel",

    Limits = {
        [GameEnum.SpecialActionLimitType.PlayerLimit] = 2,
    --  [GameEnum.SpecialActionLimitType.GameLimit] = nil,
        [GameEnum.SpecialActionLimitType.PlayerCooldown] = 120,
    --  [GameEnum.SpecialActionLimitType.GameCooldown] = 120,
    }
}