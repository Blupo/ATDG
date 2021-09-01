-- TODO: Finalise Unit replication details

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

local onUnitAdded = function(unit)
	local objects = unit:GetDescendants()
	
	for i = 1, #objects do
		local obj = objects[i]
		
		if (obj:IsA("BasePart")) then
			PhysicsService:SetPartCollisionGroup(obj, GameEnum.CollisionGroup.Units)
		end
	end
end

local onCharacterDescendantAdded = function(obj)
	if (obj:IsA("BasePart")) then
		PhysicsService:SetPartCollisionGroup(obj, GameEnum.CollisionGroup.Players)
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

PhysicsService:CreateCollisionGroup(GameEnum.CollisionGroup.Units)
PhysicsService:CreateCollisionGroup(GameEnum.CollisionGroup.Players)

PhysicsService:CollisionGroupSetCollidable(GameEnum.CollisionGroup.Units, GameEnum.CollisionGroup.Units, false)
PhysicsService:CollisionGroupSetCollidable(GameEnum.CollisionGroup.Players, GameEnum.CollisionGroup.Players, false)
PhysicsService:CollisionGroupSetCollidable(GameEnum.CollisionGroup.Units, GameEnum.CollisionGroup.Players, false)

Players.PlayerAdded:Connect(onPlayerAdded)
CollectionService:GetInstanceAddedSignal(GameEnum.ObjectType.Unit):Connect(onUnitAdded)

do
	local players = Players:GetPlayers()
	local units = CollectionService:GetTagged(GameEnum.ObjectType.Unit)
	
	for i = 1, #players do
		onPlayerAdded(players[i])
	end
	
	for i = 1, #units do
		onUnitAdded(units[i])
	end
end