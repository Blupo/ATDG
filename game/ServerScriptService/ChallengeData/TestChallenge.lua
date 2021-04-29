local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnums = require(SharedModules:FindFirstChild("GameEnums"))

---

return {
	Rounds = {
		[1] = {
			Length = 60,
			
			SpawnSequence = {
				[0] = {
					TestFieldUnit = {
						[1] = 1,
					}
				},
				
				[1] = {
					TestFieldUnit = {
						[1] = 1,
					}
				},
				
				[2] = {
					TestFieldUnit = {
						[1] = 1,
					}
				},
				
				[3] = {
					TestFieldUnit = {
						[1] = 1,
					}
				},
				
				[4] = {
					TestFieldUnit = {
						[1] = 1,
					}
				},
			}
		}
	},
	
	PointsAllowance = {
		-- Key = Round
		-- Value = Points to award
		[2] = 100,
		
		
		--[[
			If a round does not have an award specified,
			it will be the same as the last specified award
			
			(e.g., round 1 will give 0, and 2+ will give 100)
		]]
	},
	
	TicketRewards = {
		-- Key = Last round (or Completion for if they complete all rounds)
		-- Value = Tickets to award
		[2] = 1,
		[5] = 3,
		Completion = 5,
		
		--[[
			If a round does not have an award specified,
			it will be the same as the last specified award
			
			(e.g., rounds 2/3/4 will give 1 ticket, and 5+ will give 3)
		]]
	},
	
	Abilities = {
		[1] = {
			[GameEnums.UnitType.FieldUnit] = {
				TestAbility = true,
			}
		},
		
		[3] = {
			[GameEnums.UnitType.FieldUnit] = {
				TestAbility = false,
			}
		}
	},
	
	AttributeModifiers = {
		-- Key = Round number
		[1] = {
			-- Key = Unit name or a UnitType
			-- Value: dictionary
			[GameEnums.UnitType.FieldUnit] = {
				-- Key = Stat name
				-- Value: false = Remove modifier, dictionary = Add/change modifier, nil = Do nothing
				HP = {
					Type = GameEnums.AttributeModifierType.Multiplicative,
					
					Modifier = function(hp)
						return hp * 2
					end,
				},
				
				DEF = {
					Type = GameEnums.AttributeModifierType.Multiplicative,
					
					Modifiers = function(def)
						return def * 2
					end,
				}
			},
		}
	},
	
	StatusEffects = {
		-- Key = Round number
		[1] = {
			-- Key: Unit name or a UnitType
			-- Value: dictionary
			[GameEnums.UnitType.FieldUnit] = {
				-- Key = Effect name
				-- Value: number = Apply, false = Remove, nil = Do nothing
				Immune = 86400,
			}
		}
	},
}