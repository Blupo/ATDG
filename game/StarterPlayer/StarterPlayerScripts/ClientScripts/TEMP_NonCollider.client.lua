-- TODO: Finalise Unit replication details

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

---

local onDescendantAdded = function(obj)
    if (obj:IsA("BasePart")) then
        PhysicsService:SetPartCollisionGroup(obj, GameEnum.CollisionGroup.Units)
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

CollectionService:GetInstanceAddedSignal(GameEnum.ObjectType.Unit):Connect(onUnitAdded)

do
    local units = CollectionService:GetTagged(GameEnum.ObjectType.Unit)

    for i = 1, #units do
        onUnitAdded(units[i])
    end
end