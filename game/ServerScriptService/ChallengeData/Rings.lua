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
                [0] = { Zombie = { [1] = 1 } },
                [1] = { Zombie = { [1] = 1 } },
                [2] = { Zombie = { [1] = 1 } },
                [3] = { Zombie = { [1] = 1 } },
            }
        },

        [2] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Zombie = { [1] = 1 } },
                [1] = { Zombie = { [1] = 1 } },
                [2] = { Zombie = { [1] = 1 } },
                [3] = { Zombie = { [1] = 1 } },
                [4] = { TinyZombie = { [1] = 1 } },
                [5] = { TinyZombie = { [1] = 1 } },
                [6] = { TinyZombie = { [1] = 1 } },
                [7] = { TinyZombie = { [1] = 1 } },
            }
        },

        [3] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Zombie = { [1] = 1 } },
                [1] = { Zombie = { [1] = 1 } },
                [2] = { Zombie = { [1] = 1 } },
                [3] = { Zombie = { [1] = 1 } },
                [4] = { TinyZombie = { [1] = 1 } },
                [5] = { TinyZombie = { [1] = 1 } },
                [6] = { IceZombie = { [1] = 1 } },
                [7] = { IceZombie = { [1] = 1 } },
                [8] = { IceZombie = { [1] = 1 } },
                [9] = { IceZombie = { [1] = 1 } },
                [10] = { TinyZombie = { [1] = 1 } },
                [11] = { TinyZombie = { [1] = 1 } },
            }
        },

        [4] = {
            Length = 120,

            SpawnSequence = {
                [0] = { Zombie = { [1] = 1 } },
                [1] = { Zombie = { [1] = 1 } },
                [2] = { Zombie = { [1] = 1 } },
                [3] = { Zombie = { [1] = 1 } },
                [4] = { TinyZombie = { [1] = 1 } },
                [5] = { TinyZombie = { [1] = 1 } },
                [6] = { TinyZombie = { [1] = 1 } },
                [7] = { TinyZombie = { [1] = 1 } },
                [8] = { IceZombie = { [1] = 1 } },
                [9] = { IceZombie = { [1] = 1 } },
                [10] = { IceZombie = { [1] = 1 } },
                [11] = { IceZombie = { [1] = 1 } },
                [12] = { IceZombie = { [1] = 1 } },
                [13] = { IceZombie = { [1] = 1 } },
                [14] = { IceZombie = { [1] = 1 } },
                [15] = { IceZombie = { [1] = 1 } },
            }
        },

        [5] = {
            Length = 120,

            SpawnSequence = {
                [0] = { TinyZombie = { [1] = 1 } },
                [1] = { TinyZombie = { [1] = 1 } },
                [2] = { TinyZombie = { [1] = 1 } },
                [3] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [4] = { TinyZombie = { [1] = 1 } },
                [5] = { TinyZombie = { [1] = 1 } },
                [6] = { TinyZombie = { [1] = 1 } },
                [7] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [8] = { TinyZombie = { [1] = 1 } },
                [9] = { TinyZombie = { [1] = 1 } },
                [10] = { TinyZombie = { [1] = 1 } },
                [11] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [12] = { TinyZombie = { [1] = 1 } },
                [13] = { TinyZombie = { [1] = 1 } },
                [14] = { TinyZombie = { [1] = 1 } },
                [15] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },
            }
        },

        [6] = {
            Length = 120,

            SpawnSequence = {
                [0] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [0.25] = { TinyZombie = { [1] = 1 } },
                [0.5] = { TinyZombie = { [1] = 1 } },
                [0.75] = { TinyZombie = { [1] = 1 } },

                [1] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [1.25] = { TinyZombie = { [1] = 1 } },
                [1.5] = { TinyZombie = { [1] = 1 } },
                [1.75] = { TinyZombie = { [1] = 1 } },
                
                [2] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [2.25] = { TinyZombie = { [1] = 1 } },
                [2.5] = { TinyZombie = { [1] = 1 } },
                [2.75] = { TinyZombie = { [1] = 1 } },
                
                [3] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [3.25] = { TinyZombie = { [1] = 1 } },
                [3.5] = { TinyZombie = { [1] = 1 } },
                [3.75] = { TinyZombie = { [1] = 1 } },
                
                [4] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [4.25] = { TinyZombie = { [1] = 1 } },
                [4.5] = { TinyZombie = { [1] = 1 } },
                [4.75] = { TinyZombie = { [1] = 1 } },
                
                [5] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [5.25] = { TinyZombie = { [1] = 1 } },
                [5.5] = { TinyZombie = { [1] = 1 } },
                [5.75] = { TinyZombie = { [1] = 1 } },                
                
                [6] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [6.25] = { TinyZombie = { [1] = 1 } },
                [6.5] = { TinyZombie = { [1] = 1 } },
                [6.75] = { TinyZombie = { [1] = 1 } },
                
                [7] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [7.25] = { TinyZombie = { [1] = 1 } },
                [7.5] = { TinyZombie = { [1] = 1 } },
                [7.75] = { TinyZombie = { [1] = 1 } },
                
                [8] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [8.25] = { TinyZombie = { [1] = 1 } },
                [8.5] = { TinyZombie = { [1] = 1 } },
                [8.75] = { TinyZombie = { [1] = 1 } },
                
                [9] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [9.25] = { TinyZombie = { [1] = 1 } },
                [9.5] = { TinyZombie = { [1] = 1 } },
                [9.75] = { TinyZombie = { [1] = 1 } },
                
                [10] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [10.25] = { TinyZombie = { [1] = 1 } },
                [10.5] = { TinyZombie = { [1] = 1 } },
                [10.75] = { TinyZombie = { [1] = 1 } },
                
                [11] = {
                    TinyZombie = { [1] = 1 },
                    IceZombie = { [1] = 1 },
                },

                [11.25] = { TinyZombie = { [1] = 1 } },
                [11.5] = { TinyZombie = { [1] = 1 } },
                [11.75] = { TinyZombie = { [1] = 1 } },

                [12] = { MetalZombie = { [1] = 1 } },
            }
        },

        [7] = {
            Length = 120,

            SpawnSequence = {
                [0] = { IceZombie = { [1] = 1 } },
                [0.25] = { IceZombie = { [1] = 1 } },
                [0.5] = { TinyZombie = { [1] = 1 } },
                [0.75] = { TinyZombie = { [1] = 1 } },
                [1] = { IceZombie = { [1] = 1 } },
                [1.25] = { IceZombie = { [1] = 1 } },
                [1.5] = { TinyZombie = { [1] = 1 } },
                [1.75] = { TinyZombie = { [1] = 1 } },
                [2] = { IceZombie = { [1] = 1 } },
                [2.25] = { IceZombie = { [1] = 1 } },
                [2.5] = { TinyZombie = { [1] = 1 } },
                [2.75] = { TinyZombie = { [1] = 1 } },
                [3] = { IceZombie = { [1] = 1 } },
                [3.25] = { IceZombie = { [1] = 1 } },
                [3.5] = { TinyZombie = { [1] = 1 } },
                [3.75] = { TinyZombie = { [1] = 1 } },
                [4] = { IceZombie = { [1] = 1 } },
                [4.25] = { IceZombie = { [1] = 1 } },
                [4.5] = { TinyZombie = { [1] = 1 } },
                [4.75] = { TinyZombie = { [1] = 1 } },
                [5] = { IceZombie = { [1] = 1 } },
                [5.25] = { IceZombie = { [1] = 1 } },
                [5.5] = { TinyZombie = { [1] = 1 } },
                [5.75] = { TinyZombie = { [1] = 1 } },
                [6] = { IceZombie = { [1] = 1 } },
                [6.25] = { IceZombie = { [1] = 1 } },
                [6.5] = { TinyZombie = { [1] = 1 } },
                [6.75] = { TinyZombie = { [1] = 1 } },
                [7] = { IceZombie = { [1] = 1 } },
                [7.25] = { IceZombie = { [1] = 1 } },
                [7.5] = { TinyZombie = { [1] = 1 } },
                [7.75] = { TinyZombie = { [1] = 1 } },
                [8] = { IceZombie = { [1] = 1 } },
                [8.25] = { IceZombie = { [1] = 1 } },
                [8.5] = { TinyZombie = { [1] = 1 } },
                [8.75] = { TinyZombie = { [1] = 1 } },
                [9] = { IceZombie = { [1] = 1 } },
                [9.25] = { IceZombie = { [1] = 1 } },
                [9.5] = { TinyZombie = { [1] = 1 } },
                [9.75] = { TinyZombie = { [1] = 1 } },

                [10] = { BigZombie = { [1] = 1 } },
                [10.25] = { IceZombie = { [1] = 1 } },
                [10.5] = { TinyZombie = { [1] = 1 } },
                [10.75] = { TinyZombie = { [1] = 1 } },
                [11] = { BigZombie = { [1] = 1 } },
                [11.25] = { IceZombie = { [1] = 1 } },
                [11.5] = { TinyZombie = { [1] = 1 } },
                [11.75] = { TinyZombie = { [1] = 1 } },
                [12] = { BigZombie = { [1] = 1 } },
                [12.25] = { IceZombie = { [1] = 1 } },
                [12.5] = { TinyZombie = { [1] = 1 } },
                [12.75] = { TinyZombie = { [1] = 1 } },
                [13] = { BigZombie = { [1] = 1 } },
                [13.25] = { IceZombie = { [1] = 1 } },
                [13.5] = { TinyZombie = { [1] = 1 } },
                [13.75] = { TinyZombie = { [1] = 1 } },
                [14] = { BigZombie = { [1] = 1 } },
                [14.25] = { IceZombie = { [1] = 1 } },
                [14.5] = { TinyZombie = { [1] = 1 } },
                [14.75] = { TinyZombie = { [1] = 1 } },
                [15] = { GhostlyZombie = { [1] = 1 } },
                [15.25] = { IceZombie = { [1] = 1 } },
                [15.5] = { TinyZombie = { [1] = 1 } },
                [15.75] = { TinyZombie = { [1] = 1 } },
                [16] = { GhostlyZombie = { [1] = 1 } },
                [16.25] = { IceZombie = { [1] = 1 } },
                [16.5] = { TinyZombie = { [1] = 1 } },
                [16.75] = { TinyZombie = { [1] = 1 } },
                [17] = { GhostlyZombie = { [1] = 1 } },
                [17.25] = { IceZombie = { [1] = 1 } },
                [17.5] = { TinyZombie = { [1] = 1 } },
                [17.75] = { TinyZombie = { [1] = 1 } },
                [18] = { GhostlyZombie = { [1] = 1 } },
                [18.25] = { IceZombie = { [1] = 1 } },
                [18.5] = { TinyZombie = { [1] = 1 } },
                [18.75] = { TinyZombie = { [1] = 1 } },
                [19] = { GhostlyZombie = { [1] = 1 } },
                [19.25] = { IceZombie = { [1] = 1 } },
                [19.5] = { TinyZombie = { [1] = 1 } },
                [19.75] = { TinyZombie = { [1] = 1 } },
            }
        },

        [8] = {
            Length = 120,

            SpawnSequence = {
                [0] = { GhostlyZombie = { [1] = 1 } },
                [0.25] = { IceZombie = { [1] = 1 } },
                [0.5] = { IceZombie = { [1] = 1 } },
                [0.75] = { IceZombie = { [1] = 1 } },
                [1] = { GhostlyZombie = { [1] = 1 } },
                [1.25] = { IceZombie = { [1] = 1 } },
                [1.5] = { IceZombie = { [1] = 1 } },
                [1.75] = { IceZombie = { [1] = 1 } },
                [2] = { GhostlyZombie = { [1] = 1 } },
                [2.25] = { IceZombie = { [1] = 1 } },
                [2.5] = { IceZombie = { [1] = 1 } },
                [2.75] = { IceZombie = { [1] = 1 } },
                [3] = { GhostlyZombie = { [1] = 1 } },
                [3.25] = { IceZombie = { [1] = 1 } },
                [3.5] = { IceZombie = { [1] = 1 } },
                [3.75] = { IceZombie = { [1] = 1 } },
                [4] = { GhostlyZombie = { [1] = 1 } },
                [4.25] = { IceZombie = { [1] = 1 } },
                [4.5] = { IceZombie = { [1] = 1 } },
                [4.75] = { IceZombie = { [1] = 1 } },
                [5] = { GhostlyZombie = { [1] = 1 } },
                [5.25] = { IceZombie = { [1] = 1 } },
                [5.5] = { IceZombie = { [1] = 1 } },
                [5.75] = { IceZombie = { [1] = 1 } },
                [6] = { GhostlyZombie = { [1] = 1 } },
                [6.25] = { IceZombie = { [1] = 1 } },
                [6.5] = { IceZombie = { [1] = 1 } },
                [6.75] = { IceZombie = { [1] = 1 } },
                [7] = { GhostlyZombie = { [1] = 1 } },
                [7.25] = { IceZombie = { [1] = 1 } },
                [7.5] = { IceZombie = { [1] = 1 } },
                [7.75] = { IceZombie = { [1] = 1 } },
                [8] = { GhostlyZombie = { [1] = 1 } },
                [8.25] = { IceZombie = { [1] = 1 } },
                [8.5] = { IceZombie = { [1] = 1 } },
                [8.75] = { IceZombie = { [1] = 1 } },
                [9] = { GhostlyZombie = { [1] = 1 } },
                [9.25] = { IceZombie = { [1] = 1 } },
                [9.5] = { IceZombie = { [1] = 1 } },
                [9.75] = { IceZombie = { [1] = 1 } },

                [10] = { BigZombie = { [1] = 1 } },
                [10.25] = { IceZombie = { [1] = 1 } },
                [10.5] = { IceZombie = { [1] = 1 } },
                [10.75] = { IceZombie = { [1] = 1 } },
                [11] = { BigZombie = { [1] = 1 } },
                [11.25] = { IceZombie = { [1] = 1 } },
                [11.5] = { IceZombie = { [1] = 1 } },
                [11.75] = { IceZombie = { [1] = 1 } },
                [12] = { BigZombie = { [1] = 1 } },
                [12.25] = { IceZombie = { [1] = 1 } },
                [12.5] = { IceZombie = { [1] = 1 } },
                [12.75] = { IceZombie = { [1] = 1 } },
                [13] = { BigZombie = { [1] = 1 } },
                [13.25] = { IceZombie = { [1] = 1 } },
                [13.5] = { IceZombie = { [1] = 1 } },
                [13.75] = { IceZombie = { [1] = 1 } },
                [14] = { BigZombie = { [1] = 1 } },
                [14.25] = { IceZombie = { [1] = 1 } },
                [14.5] = { IceZombie = { [1] = 1 } },
                [14.75] = { IceZombie = { [1] = 1 } },
                [15] = { BruteZombie = { [1] = 1 } },
                [15.25] = { IceZombie = { [1] = 1 } },
                [15.5] = { IceZombie = { [1] = 1 } },
                [15.75] = { IceZombie = { [1] = 1 } },
                [16] = { BruteZombie = { [1] = 1 } },
                [16.25] = { IceZombie = { [1] = 1 } },
                [16.5] = { IceZombie = { [1] = 1 } },
                [16.75] = { IceZombie = { [1] = 1 } },
                [17] = { BruteZombie = { [1] = 1 } },
                [17.25] = { IceZombie = { [1] = 1 } },
                [17.5] = { IceZombie = { [1] = 1 } },
                [17.75] = { IceZombie = { [1] = 1 } },
                [18] = { BruteZombie = { [1] = 1 } },
                [18.25] = { IceZombie = { [1] = 1 } },
                [18.5] = { IceZombie = { [1] = 1 } },
                [18.75] = { IceZombie = { [1] = 1 } },
                [19] = { BruteZombie = { [1] = 1 } },
                [19.25] = { IceZombie = { [1] = 1 } },
                [19.5] = { IceZombie = { [1] = 1 } },
                [19.75] = { IceZombie = { [1] = 1 } },

                [20] = { MagmaZombie = { [1] = 1 } },
                [20.25] = { IceZombie = { [1] = 1 } },
                [20.75] = { IceZombie = { [1] = 1 } },
                [21] = { MagmaZombie = { [1] = 1 } },
                [21.25] = { IceZombie = { [1] = 1 } },
                [21.75] = { IceZombie = { [1] = 1 } },
                [22] = { MagmaZombie = { [1] = 1 } },
                [22.25] = { IceZombie = { [1] = 1 } },
                [22.75] = { IceZombie = { [1] = 1 } },
                [23] = { MagmaZombie = { [1] = 1 } },
                [23.25] = { IceZombie = { [1] = 1 } },
                [23.75] = { IceZombie = { [1] = 1 } },
                [24] = { MagmaZombie = { [1] = 1 } },
                [24.25] = { IceZombie = { [1] = 1 } },
                [24.75] = { IceZombie = { [1] = 1 } },
                [25] = { MagmaZombie = { [1] = 1 } },
                [25.25] = { IceZombie = { [1] = 1 } },
                [25.75] = { IceZombie = { [1] = 1 } },
                [26] = { MagmaZombie = { [1] = 1 } },
                [26.25] = { IceZombie = { [1] = 1 } },
                [26.75] = { IceZombie = { [1] = 1 } },
                [27] = { MagmaZombie = { [1] = 1 } },
                [27.25] = { IceZombie = { [1] = 1 } },
                [27.75] = { IceZombie = { [1] = 1 } },
                [28] = { MagmaZombie = { [1] = 1 } },
                [28.25] = { IceZombie = { [1] = 1 } },
                [28.75] = { IceZombie = { [1] = 1 } },
                [29] = { MetalZombie = { [1] = 1 } },
                [29.25] = { IceZombie = { [1] = 1 } },
                [29.75] = { IceZombie = { [1] = 1 } },
            }
        },

        [9] = {
            Length = 120,

            SpawnSequence = {
                [0] = { GhostlyZombie = { [1] = 1 } },
                [0.25] = { GhostlyZombie = { [1] = 1 } },
                [0.5] = { GhostlyZombie = { [1] = 1 } },
                [0.75] = { GhostlyZombie = { [1] = 1 } },
                [1] = { GhostlyZombie = { [1] = 1 } },
                [1.25] = { GhostlyZombie = { [1] = 1 } },
                [1.5] = { GhostlyZombie = { [1] = 1 } },
                [1.75] = { GhostlyZombie = { [1] = 1 } },
                [2] = { GhostlyZombie = { [1] = 1 } },
                [2.25] = { GhostlyZombie = { [1] = 1 } },
                [2.5] = { GhostlyZombie = { [1] = 1 } },
                [2.75] = { GhostlyZombie = { [1] = 1 } },
                [3] = { GhostlyZombie = { [1] = 1 } },
                [3.25] = { GhostlyZombie = { [1] = 1 } },
                [3.5] = { GhostlyZombie = { [1] = 1 } },
                [3.75] = { GhostlyZombie = { [1] = 1 } },
                [4] = { GhostlyZombie = { [1] = 1 } },
                [4.25] = { GhostlyZombie = { [1] = 1 } },
                [4.5] = { GhostlyZombie = { [1] = 1 } },
                [4.75] = { GhostlyZombie = { [1] = 1 } },
                [5] = { GhostlyZombie = { [1] = 1 } },
                [5.25] = { GhostlyZombie = { [1] = 1 } },
                [5.5] = { GhostlyZombie = { [1] = 1 } },
                [5.75] = { GhostlyZombie = { [1] = 1 } },
                [6] = { GhostlyZombie = { [1] = 1 } },
                [6.25] = { GhostlyZombie = { [1] = 1 } },
                [6.5] = { GhostlyZombie = { [1] = 1 } },
                [6.75] = { GhostlyZombie = { [1] = 1 } },
                [7] = { GhostlyZombie = { [1] = 1 } },
                [7.25] = { GhostlyZombie = { [1] = 1 } },
                [7.5] = { GhostlyZombie = { [1] = 1 } },
                [7.75] = { GhostlyZombie = { [1] = 1 } },
                [8] = { GhostlyZombie = { [1] = 1 } },
                [8.25] = { GhostlyZombie = { [1] = 1 } },
                [8.5] = { GhostlyZombie = { [1] = 1 } },
                [8.75] = { GhostlyZombie = { [1] = 1 } },
                [9] = { GhostlyZombie = { [1] = 1 } },
                [9.25] = { GhostlyZombie = { [1] = 1 } },
                [9.5] = { GhostlyZombie = { [1] = 1 } },
                [9.75] = { GhostlyZombie = { [1] = 1 } },

                [10] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [10.25] = { GhostlyZombie = { [1] = 1 } },
                [10.5] = { GhostlyZombie = { [1] = 1 } },
                [10.75] = { GhostlyZombie = { [1] = 1 } },
                
                [11] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [11.25] = { GhostlyZombie = { [1] = 1 } },
                [11.5] = { GhostlyZombie = { [1] = 1 } },
                [11.75] = { GhostlyZombie = { [1] = 1 } },
                
                [12] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [12.25] = { GhostlyZombie = { [1] = 1 } },
                [12.5] = { GhostlyZombie = { [1] = 1 } },
                [12.75] = { GhostlyZombie = { [1] = 1 } },
                
                [13] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [13.25] = { GhostlyZombie = { [1] = 1 } },
                [13.5] = { GhostlyZombie = { [1] = 1 } },
                [13.75] = { GhostlyZombie = { [1] = 1 } },
                
                [14] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [14.25] = { GhostlyZombie = { [1] = 1 } },
                [14.5] = { GhostlyZombie = { [1] = 1 } },
                [14.75] = { GhostlyZombie = { [1] = 1 } },
                
                [15] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [15.25] = { GhostlyZombie = { [1] = 1 } },
                [15.5] = { GhostlyZombie = { [1] = 1 } },
                [15.75] = { GhostlyZombie = { [1] = 1 } },
                
                [16] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [16.25] = { GhostlyZombie = { [1] = 1 } },
                [16.5] = { GhostlyZombie = { [1] = 1 } },
                [16.75] = { GhostlyZombie = { [1] = 1 } },
                
                [17] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [17.25] = { GhostlyZombie = { [1] = 1 } },
                [17.5] = { GhostlyZombie = { [1] = 1 } },
                [17.75] = { GhostlyZombie = { [1] = 1 } },
                
                [18] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [18.25] = { GhostlyZombie = { [1] = 1 } },
                [18.5] = { GhostlyZombie = { [1] = 1 } },
                [18.75] = { GhostlyZombie = { [1] = 1 } },
                
                [19] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [19.25] = { GhostlyZombie = { [1] = 1 } },
                [19.5] = { GhostlyZombie = { [1] = 1 } },
                [19.75] = { GhostlyZombie = { [1] = 1 } },

                [20] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [20.25] = { GhostlyZombie = { [1] = 1 } },
                [20.5] = { GhostlyZombie = { [1] = 1 } },
                [20.75] = { GhostlyZombie = { [1] = 1 } },
                
                [21] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [21.25] = { GhostlyZombie = { [1] = 1 } },
                [21.5] = { GhostlyZombie = { [1] = 1 } },
                [21.75] = { GhostlyZombie = { [1] = 1 } },
                
                [22] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [22.25] = { GhostlyZombie = { [1] = 1 } },
                [22.5] = { GhostlyZombie = { [1] = 1 } },
                [22.75] = { GhostlyZombie = { [1] = 1 } },
                
                [23] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [23.25] = { GhostlyZombie = { [1] = 1 } },
                [23.5] = { GhostlyZombie = { [1] = 1 } },
                [23.75] = { GhostlyZombie = { [1] = 1 } },
                
                [24] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [24.25] = { GhostlyZombie = { [1] = 1 } },
                [24.5] = { GhostlyZombie = { [1] = 1 } },
                [24.75] = { GhostlyZombie = { [1] = 1 } },
                
                [25] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [25.25] = { MagmaZombie = { [1] = 1 } },
                [25.5] = { MagmaZombie = { [1] = 1 } },
                [25.75] = { MagmaZombie = { [1] = 1 } },
                
                [26] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [26.25] = { MagmaZombie = { [1] = 1 } },
                [26.5] = { MagmaZombie = { [1] = 1 } },
                [26.75] = { MagmaZombie = { [1] = 1 } },
                
                [27] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [27.25] = { MagmaZombie = { [1] = 1 } },
                [27.5] = { MagmaZombie = { [1] = 1 } },
                [27.75] = { MagmaZombie = { [1] = 1 } },
                
                [28] = {
                    MagmaZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [28.25] = { MagmaZombie = { [1] = 1 } },
                [28.5] = { MagmaZombie = { [1] = 1 } },
                [28.75] = { MagmaZombie = { [1] = 1 } },
                
                [29] = {
                    MetalZombie = { [1] = 1 },
                    BruteZombie = { [1] = 1 },
                },

                [29.25] = { MagmaZombie = { [1] = 1 } },
                [29.5] = { MagmaZombie = { [1] = 1 } },
                [29.75] = { MagmaZombie = { [1] = 1 } },
            }
        },

        [10] = {
            Length = 120,

            SpawnSequence = {
                [0] = { MagmaZombie = { [1] = 1 } },
                [0.25] = { MagmaZombie = { [1] = 1 } },
                [0.5] = { MagmaZombie = { [1] = 1 } },
                [0.75] = { MagmaZombie = { [1] = 1 } },
                [1] = { MagmaZombie = { [1] = 1 } },
                [1.25] = { MagmaZombie = { [1] = 1 } },
                [1.5] = { MagmaZombie = { [1] = 1 } },
                [1.75] = { MagmaZombie = { [1] = 1 } },
                [2] = { MagmaZombie = { [1] = 1 } },
                [2.25] = { MagmaZombie = { [1] = 1 } },
                [2.5] = { MagmaZombie = { [1] = 1 } },
                [2.75] = { MagmaZombie = { [1] = 1 } },
                [3] = { MagmaZombie = { [1] = 1 } },
                [3.25] = { MagmaZombie = { [1] = 1 } },
                [3.5] = { MagmaZombie = { [1] = 1 } },
                [3.75] = { MagmaZombie = { [1] = 1 } },
                [4] = { MagmaZombie = { [1] = 1 } },
                [4.25] = { MagmaZombie = { [1] = 1 } },
                [4.5] = { MagmaZombie = { [1] = 1 } },
                [4.75] = { MagmaZombie = { [1] = 1 } },
                [5] = { MagmaZombie = { [1] = 1 } },
                [5.25] = { MagmaZombie = { [1] = 1 } },
                [5.5] = { MagmaZombie = { [1] = 1 } },
                [5.75] = { MagmaZombie = { [1] = 1 } },
                [6] = { MagmaZombie = { [1] = 1 } },
                [6.25] = { MagmaZombie = { [1] = 1 } },
                [6.5] = { MagmaZombie = { [1] = 1 } },
                [6.75] = { MagmaZombie = { [1] = 1 } },
                [7] = { MagmaZombie = { [1] = 1 } },
                [7.25] = { MagmaZombie = { [1] = 1 } },
                [7.5] = { MagmaZombie = { [1] = 1 } },
                [7.75] = { MagmaZombie = { [1] = 1 } },
                [8] = { MagmaZombie = { [1] = 1 } },
                [8.25] = { MagmaZombie = { [1] = 1 } },
                [8.5] = { MagmaZombie = { [1] = 1 } },
                [8.75] = { MagmaZombie = { [1] = 1 } },
                [9] = { MagmaZombie = { [1] = 1 } },
                [9.25] = { MagmaZombie = { [1] = 1 } },
                [9.5] = { MagmaZombie = { [1] = 1 } },
                [9.75] = { MagmaZombie = { [1] = 1 } },
            }
        },
    },

    PointsAllowance = {
        [0] = 700,
        [1] = 0,
        [2] = 200,
        [4] = 600,
        [6] = 0,
    },
    
    TicketRewards = {
        [2] = 1,
        [5] = 3,
        [7] = 5,
        [8] = 6,
        [9] = 8,
        [10] = 9,

        Completion = 10,
    },
    
    AttributeModifiers = {
        --[[
        [9] = {
            [GameEnum.UnitType.FieldUnit] = {
                SPD = {
                    Type = GameEnum.AttributeModifierType.Multiplicative,
                    
                    Modifier = function(spd)
                        return spd * 2
                    end,
                },
            }
        },

        [10] = {
            GhostlyZombie = {
                DEF = {
                    Type = GameEnum.AttributeModifierType.Multiplicative,
                    
                    Modifier = function(def)
                        return def * 4
                    end,
                },
            }
        }
        --]]
    },
    
    Abilities = {},
    StatusEffects = {},
}