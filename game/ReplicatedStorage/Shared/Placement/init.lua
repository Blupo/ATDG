--[[
	Placement system code from EgoMoose's DevForum post:
	https://devforum.roblox.com/t/205509
	
	Rules:
		- Parts with Block Shape only
		- Placement areas consisting of multiple parts must be axis-aligned (rotated along the same axis)
		- Models should be rotated in 90 degree (pi/2 radian) increments for best results
		- Assumes that the PrimaryPart of Models is the bounding box of the model 
]]

-- TODO: account for the surface size being smaller than the placement model bounding box size

---

local ComplexPlacement = require(script:WaitForChild("ComplexPlacement"))
local SimplePlacement = require(script:WaitForChild("SimplePlacement"))

---

return {
	new = SimplePlacement.new,
	Merge = ComplexPlacement.new,
}