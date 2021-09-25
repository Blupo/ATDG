--[[
	Placement system code from EgoMoose's DevForum post:
	https://devforum.roblox.com/t/205509
	
	Rules:
		- Parts with Block Shape only
		- Placement areas consisting of multiple parts must be axis-aligned (rotated along the same axis)
		- Models should be rotated in 90 degree (pi/2 radian) increments for best results
		- Assumes that the PrimaryPart of Models is the bounding box of the model
		- Any individual placement area part must be large enough to accomodate a single Unit,
		  even if the entire surface cannot be used
		  - The current minimum area is 5x5 studs
]]

---

local ComplexPlacement = require(script:WaitForChild("ComplexPlacement"))
local SimplePlacement = require(script:WaitForChild("SimplePlacement"))

---

return {
	new = SimplePlacement.new,
	Merge = ComplexPlacement.new,
}