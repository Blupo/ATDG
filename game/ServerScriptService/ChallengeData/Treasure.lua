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
				[0] = { Zombie = { [1] = 1, } },
				[1] = { Zombie = { [1] = 1, } },
				[2] = { Zombie = { [1] = 1, } },
				[3] = { Zombie = { [1] = 1, } },
			}
		},

		[2] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Zombie = { [1] = 1, } },
				[1] = { Zombie = { [1] = 1, } },
				[2] = { Zombie = { [1] = 1, } },
				[3] = { Zombie = { [1] = 1, } },
				[3.5] = { Theif = { [1] = 1, } },
			}
		},

		[3] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Thief = { [1] = 1, } },
				[1] = { Zombie = { [1] = 1, } },
				[2] = { Thief = { [1] = 1, } },
				[3] = { Zombie = { [1] = 1, } },
				[4] = { Theif = { [1] = 1, } },
				[5] = { Zombie = { [1] = 1, } },
			}
		},

		[4] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Thief = { [1] = 1, } },
				[1] = { Zombie = { [1] = 1, } },
				[2] = { Thief = { [1] = 1, } },
				[3] = { Zombie = { [1] = 1, } },
				[4] = { Theif = { [1] = 1, } },
				[5] = { Zombie = { [1] = 1, } },

				[15] = { Zombie = { [1] = 1, } },
				[15.2] = { Zombie = { [1] = 1, } },
				[15.4] = { Zombie = { [1] = 1, } },
				[15.6] = { Zombie = { [1] = 1, } },
				[15.8] = { Zombie = { [1] = 1, } },
				[16] = { Zombie = { [1] = 1, } },
			}
		},

		[5] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Thief = { [1] = 1, } },
				[1] = { Thief = { [1] = 1, } },
				[2] = { Thief = { [1] = 1, } },
				[3] = { Thief = { [1] = 1, } },
				[4] = { Theif = { [1] = 1, } },
				[5] = { Thief = { [1] = 1, } },

				[15] = { Zombie = { [1] = 1, } },
				[15.2] = { Zombie = { [1] = 1, } },
				[15.4] = { Zombie = { [1] = 1, } },
				[15.6] = { Zombie = { [1] = 1, } },
				[15.8] = { Zombie = { [1] = 1, } },
				[16] = { Zombie = { [1] = 1, } },

				[20] = { ["Elite Thief"] = { [1] = 1, } },
			}
		},

		[6] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Zombie = { [1] = 1, } },
				[1] = { Zombie = { [1] = 1, } },
				[2] = { Thief = { [1] = 1, } },
				[3] = { Thief = { [1] = 1, } },
				[4] = { Theif = { [1] = 1, } },
				[5] = { Thief = { [1] = 1, } },

				[10] = { ["Elite Thief"] = { [1] = 1, } },
				[11] = { ["Elite Thief"] = { [1] = 1, } },
			}
		},

		[7] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Thief = { [1] = 1, } },
				[1] = { Thief = { [1] = 1, } },
				[2] = { Thief = { [1] = 1, } },
				[3] = { Thief = { [1] = 1, } },
				[4] = { Theif = { [1] = 1, } },
				[5] = { Thief = { [1] = 1, } },
				[6] = { ["Elite Thief"] = { [1] = 1, } },
				[7] = { ["Elite Thief"] = { [1] = 1, } },

				[20] = { Zombie = { [1] = 1, } },
				[21] = { Zombie = { [1] = 1, } },
				[22] = { Zombie = { [1] = 1, } },
				[23] = { Zombie = { [1] = 1, } },
				[24] = { Zombie = { [1] = 1, } },
				[25] = { Zombie = { [1] = 1, } },
				[26] = { Zombie = { [1] = 1, } },
				[27] = { Zombie = { [1] = 1, } },
				[28] = { Zombie = { [1] = 1, } },
				[29] = { Zombie = { [1] = 1, } },
				[30] = { Zombie = { [1] = 1, } },
			}
		},

		[8] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Thief = { [1] = 1, } },
				[0.5] = { ["Elite Thief"] = { [1] = 1, } },
				[1] = { Thief = { [1] = 1, } },
				[1.5] = { ["Elite Thief"] = { [1] = 1, } },
				[2] = { Theif = { [1] = 1, } },
				[2.5] = { ["Elite Thief"] = { [1] = 1, } },
				[3] = { Thief = { [1] = 1, } },
				[3.5] = { ["Elite Thief"] = { [1] = 1, } },
				[4] = { Thief = { [1] = 1, } },
				[4.5] = { ["Elite Thief"] = { [1] = 1, } },
				[5] = { Thief = { [1] = 1, } },
				[5.5] = { ["Elite Thief"] = { [1] = 1, } },
				[6] = { Theif = { [1] = 1, } },
				[6.5] = { ["Elite Thief"] = { [1] = 1, } },
				[7] = { Thief = { [1] = 1, } },
				[7.5] = { ["Elite Thief"] = { [1] = 1, } },
				[8] = { Thief = { [1] = 1, } },
				[8.5] = { ["Elite Thief"] = { [1] = 1, } },
				[9] = { Thief = { [1] = 1, } },
				[9.5] = { ["Elite Thief"] = { [1] = 1, } },
				[10] = { Theif = { [1] = 1, } },
				[10.5] = { ["Elite Thief"] = { [1] = 1, } },
				[11] = { Thief = { [1] = 1, } },
				[11.5] = { ["Elite Thief"] = { [1] = 1, } },
				[12] = { Thief = { [1] = 1, } },
				[12.5] = { ["Elite Thief"] = { [1] = 1, } },
				[13] = { Thief = { [1] = 1, } },
				[13.5] = { ["Elite Thief"] = { [1] = 1, } },
				[14] = { Theif = { [1] = 1, } },
				[14.5] = { ["Elite Thief"] = { [1] = 1, } },
				[15] = { Thief = { [1] = 1, } },
				[15.5] = { ["Elite Thief"] = { [1] = 1, } },
			}
		},

		[9] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Zombie = { [1] = 10 } },
				[5] = { ["Elite Thief"] = { [1] = 1 } },
				[6] = { ["Elite Thief"] = { [1] = 1 } },
				[7] = { ["Elite Thief"] = { [1] = 1 } },

				[10] = { Zombie = { [1] = 10 } },
				[15] = { ["Elite Thief"] = { [1] = 1 } },
				[16] = { ["Elite Thief"] = { [1] = 1 } },
				[17] = { ["Elite Thief"] = { [1] = 1 } },

				[20] = { ["Elite Thief"] = { [1] = 1 } },
				[21] = { ["Elite Thief"] = { [1] = 1 } },
				[22] = { ["Elite Thief"] = { [1] = 1 } },
				[23] = { ["Elite Thief"] = { [1] = 1 } },
				[24] = { ["Elite Thief"] = { [1] = 1 } },
				[25] = { ["Elite Thief"] = { [1] = 1 } },
				[26] = { ["Elite Thief"] = { [1] = 1 } },
				[27] = { ["Elite Thief"] = { [1] = 1 } },
				[28] = { ["Elite Thief"] = { [1] = 1 } },
				[29] = { ["Elite Thief"] = { [1] = 1 } },
				[30] = { ["Elite Thief"] = { [1] = 1 } },
			}
		},

		[10] = {
			Length = 120,

			SpawnSequence = {
				[0] = { Zombie = { [1] = 10 } },
				[3] = { Zombie = { [1] = 10 } },
				[5] = { Zombie = { [1] = 10 } },
				[7] = { Zombie = { [1] = 10 } },

				[20] = { Zombie = { [1] = 10 } },
				[23] = { Zombie = { [1] = 10 } },
				[25] = { Zombie = { [1] = 10 } },
				[27] = { Zombie = { [1] = 10 } },
				
				[30] = { ["Elite Thief"] = { [1] = 1 } },
			}
		},
	},
	
	PointsAllowance = {
		[0] = 600,
		[2] = 100,
		[3] = 200,
		[5] = 300,
		[7] = 600,
		[10] = 800,
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