local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    Rounds = {
        [1] = {
            Length = 86400,
            
            SpawnSequence = {
                [0] = { AnimationTest = { [1] = 1, } },
                [2] = { AnimationTest = { [1] = 1, } },
                [4] = { AnimationTest = { [1] = 1, } },
                [6] = { AnimationTest = { [1] = 1, } },
                [8] = { AnimationTest = { [1] = 1, } },
                [10] = { AnimationTest = { [1] = 1, } },
            }
        }
    },
    
    PointsAllowance = {
        [0] = 0,
        [1] = 0,
    },
    
    TicketRewards = {
        [1] = 0,

        Completion = 0,
    },
    
    Abilities = {},
    AttributeModifiers = {},
    StatusEffects = {},
}