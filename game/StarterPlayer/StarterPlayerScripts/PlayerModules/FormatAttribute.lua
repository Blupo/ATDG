local ReplicatedStorage = game:GetService("ReplicatedStorage")

---

local SharedModules = ReplicatedStorage:WaitForChild("Shared")
local GameEnum = require(SharedModules:WaitForChild("GameEnum"))

---

return function(attribute: string, value: any)
    if (tonumber(value) and (attribute ~= "MaxHP")) then
        if (value ~= math.huge) then
            return string.format("%0.2f", value)
        else
            return "∞"
        end
    elseif (attribute == "PathType") then
        if (value == GameEnum.PathType.Ground) then
            return "G"
        elseif (value == GameEnum.PathType.Air) then
            return "A"
        elseif (value == GameEnum.PathType.GroundAndAir) then
            return "GA"
        end
    else
        return value
    end
end