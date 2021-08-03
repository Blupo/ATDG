local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	StatusEffects = {},
	Abilities = {},
	
	PointsAllowance = {
		[0] = 1000,
		[1] = 120,
		[4] = 300,
		[10] = 750,
		[20] = 900,
	},

	TicketRewards = {
		Completion = 5,
		
		[1] = 0,
		[5] = 1,
		[10] = 2,
		[20] = 3,
	},

	Rounds = {
		[1] = {
			Length = 60,

			SpawnSequence = {
				[0] = {
					TestFieldUnit = { [1] = 1, }
				},

				[1] = {
					TestFieldUnit = { [1] = 1, }
				},

				[2] = {
					TestFieldUnit = { [1] = 1, }
				},

				[3] = {
					TestFieldUnit = { [1] = 1, }
				},

				[4] = {
					TestFieldUnit = { [1] = 1, },
					TestAirFieldUnit = { [1] = 1, }
				},
				
				[5] = {
					TestBiggerFieldUnit = { [2] = 1, }
				},
			}
		},
		
		[2] = {
			Length = 60,

			SpawnSequence = {
				[0] = {
					TestFieldUnit = { [1] = 1, }
				},

				[1] = {
					TestFieldUnit = { [1] = 1, }
				},

				[2] = {
					TestFieldUnit = { [1] = 1, }
				},

				[3] = {
					TestFieldUnit = { [1] = 1, }
				},

				[4] = {
					TestFieldUnit = { [1] = 1, },
					TestAirFieldUnit = { [1] = 1, }
				},

				[5] = {
					TestBiggerFieldUnit = { [2] = 1, }
				},
			}
		},

		[3] = {
			Length = 60,

			SpawnSequence = {
				[0] = {
					TestFieldUnit = { [1] = 1, }
				},

				[1] = {
					TestFieldUnit = { [1] = 1, }
				},

				[2] = {
					TestFieldUnit = { [1] = 1, }
				},

				[3] = {
					TestFieldUnit = { [1] = 1, }
				},

				[4] = {
					TestFieldUnit = { [1] = 1, },
					TestAirFieldUnit = { [1] = 1, }
				},

				[5] = {
					TestBiggerFieldUnit = { [2] = 1, }
				},
			}
		}
	},
	
	AttributeModifiers = {
		--[[
		[1] = {
			[GameEnum.UnitType.FieldUnit] = {
				DEF = {
					Type = GameEnum.AttributeModifierType.Additive,
					
					Modifier = function()
						return 5
					end,
				}
			}
		},
		
		[2] = {
			[GameEnum.UnitType.FieldUnit] = {
				DEF = false,
			}
		}
		--]]
	},
}