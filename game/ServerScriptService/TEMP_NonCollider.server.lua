local cs = game.CollectionService
local pl = game.Players
local ps = game.PhysicsService

---

local UNIT_GROUP_ID = "Units"
local PLAYER_GROUP_ID = "Players"
local UNIT_TAG_ID = "Unit"

local onUnitAdded = function(unit)
	local objects = unit:GetDescendants()
	
	for i = 1, #objects do
		local obj = objects[i]
		
		if (obj:IsA("BasePart")) then
			ps:SetPartCollisionGroup(obj, UNIT_GROUP_ID)
		end
	end
end

local onCharacterDescendantAdded = function(obj)
	if (obj:IsA("BasePart")) then
		ps:SetPartCollisionGroup(obj, PLAYER_GROUP_ID)
	end
end

local onPlayerCharacterAdded = function(character)
	character.DescendantAdded:Connect(onCharacterDescendantAdded)
	
	local objects = character:GetDescendants()
	
	for i = 1, #objects do
		onCharacterDescendantAdded(objects[i])
	end
end

local onPlayerAdded = function(player)
	player.CharacterAdded:Connect(onPlayerCharacterAdded)
	
	if (player.Character) then
		onPlayerCharacterAdded(player.Character)
	end
end

---

ps:CreateCollisionGroup(UNIT_GROUP_ID)
ps:CreateCollisionGroup(PLAYER_GROUP_ID)

ps:CollisionGroupSetCollidable(UNIT_GROUP_ID, UNIT_GROUP_ID, false)
ps:CollisionGroupSetCollidable(PLAYER_GROUP_ID, PLAYER_GROUP_ID, false)
ps:CollisionGroupSetCollidable(UNIT_GROUP_ID, PLAYER_GROUP_ID, false)

pl.PlayerAdded:Connect(onPlayerAdded)
cs:GetInstanceAddedSignal(UNIT_TAG_ID):Connect(onUnitAdded)

do
	local players = pl:GetPlayers()
	local units = cs:GetTagged(UNIT_TAG_ID)
	
	for i = 1, #players do
		onPlayerAdded(players[i])
	end
	
	for i = 1, #units do
		onUnitAdded(units[i])
	end
end