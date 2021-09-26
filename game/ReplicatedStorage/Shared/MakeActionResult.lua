local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:FindFirstChild("Shared")
local GameEnum = require(SharedModules:FindFirstChild("GameEnum"))

return function(failureReason: string?)
    return {
        Success = (not failureReason) and true or false,
        FailureReason = failureReason or GameEnum.GenericActionResult.None,
    }
end