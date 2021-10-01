local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
    Rounds = {
        [1] = {
            Length = 120,
            
            SpawnSequence = {
                [0] = { Treasure_Zombie = { [1] = 1, } },
                [1] = { Treasure_Zombie = { [1] = 1, } },
                [2] = { Treasure_Zombie = { [1] = 1, } },
                [3] = { Treasure_Zombie = { [1] = 1, } },
            }
        },

        [2] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Treasure_Zombie = { [1] = 1, } },
                [1] = { Treasure_Zombie = { [1] = 1, } },
                [2] = { Treasure_Zombie = { [1] = 1, } },
                [3] = { Treasure_Zombie = { [1] = 1, } },
                
                [8] = { Treasure_Zombie = { [1] = 1, } },
                [9] = { Treasure_Zombie = { [1] = 1, } },
                [10] = { Treasure_Zombie = { [1] = 1, } },
                [11] = { Treasure_Zombie = { [1] = 1, } },
            }
        },

        [3] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Thief = { [1] = 1, } },
                [1] = { Treasure_Zombie = { [1] = 1, } },
                [2] = { Thief = { [1] = 1, } },
                [3] = { Treasure_Zombie = { [1] = 1, } },
                [4] = { Thief = { [1] = 1, } },
                [5] = { Treasure_Zombie = { [1] = 1, } },
            }
        },

        [4] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Thief = { [1] = 1, } },
                [1] = { Treasure_Zombie = { [1] = 1, } },
                [2] = { Thief = { [1] = 1, } },
                [3] = { Treasure_Zombie = { [1] = 1, } },
                [4] = { Thief = { [1] = 1, } },
                [5] = { Treasure_Zombie = { [1] = 1, } },

                [10] = { Treasure_Zombie = { [1] = 1, } },
                [10.2] = { Treasure_Zombie = { [1] = 1, } },
                [10.4] = { Treasure_Zombie = { [1] = 1, } },
                [10.6] = { Treasure_Zombie = { [1] = 1, } },
                [10.8] = { Treasure_Zombie = { [1] = 1, } },
                [11] = { Treasure_Zombie = { [1] = 1, } },
            }
        },

        [5] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Thief = { [1] = 1, } },
                [1] = { Thief = { [1] = 1, } },
                [2] = { Thief = { [1] = 1, } },
                [3] = { Thief = { [1] = 1, } },
                [4] = { Thief = { [1] = 1, } },
                [5] = { Thief = { [1] = 1, } },

                [15] = { Treasure_Zombie = { [1] = 1, } },
                [15.2] = { Treasure_Zombie = { [1] = 1, } },
                [15.4] = { Treasure_Zombie = { [1] = 1, } },
                [15.6] = { Treasure_Zombie = { [1] = 1, } },
                [15.8] = { Treasure_Zombie = { [1] = 1, } },
                [16] = { Treasure_Zombie = { [1] = 1, } },

                [20] = { EliteThief = { [1] = 1, } },
            }
        },

        [6] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Treasure_Zombie = { [1] = 1, } },
                [1] = { Treasure_Zombie = { [1] = 1, } },
                [2] = { Thief = { [1] = 1, } },
                [3] = { Thief = { [1] = 1, } },
                [4] = { Thief = { [1] = 1, } },
                [5] = { Thief = { [1] = 1, } },

                [10] = { EliteThief = { [1] = 1, } },
                [11] = { EliteThief = { [1] = 1, } },
            }
        },

        [7] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Thief = { [1] = 1, } },
                [1] = { Thief = { [1] = 1, } },
                [2] = { Thief = { [1] = 1, } },
                [3] = { Thief = { [1] = 1, } },
                [4] = { Thief = { [1] = 1, } },
                [5] = { Thief = { [1] = 1, } },
                [6] = { EliteThief = { [1] = 1, } },
                [7] = { EliteThief = { [1] = 1, } },

                [20] = { Treasure_Zombie = { [1] = 1, } },
                [21] = { Treasure_Zombie = { [1] = 1, } },
                [22] = { Treasure_Zombie = { [1] = 1, } },
                [23] = { Treasure_Zombie = { [1] = 1, } },
                [24] = { Treasure_Zombie = { [1] = 1, } },
                [25] = { Treasure_Zombie = { [1] = 1, } },
                [26] = { Treasure_Zombie = { [1] = 1, } },
                [27] = { Treasure_Zombie = { [1] = 1, } },
                [28] = { Treasure_Zombie = { [1] = 1, } },
                [29] = { Treasure_Zombie = { [1] = 1, } },
                [30] = { Treasure_Zombie = { [1] = 1, } },
            }
        },

        [8] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Thief = { [1] = 1, } },
                [0.5] = { EliteThief = { [1] = 1, } },
                [1] = { Thief = { [1] = 1, } },
                [1.5] = { EliteThief = { [1] = 1, } },
                [2] = { Thief = { [1] = 1, } },
                [2.5] = { EliteThief = { [1] = 1, } },
                [3] = { Thief = { [1] = 1, } },
                [3.5] = { EliteThief = { [1] = 1, } },
                [4] = { Thief = { [1] = 1, } },
                [4.5] = { EliteThief = { [1] = 1, } },
                [5] = { Thief = { [1] = 1, } },
                [5.5] = { EliteThief = { [1] = 1, } },
                [6] = { Thief = { [1] = 1, } },
                [6.5] = { EliteThief = { [1] = 1, } },
                [7] = { Thief = { [1] = 1, } },
                [7.5] = { EliteThief = { [1] = 1, } },
                [8] = { Thief = { [1] = 1, } },
                [8.5] = { EliteThief = { [1] = 1, } },
                [9] = { Thief = { [1] = 1, } },
                [9.5] = { EliteThief = { [1] = 1, } },
                [10] = { Thief = { [1] = 1, } },
                [10.5] = { EliteThief = { [1] = 1, } },
                [11] = { Thief = { [1] = 1, } },
                [11.5] = { EliteThief = { [1] = 1, } },
                [12] = { Thief = { [1] = 1, } },
                [12.5] = { EliteThief = { [1] = 1, } },
                [13] = { Thief = { [1] = 1, } },
                [13.5] = { EliteThief = { [1] = 1, } },
                [14] = { Thief = { [1] = 1, } },
                [14.5] = { EliteThief = { [1] = 1, } },
                [15] = { Thief = { [1] = 1, } },
                [15.5] = { EliteThief = { [1] = 1, } },
            }
        },

        [9] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Treasure_Zombie = { [1] = 10 } },
                [5] = { EliteThief = { [1] = 1 } },
                [6] = { EliteThief = { [1] = 1 } },
                [7] = { EliteThief = { [1] = 1 } },

                [10] = { Treasure_Zombie = { [1] = 10 } },
                [15] = { EliteThief = { [1] = 1 } },
                [16] = { EliteThief = { [1] = 1 } },
                [17] = { EliteThief = { [1] = 1 } },

                [20] = { EliteThief = { [1] = 1 } },
                [21] = { EliteThief = { [1] = 1 } },
                [22] = { EliteThief = { [1] = 1 } },
                [23] = { EliteThief = { [1] = 1 } },
                [24] = { EliteThief = { [1] = 1 } },
                [25] = { EliteThief = { [1] = 1 } },
                [26] = { EliteThief = { [1] = 1 } },
                [27] = { EliteThief = { [1] = 1 } },
                [28] = { EliteThief = { [1] = 1 } },
                [29] = { EliteThief = { [1] = 1 } },
                [30] = { EliteThief = { [1] = 1 } },
            }
        },

        [10] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Treasure_Zombie = { [1] = 10 } },
                [3] = { Treasure_Zombie = { [1] = 10 } },
                [5] = { Treasure_Zombie = { [1] = 10 } },
                [7] = { Treasure_Zombie = { [1] = 10 } },

                [20] = { Treasure_Zombie = { [1] = 10 } },
                [23] = { Treasure_Zombie = { [1] = 10 } },
                [25] = { Treasure_Zombie = { [1] = 10 } },
                [27] = { Treasure_Zombie = { [1] = 10 } },
                
                [30] = { EliteThief = { [1] = 1 } },
            }
        },
    },
    
    PointsAllowance = {
        [0] = 600,
        [1] = 100,
        [2] = 200,
        [4] = 300,
        [6] = 600,
        [9] = 800,
    },
    
    TicketRewards = {
        [2] = 1,
        [5] = 3,
        [7] = 5,
        [9] = 8,
        
        Completion = 10,
    },
    
    Abilities = {},
    AttributeModifiers = {},
    StatusEffects = {},
}