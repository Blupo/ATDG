local cs = game.CollectionService
local ps = game.PhysicsService

---

local UNIT_GROUP_ID = "Units"
local UNIT_TAG_ID = "Unit"

local onDescendantAdded = function(obj)
	if (obj:IsA("BasePart")) then
		ps:SetPartCollisionGroup(obj, UNIT_GROUP_ID)
	end
end

local onUnitAdded = function(unit)
	unit.DescendantAdded:Connect(onDescendantAdded)
	
	local objects = unit:GetDescendants()
	
	for i = 1, #objects do
		onDescendantAdded(objects[i])
	end
end

---

cs:GetInstanceAddedSignal(UNIT_TAG_ID):Connect(onUnitAdded)

do
	local units = cs:GetTagged(UNIT_TAG_ID)

	for i = 1, #units do
		onUnitAdded(units[i])
	end
end