local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

return {
	Rounds = {
		[1] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { PaperPlane = { [1] = 1 } },
				[1] = { PaperPlane = { [1] = 1 } },
				[2] = { PaperPlane = { [1] = 1 } },
				[3] = { PaperPlane = { [1] = 1 } },
				[4] = { PaperPlane = { [1] = 1 } },
				[5] = { PaperPlane = { [1] = 1 } },
				[6] = { PaperPlane = { [1] = 1 } },
				[7] = { PaperPlane = { [1] = 1 } },
			}
		},

		[2] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { PaperPlane = { [1] = 1 } },
				[1] = { PaperPlane = { [1] = 1 } },
				[2] = { PaperPlane = { [1] = 1 } },
				[3] = { PaperPlane = { [1] = 1 } },
				[4] = { PaperPlane = { [1] = 1 } },
				[5] = { PaperPlane = { [1] = 1 } },
				[6] = { PaperPlane = { [1] = 1 } },
				[7] = { PaperPlane = { [1] = 1 } },

				[10] = { PaperPlane = { [1] = 1 } },
				[11] = { PaperPlane = { [1] = 1 } },
				[12] = { PaperPlane = { [1] = 1 } },
				[13] = { PaperPlane = { [1] = 1 } },
				[14] = { PaperPlane = { [1] = 1 } },
				[15] = { PaperPlane = { [1] = 1 } },
				[16] = { PaperPlane = { [1] = 1 } },
				[17] = { PaperPlane = { [1] = 1 } },

				[20] = { PaperPlane = { [1] = 1 } },
				[21] = { PaperPlane = { [1] = 1 } },
				[22] = { PaperPlane = { [1] = 1 } },
				[23] = { PaperPlane = { [1] = 1 } },
				[24] = { PaperPlane = { [1] = 1 } },
				[25] = { PaperPlane = { [1] = 1 } },
				[26] = { PaperPlane = { [1] = 1 } },
				[27] = { PaperPlane = { [1] = 1 } },
			}
		},

		[3] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { PaperPlane = { [1] = 1 } },
				[1] = { PaperPlane = { [1] = 1 } },
				[2] = { PaperPlane = { [1] = 1 } },
				[3] = { PaperPlane = { [1] = 1 } },
				[4] = { PaperPlane = { [1] = 1 } },
				[5] = { PaperPlane = { [1] = 1 } },
				[6] = { PaperPlane = { [1] = 1 } },
				[7] = { PaperPlane = { [1] = 1 } },

				[8] = { Plane = { [1] = 1 } },
				[9] = { Plane = { [1] = 1 } },
				[10] = { Plane = { [1] = 1 } },
				[11] = { Plane = { [1] = 1 } },
				[12] = { Plane = { [1] = 1 } },
				[13] = { Plane = { [1] = 1 } },
				[14] = { Plane = { [1] = 1 } },
				[15] = { Plane = { [1] = 1 } },

				[20] = { PaperPlane = { [1] = 1 } },
				[21] = { Plane = { [1] = 1 } },
				[22] = { PaperPlane = { [1] = 1 } },
				[23] = { Plane = { [1] = 1 } },
				[24] = { PaperPlane = { [1] = 1 } },
				[25] = { Plane = { [1] = 1 } },
				[26] = { PaperPlane = { [1] = 1 } },
				[27] = { Plane = { [1] = 1 } },
				[28] = { PaperPlane = { [1] = 1 } },
				[29] = { Plane = { [1] = 1 } },
				[30] = { PaperPlane = { [1] = 1 } },
				[31] = { Plane = { [1] = 1 } },
				[32] = { PaperPlane = { [1] = 1 } },
				[33] = { Plane = { [1] = 1 } },
				[34] = { PaperPlane = { [1] = 1 } },
				[35] = { Plane = { [1] = 1 } },
			}
		},

		[4] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { PaperPlane = { [1] = 1 } },
				[1] = { Plane = { [1] = 1 } },
				[2] = { PaperPlane = { [1] = 1 } },
				[3] = { Plane = { [1] = 1 } },
				[4] = { PaperPlane = { [1] = 1 } },
				[5] = { Plane = { [1] = 1 } },
				[6] = { PaperPlane = { [1] = 1 } },
				[7] = { Plane = { [1] = 1 } },

				[8] = { Plane = { [1] = 1 } },
				[9] = { Plane = { [1] = 1 } },
				[10] = { Plane = { [1] = 1 } },
				[11] = { Plane = { [1] = 1 } },
				[12] = { Plane = { [1] = 1 } },
				[13] = { Plane = { [1] = 1 } },
				[14] = { Plane = { [1] = 1 } },
				[15] = { Plane = { [1] = 1 } },

				[20] = { PaperPlane = { [1] = 1 } },
				[21] = { Plane = { [1] = 1 } },
				[22] = { PaperPlane = { [1] = 1 } },
				[23] = { Plane = { [1] = 1 } },
				[24] = { PaperPlane = { [1] = 1 } },
				[25] = { Plane = { [1] = 1 } },
				[26] = { PaperPlane = { [1] = 1 } },
				[27] = { Plane = { [1] = 1 } },
				[28] = { PaperPlane = { [1] = 1 } },
				[29] = { Plane = { [1] = 1 } },
				[30] = { PaperPlane = { [1] = 1 } },
				[31] = { Plane = { [1] = 1 } },
				[32] = { PaperPlane = { [1] = 1 } },
				[33] = { Plane = { [1] = 1 } },
				[34] = { PaperPlane = { [1] = 1 } },
				[35] = { Plane = { [1] = 1 } },
			}
		},

		[5] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { Plane = { [1] = 1 } },
				[0.5] = { Plane = { [1] = 1 } },
				[1] = { Plane = { [1] = 1 } },
				[1.5] = { Plane = { [1] = 1 } },
				[2] = { Plane = { [1] = 1 } },
				[2.5] = { Plane = { [1] = 1 } },
				[3] = { Plane = { [1] = 1 } },
				[3.5] = { Plane = { [1] = 1 } },
				[4] = { Plane = { [1] = 1 } },
				[4.5] = { Plane = { [1] = 1 } },
				[5] = { Plane = { [1] = 1 } },
				[5.5] = { Plane = { [1] = 1 } },
				[6] = { Plane = { [1] = 1 } },
				[6.5] = { Plane = { [1] = 1 } },
				[7] = { Plane = { [1] = 1 } },
				[7.5] = { Plane = { [1] = 1 } },
				[8] = { Plane = { [1] = 1 } },
				[8.5] = { Plane = { [1] = 1 } },
				[9] = { Plane = { [1] = 1 } },
				[9.5] = { Plane = { [1] = 1 } },
				[10] = { Plane = { [1] = 1 } },
				[10.5] = { Plane = { [1] = 1 } },
				[11] = { Plane = { [1] = 1 } },
				[11.5] = { Plane = { [1] = 1 } },
				[12] = { Plane = { [1] = 1 } },
				[12.5] = { Plane = { [1] = 1 } },
				[13] = { Plane = { [1] = 1 } },
				[13.5] = { Plane = { [1] = 1 } },
				[14] = { Plane = { [1] = 1 } },
				[14.5] = { Plane = { [1] = 1 } },
				[15] = { Plane = { [1] = 1 } },
				[15.5] = { Plane = { [1] = 1 } },
				[16] = { MilitaryPlane = { [1] = 1 } },
				[17] = { MilitaryPlane = { [1] = 1 } },
			}
		},

		[6] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { MilitaryPlane = { [1] = 1 } },
				[0.25] = { Plane = { [1] = 1 } },
				[0.5] = { MilitaryPlane = { [1] = 1 } },
				[1] = { MilitaryPlane = { [1] = 1 } },
				[1.5] = { MilitaryPlane = { [1] = 1 } },
				[2] = { MilitaryPlane = { [1] = 1 } },
				[2.5] = { MilitaryPlane = { [1] = 1 } },
				[3] = { MilitaryPlane = { [1] = 1 } },
				[3.5] = { MilitaryPlane = { [1] = 1 } },
				[4] = { MilitaryPlane = { [1] = 1 } },
				[4.5] = { MilitaryPlane = { [1] = 1 } },
				[5] = { MilitaryPlane = { [1] = 1 } },
				[5.5] = { MilitaryPlane = { [1] = 1 } },
				[6] = { MilitaryPlane = { [1] = 1 } },
				[6.25] = { Plane = { [1] = 1 } },
				[6.5] = { MilitaryPlane = { [1] = 1 } },
				[6.75] = { Plane = { [1] = 1 } },
				[7] = { MilitaryPlane = { [1] = 1 } },
				[7.5] = { MilitaryPlane = { [1] = 1 } },
				[8] = { MilitaryPlane = { [1] = 1 } },
				[8.5] = { MilitaryPlane = { [1] = 1 } },
				[9] = { MilitaryPlane = { [1] = 1 } },
				[9.5] = { MilitaryPlane = { [1] = 1 } },
				[10] = { MilitaryPlane = { [1] = 1 } },
				[10.5] = { MilitaryPlane = { [1] = 1 } },
				[11] = { MilitaryPlane = { [1] = 1 } },
				[11.5] = { MilitaryPlane = { [1] = 1 } },
				[12] = { MilitaryPlane = { [1] = 1 } },
				[12.25] = { Plane = { [1] = 1 } },
				[12.5] = { MilitaryPlane = { [1] = 1 } },
				[12.75] = { Plane = { [1] = 1 } },
				[13] = { MilitaryPlane = { [1] = 1 } },
				[13.5] = { MilitaryPlane = { [1] = 1 } },
				[14] = { MilitaryPlane = { [1] = 1 } },
				[14.5] = { MilitaryPlane = { [1] = 1 } },
				[15] = { MilitaryPlane = { [1] = 1 } },
				[15.5] = { MilitaryPlane = { [1] = 1 } },
				[16] = { MilitaryPlane = { [1] = 1 } },
				[16.5] = { MilitaryPlane = { [1] = 1 } },

				[20] = { UFO = { [1] = 1 } },
				[21] = { UFO = { [1] = 1 } },
				[22] = { UFO = { [1] = 1 } },
			}
		},

		[7] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { UFO = { [1] = 1 } },
				[0.5] = { MilitaryPlane = { [1] = 1 } },
				[1] = { MilitaryPlane = { [1] = 1 } },
				[1.5] = { MilitaryPlane = { [1] = 1 } },

				[4] = { UFO = { [1] = 1 } },
				[4.5] = { MilitaryPlane = { [1] = 1 } },
				[5] = { MilitaryPlane = { [1] = 1 } },
				[5.5] = { MilitaryPlane = { [1] = 1 } },

				[8] = { UFO = { [1] = 1 } },
				[8.5] = { MilitaryPlane = { [1] = 1 } },
				[9] = { MilitaryPlane = { [1] = 1 } },
				[9.5] = { MilitaryPlane = { [1] = 1 } },

				[12] = { UFO = { [1] = 1 } },
				[12.5] = { MilitaryPlane = { [1] = 1 } },
				[13] = { MilitaryPlane = { [1] = 1 } },
				[13.5] = { MilitaryPlane = { [1] = 1 } },

				[16] = { UFO = { [1] = 1 } },
				[16.5] = { MilitaryPlane = { [1] = 1 } },
				[17] = { MilitaryPlane = { [1] = 1 } },
				[17.5] = { MilitaryPlane = { [1] = 1 } },

				[20] = { UFO = { [1] = 1 } },
				[20.5] = { MilitaryPlane = { [1] = 1 } },
				[21] = { MilitaryPlane = { [1] = 1 } },
				[21.5] = { MilitaryPlane = { [1] = 1 } },

				[24] = { UFO = { [1] = 1 } },
				[24.5] = { MilitaryPlane = { [1] = 1 } },
				[25] = { MilitaryPlane = { [1] = 1 } },
				[25.5] = { MilitaryPlane = { [1] = 1 } },
			}
		},

		[8] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = { UFO = { [1] = 1 } },
				[1] = { MilitaryPlane = { [1] = 1 } },

				[3] = { UFO = { [1] = 1 } },
				[4] = { MilitaryPlane = { [1] = 1 } },

				[6] = { UFO = { [1] = 1 } },
				[7] = { MilitaryPlane = { [1] = 1 } },

				[9] = { UFO = { [1] = 1 } },
				[10] = { MilitaryPlane = { [1] = 1 } },

				[12] = { UFO = { [1] = 1 } },
				[13] = { MilitaryPlane = { [1] = 1 } },

				[15] = { UFO = { [1] = 1 } },
				[16] = { MilitaryPlane = { [1] = 1 } },

				[18] = { UFO = { [1] = 1 } },
				[19] = { MilitaryPlane = { [1] = 1 } },

				[21] = { UFO = { [1] = 1 } },
				[22] = { MilitaryPlane = { [1] = 1 } },

				[24] = { UFO = { [1] = 1 } },
				[25] = { MilitaryPlane = { [1] = 1 } },

				[27] = { UFO = { [1] = 1 } },
				[28] = { MilitaryPlane = { [1] = 1 } },

				[30] = { UFO = { [1] = 1 } },
				[31] = { MilitaryPlane = { [1] = 1 } },

				[33] = { UFO = { [1] = 1 } },
				[34] = { MilitaryPlane = { [1] = 1 } },

				[36] = { UFO = { [1] = 1 } },
				[37] = { MilitaryPlane = { [1] = 1 } },

				[39] = { UFO = { [1] = 1 } },
				[40] = { MilitaryPlane = { [1] = 1 } },
			}
		},

		[9] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[0.5] = {
					MilitaryPlane = { [1] = 1 },
					Plane = { [2] = 1 }
				},

				[1] = {
					MilitaryPlane = { [1] = 1 },
					Plane = { [2] = 1 }
				},

				[1.5] = {
					MilitaryPlane = { [1] = 1 },
					Plane = { [2] = 1 }
				},

				[2] = {
					MilitaryPlane = { [1] = 1 },
					Plane = { [2] = 1 }
				},

				[2.5] = {
					MilitaryPlane = { [1] = 1 },
					Plane = { [2] = 1 }
				},

				[3] = {
					MilitaryPlane = { [1] = 1 },
					Plane = { [2] = 1 }
				},

				[3.5] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[4] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[4.5] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[5] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[5.5]= {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[6] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[6.5] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[7] = {
					MilitaryPlane = { [1] = 1 },
					PaperPlane = { [2] = 1 }
				},

				[7.5] = {
					UFO = {
						[1] = 1,
						[2] = 1,
					},
				},
			}
		},
		
		[10] = {
			Length = 180,
			
			SpawnSequence = {
				[0] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[0.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[0.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[0.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[1] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[1.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[1.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[1.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[2] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[2.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[2.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[2.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[3] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[3.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[3.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[3.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[4] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[4.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[4.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[4.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[5.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[5.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[5.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[6] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[6.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[6.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[6.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[7] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[7.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[7.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[7.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[8] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[8.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[8.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[8.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[9] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[9.25] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[9.5] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[9.75] = {
					PaperPlane = {
						[1] = 1,
						[2] = 1,
					}
				},

				[10] = { MilitaryPlane = { [1] = 1 } },
				[10.25] = { UFO = { [1] = 1 } },
				[10.5] = { MilitaryPlane = { [1] = 1 } },
				[10.75] = { UFO = { [1] = 1 } },
				[11] = { MilitaryPlane = { [1] = 1 } },
				[11.25] = { UFO = { [1] = 1 } },
				[11.5] = { MilitaryPlane = { [1] = 1 } },
				[11.75] = { UFO = { [1] = 1 } },
				[12] = { MilitaryPlane = { [1] = 1 } },
				[12.25] = { UFO = { [1] = 1 } },
				[12.5] = { MilitaryPlane = { [1] = 1 } },
				[12.75] = { UFO = { [1] = 1 } },
				[13] = { MilitaryPlane = { [1] = 1 } },
				[13.25] = { UFO = { [1] = 1 } },
				[13.5] = { MilitaryPlane = { [1] = 1 } },
				[13.75] = { UFO = { [1] = 1 } },
				[14] = { MilitaryPlane = { [1] = 1 } },
				[14.25] = { UFO = { [1] = 1 } },
				[14.5] = { MilitaryPlane = { [1] = 1 } },
				[14.75] = { UFO = { [1] = 1 } },
				[15] = { MilitaryPlane = { [1] = 1 } },
				[15.25] = { UFO = { [1] = 1 } },
				[15.5] = { MilitaryPlane = { [1] = 1 } },
				[15.75] = { UFO = { [1] = 1 } },
				[16] = { MilitaryPlane = { [1] = 1 } },
				[16.25] = { UFO = { [1] = 1 } },
				[16.5] = { MilitaryPlane = { [1] = 1 } },
				[16.75] = { UFO = { [1] = 1 } },
				[17] = { MilitaryPlane = { [1] = 1 } },
				[17.25] = { UFO = { [1] = 1 } },
				[17.5] = { MilitaryPlane = { [1] = 1 } },
				[17.75] = { UFO = { [1] = 1 } },
				[18] = { MilitaryPlane = { [1] = 1 } },
				[18.25] = { UFO = { [1] = 1 } },
				[18.5] = { MilitaryPlane = { [1] = 1 } },
				[18.75] = { UFO = { [1] = 1 } },
				[19] = { MilitaryPlane = { [1] = 1 } },
				[19.25] = { UFO = { [1] = 1 } },
				[19.5] = { MilitaryPlane = { [1] = 1 } },
				[19.75] = { UFO = { [1] = 1 } },
				[20] = { MilitaryPlane = { [1] = 1 } },
			}
		},
	},
	
	PointsAllowance = {
		[0] = 700,
		[1] = 0,
		[2] = 300,
		[3] = 400,
		[4] = 500,
		[5] = 800,
		[6] = 1000,
		[8] = 2000,
		[9] = 3000,
	},
	
	TicketRewards = {
		[2] = 1,
		[4] = 2,
		[5] = 4,
		[6] = 6,
		[8] = 8,
		[10] = 9,
		
		Completion = 10,
	},
	
	Abilities = {},
	AttributeModifiers = {},
	StatusEffects = {},
}