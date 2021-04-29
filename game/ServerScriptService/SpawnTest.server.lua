local GameEnums = require(game.ReplicatedStorage.Shared.GameEnums)
local Path = require(script.Parent.GameModules.Path)
local StatusEffects = require(script.Parent.GameModules.StatusEffects)
local Unit = require(script.Parent.GameModules.Unit)

---

local RND_SE_CHANCE = 0.5

Path.PursuitEnded:Connect(function(unitId)
	Unit.fromId(unitId):Destroy()
end)

wait(2)
--[[
for i = 1, 2 do
	local newTowerUnit = Unit.new("TestTowerUnit")
	newTowerUnit.Model.Parent = workspace
	newTowerUnit.Model.PrimaryPart:SetNetworkOwner(nil)
end
]]

while true do
	local newUnit = Unit.new("TestFieldUnit")

	newUnit.Model.Parent = workspace
	newUnit.Model.PrimaryPart:SetNetworkOwner(nil)
	Path.PursuePath(newUnit, 1, GameEnums.PursuitDirection.Reverse)
	
	if (math.random() < RND_SE_CHANCE) then
		spawn(function()
			wait(math.random() * 3)
			StatusEffects.ApplyEffect(newUnit, "Frozen", math.random() * 5)
		end)
	end
	
	wait(0.5)
end

--[[
do
	local newUnit = Unit.new(GameEnums.UnitType.FieldUnit, "TestFieldUnit")

	newUnit.Model.Parent = workspace
	newUnit.Model.HumanoidRootPart:SetNetworkOwner(nil)
	
	wait(5)
	StatusEffects.ApplyEffect(newUnit, "Frozen", math.random() * 5)
	wait(2)
	StatusEffects.ApplyEffect(newUnit, "Burning", math.random() * 5)
end
--]]