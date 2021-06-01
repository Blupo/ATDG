local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local StatusEffectsCommunicators = ReplicatedStorage:WaitForChild("Communicators"):WaitForChild("StatusEffects")

local Util = script.Parent.Parent:WaitForChild("Util")
local RemoteFunctionWrapper = require(Util:WaitForChild("RemoteFunctionWrapper"))

local UnitHasEffect = StatusEffectsCommunicators:WaitForChild("UnitHasEffect")
local GetUnitEffects = StatusEffectsCommunicators:WaitForChild("GetUnitEffects")
local EffectApplied = StatusEffectsCommunicators:WaitForChild("EffectApplied")
local EffectRemoved = StatusEffectsCommunicators:WaitForChild("EffectRemoved")

---

-- temp: prevent invocation queue errors
EffectApplied.OnClientEvent:Connect(function() end)
EffectRemoved.OnClientEvent:Connect(function() end)
--

return {
	UnitHasEffect = RemoteFunctionWrapper(UnitHasEffect),
	GetUnitEffects = RemoteFunctionWrapper(GetUnitEffects),
	
	EffectAppliedEvent = EffectApplied.OnClientEvent,
	EffectRemovedEvent = EffectRemoved.OnClientEvent
}
