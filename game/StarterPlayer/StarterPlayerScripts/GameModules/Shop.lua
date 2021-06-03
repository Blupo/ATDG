local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local PlayerScripts = script.Parent.Parent
local Util = PlayerScripts:WaitForChild("Util")
local RemoteFunctionWrapper = require(Util:WaitForChild("RemoteFunctionWrapper"))

local Communicators = ReplicatedStorage:WaitForChild("Communicators"):WaitForChild("Shop")
local PurchaseObjectPlacement = Communicators:WaitForChild("PurchaseObjectPlacement")

---

local Shop = {
    PurchaseObjectPlacement = RemoteFunctionWrapper(PurchaseObjectPlacement)
}

---

return Shop